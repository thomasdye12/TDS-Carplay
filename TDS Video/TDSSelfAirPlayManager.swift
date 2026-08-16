import Foundation
import NetworkExtension
import os
import UIKit

private let selfAirPlayLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "net.thomasdye.TDS-Video2",
    category: "SelfAirPlay"
)

private func selfAirPlayLog(_ message: String) {
    selfAirPlayLogger.notice("\(message, privacy: .public)")
    print("[SelfAirPlay] \(message)")
}

@MainActor
final class TDSSelfAirPlayManager: ObservableObject {
    static let shared = TDSSelfAirPlayManager()

    enum State: Equatable {
        case off
        case preparing
        case connected
        case error(String)

        var isEnabled: Bool {
            if case .connected = self { return true }
            if case .preparing = self { return true }
            return false
        }

        var description: String {
            switch self {
            case .off:
                return "Off"
            case .preparing:
                return "Finding the local receiver and preparing its virtual network device…"
            case .connected:
                return "Ready. Open Control Centre, tap Screen Mirroring, and choose TDS Carplay (This iPhone)."
            case .error(let message):
                return message
            }
        }
    }

    @Published private(set) var state: State = .off

    private var manager: NETunnelProviderManager?
    private var operation: Task<Void, Never>?
    private var statusObserver: NSObjectProtocol?
    private var syntheticPublisher: TDSSelfAirPlayPublisher?

    private struct VirtualIdentity {
        let deviceID: String
        let compactDeviceID: String
        let persistentID: String
    }

    private init() {
        selfAirPlayLog("Manager initialized; loading saved tunnel configuration")
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let connection = notification.object as? NEVPNConnection else { return }
            Task { @MainActor in self?.apply(connection.status) }
        }

        Task { await refreshStatus() }
    }

    func setEnabled(_ enabled: Bool) {
        selfAirPlayLog("User requested Self AirPlay \(enabled ? "ON" : "OFF")")
        operation?.cancel()
        if enabled {
            operation = Task { await enable() }
        } else {
            selfAirPlayLog("Stopping packet tunnel")
            syntheticPublisher?.stop()
            syntheticPublisher = nil
            manager?.connection.stopVPNTunnel()
            state = .off
        }
    }

    private func enable() async {
        state = .preparing
        selfAirPlayLog("Enable sequence started; app state=\(UIApplication.shared.applicationState.rawValue)")

        let receiver = TDSAirPlayReceiverManager.shared
        if !receiver.isEnabled {
            selfAirPlayLog("AirPlay receiver is off; starting it before Bonjour resolution")
            receiver.setEnabled(true)
        }
        guard receiver.isEnabled else {
            selfAirPlayLog("Receiver start failed: \(receiver.errorMessage ?? "unknown error")")
            state = .error(receiver.errorMessage ?? "The AirPlay receiver could not be started.")
            return
        }
        selfAirPlayLog("Receiver is running; resolving its _airplay and _raop records")

        do {
            let services = try await TDSSelfAirPlayServiceResolver.resolve()
            selfAirPlayLog("Resolved AirPlay port=\(services.airPlay.port), TXT=\(services.airPlay.txtRecord.count) bytes; RAOP port=\(services.raop.port), TXT=\(services.raop.txtRecord.count) bytes")
            try Task.checkCancellation()
            let tunnelManager = try await configuredManager(services: services)
            try Task.checkCancellation()
            manager = tunnelManager
            selfAirPlayLog("Starting NETunnelProvider session; current status=\(tunnelManager.connection.status.logName)")
            try tunnelManager.connection.startVPNTunnel()
        } catch is CancellationError {
            selfAirPlayLog("Enable sequence cancelled")
            syntheticPublisher?.stop()
            syntheticPublisher = nil
            state = .off
        } catch {
            selfAirPlayLog("Enable sequence failed: \(error.localizedDescription)")
            syntheticPublisher?.stop()
            syntheticPublisher = nil
            state = .error(error.localizedDescription)
        }
    }

    private func configuredManager(
        services: TDSSelfAirPlayServiceResolver.Services
    ) async throws -> NETunnelProviderManager {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.thomasdye.TDS-Video2"
        let providerIdentifier = bundleIdentifier + ".SelfAirPlayTunnel"
        let managers = try await NETunnelProviderManager.loadAllFromPreferences()
        selfAirPlayLog("Loaded \(managers.count) packet tunnel configuration(s); provider=\(providerIdentifier)")
        let manager = managers.first(where: {
            ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == providerIdentifier
        }) ?? NETunnelProviderManager()

        let tunnelProtocol = NETunnelProviderProtocol()
        tunnelProtocol.providerBundleIdentifier = providerIdentifier
        tunnelProtocol.serverAddress = "Self AirPlay"
        let syntheticName = services.airPlay.name + " (This iPhone)"
        let identity = virtualIdentity()
        let airPlayTXT = rewrittenTXTRecord(services.airPlay.txtRecord, identity: identity)
        let raopTXT = rewrittenTXTRecord(services.raop.txtRecord, identity: identity)
        let syntheticRAOPName = identity.compactDeviceID + "@" + syntheticName
        syntheticPublisher?.stop()
        let publisher = TDSSelfAirPlayPublisher(
            airPlayName: syntheticName,
            airPlayPort: services.airPlay.port,
            airPlayTXT: airPlayTXT,
            raopName: syntheticRAOPName,
            raopPort: services.raop.port,
            raopTXT: raopTXT
        )
        syntheticPublisher = publisher
        publisher.start()
        tunnelProtocol.providerConfiguration = [
            "airPlayName": syntheticName,
            "airPlayPort": NSNumber(value: services.airPlay.port),
            "airPlayTXT": airPlayTXT,
            "raopName": syntheticRAOPName,
            "raopPort": NSNumber(value: services.raop.port),
            "raopTXT": raopTXT
        ]
        manager.protocolConfiguration = tunnelProtocol
        manager.localizedDescription = "TDS Self AirPlay"
        manager.isEnabled = true
        selfAirPlayLog("Saving tunnel configuration for \(syntheticName) with virtual peer 198.18.0.2 and virtual device ID \(identity.deviceID)")
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        selfAirPlayLog("Tunnel configuration saved and reloaded successfully")
        return manager
    }

    private func virtualIdentity() -> VirtualIdentity {
        let defaultsKey = "TDSSelfAirPlayVirtualIdentity"
        let defaults = UserDefaults.standard
        let identifier: UUID
        if let stored = defaults.string(forKey: defaultsKey), let uuid = UUID(uuidString: stored) {
            identifier = uuid
        } else {
            identifier = UUID()
            defaults.set(identifier.uuidString, forKey: defaultsKey)
        }

        var uuid = identifier.uuid
        var bytes = withUnsafeBytes(of: &uuid) { Array($0.prefix(6)) }
        // Mark this as a locally administered unicast address so it cannot collide with hardware.
        bytes[0] = (bytes[0] & 0xfc) | 0x02
        let compact = bytes.map { String(format: "%02X", $0) }.joined()
        let deviceID = stride(from: 0, to: compact.count, by: 2).map { offset -> String in
            let start = compact.index(compact.startIndex, offsetBy: offset)
            let end = compact.index(start, offsetBy: 2)
            return String(compact[start..<end])
        }.joined(separator: ":")
        return VirtualIdentity(
            deviceID: deviceID,
            compactDeviceID: compact,
            persistentID: identifier.uuidString.uppercased()
        )
    }

    private func rewrittenTXTRecord(_ data: Data, identity: VirtualIdentity) -> Data {
        var values = NetService.dictionary(fromTXTRecord: data)
        values["deviceid"] = Data(identity.deviceID.utf8)

        // These identity/group fields are used by AirPlay discovery to coalesce the same device.
        // Preserve capability and public-key fields so the real receiver can still negotiate.
        for key in ["pi", "psi", "gid"] where values[key] != nil {
            values[key] = Data(identity.persistentID.utf8)
        }
        if values["serialNumber"] != nil {
            values["serialNumber"] = Data(identity.compactDeviceID.utf8)
        }
        if values["btaddr"] != nil {
            values["btaddr"] = Data(identity.deviceID.utf8)
        }
        selfAirPlayLog("Rewrote Bonjour identity fields; TXT keys=\(values.keys.sorted())")
        return NetService.data(fromTXTRecord: values)
    }

    private func refreshStatus() async {
        do {
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? "net.thomasdye.TDS-Video2"
            let providerIdentifier = bundleIdentifier + ".SelfAirPlayTunnel"
            manager = try await NETunnelProviderManager.loadAllFromPreferences().first(where: {
                ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier == providerIdentifier
            })
            if let status = manager?.connection.status {
                selfAirPlayLog("Restored tunnel status: \(status.logName)")
                apply(status)
            } else {
                selfAirPlayLog("No saved Self AirPlay tunnel configuration found")
            }
        } catch {
            selfAirPlayLog("Could not load saved tunnel configuration: \(error.localizedDescription)")
            state = .off
        }
    }

    private func apply(_ status: NEVPNStatus) {
        selfAirPlayLog("VPN status changed to \(status.logName)")
        switch status {
        case .connected:
            state = .connected
            requestTunnelDiagnostics()
        case .connecting, .reasserting:
            state = .preparing
        case .disconnecting:
            break
        case .disconnected, .invalid:
            if state.isEnabled { state = .off }
        @unknown default:
            state = .off
        }
    }

    private func requestTunnelDiagnostics() {
        guard let session = manager?.connection as? NETunnelProviderSession else {
            selfAirPlayLog("Connected session is not a NETunnelProviderSession")
            return
        }
        let request = Data("status".utf8)
        do {
            try session.sendProviderMessage(request) { response in
                guard let response,
                      let status = try? PropertyListSerialization.propertyList(from: response, options: [], format: nil) as? [String: Any] else {
                    selfAirPlayLog("Tunnel did not return a diagnostic response")
                    return
                }
                selfAirPlayLog("Tunnel diagnostics: \(status)")
            }
        } catch {
            selfAirPlayLog("Could not request tunnel diagnostics: \(error.localizedDescription)")
        }
    }
}

@MainActor
private final class TDSSelfAirPlayPublisher: NSObject, @preconcurrency NetServiceDelegate {
    private let airPlay: NetService
    private let raop: NetService

    init(
        airPlayName: String,
        airPlayPort: UInt16,
        airPlayTXT: Data,
        raopName: String,
        raopPort: UInt16,
        raopTXT: Data
    ) {
        airPlay = NetService(
            domain: "local.",
            type: "_airplay._tcp.",
            name: airPlayName,
            port: Int32(airPlayPort)
        )
        raop = NetService(
            domain: "local.",
            type: "_raop._tcp.",
            name: raopName,
            port: Int32(raopPort)
        )
        super.init()
        airPlay.delegate = self
        raop.delegate = self
        airPlay.includesPeerToPeer = true
        raop.includesPeerToPeer = true
        airPlay.setTXTRecord(airPlayTXT)
        raop.setTXTRecord(raopTXT)
    }

    func start() {
        selfAirPlayLog("Publishing synthetic services through Bonjour: \(airPlay.name):\(airPlay.port), \(raop.name):\(raop.port)")
        airPlay.publish()
        raop.publish()
    }

    func stop() {
        selfAirPlayLog("Stopping synthetic Bonjour services")
        airPlay.stop()
        raop.stop()
    }

    func netServiceDidPublish(_ sender: NetService) {
        selfAirPlayLog("Synthetic Bonjour service published: \(sender.name).\(sender.type) port=\(sender.port)")
    }

    func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        selfAirPlayLog("Synthetic Bonjour publish failed for \(sender.name).\(sender.type): \(errorDict)")
    }
}

@MainActor
private final class TDSSelfAirPlayServiceResolver: NSObject,
    @preconcurrency NetServiceBrowserDelegate,
    @preconcurrency NetServiceDelegate {
    struct ResolvedService {
        let name: String
        let port: UInt16
        let txtRecord: Data
    }

    struct Services {
        let airPlay: ResolvedService
        let raop: ResolvedService
    }

    enum ResolveError: LocalizedError {
        case timedOut
        case invalidPort

        var errorDescription: String? {
            switch self {
            case .timedOut:
                return "The app could not resolve its own AirPlay Bonjour services. Check Local Network access and try again."
            case .invalidPort:
                return "The AirPlay receiver advertised an invalid network port."
            }
        }
    }

    private var browsers: [NetServiceBrowser] = []
    private var resolvingServices: [NetService] = []
    private var airPlay: ResolvedService?
    private var raop: ResolvedService?
    private var continuation: CheckedContinuation<Services, Error>?
    private var timeoutTask: Task<Void, Never>?

    static func resolve() async throws -> Services {
        let resolver = TDSSelfAirPlayServiceResolver()
        selfAirPlayLog("Bonjour resolver created; timeout=8 seconds")
        return try await withCheckedThrowingContinuation { continuation in
            resolver.continuation = continuation
            resolver.start()
            resolver.timeoutTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(8))
                guard !Task.isCancelled else { return }
                selfAirPlayLog("Bonjour resolver timeout fired")
                resolver.finish(.failure(ResolveError.timedOut))
            }
        }
    }

    private func start() {
        for type in ["_airplay._tcp.", "_raop._tcp."] {
            selfAirPlayLog("Browsing \(type) in local. (includesPeerToPeer=true)")
            let browser = NetServiceBrowser()
            browser.delegate = self
            browser.includesPeerToPeer = true
            browsers.append(browser)
            browser.searchForServices(ofType: type, inDomain: "local.")
        }
    }

    func netServiceBrowser(
        _ browser: NetServiceBrowser,
        didFind service: NetService,
        moreComing: Bool
    ) {
        selfAirPlayLog("Bonjour found name=\(service.name), type=\(service.type), domain=\(service.domain)")
        let isAirPlay = service.type.hasPrefix("_airplay") && service.name == "TDS Carplay"
        let isRAOP = service.type.hasPrefix("_raop") && service.name.hasSuffix("@TDS Carplay")
        guard isAirPlay || isRAOP else {
            selfAirPlayLog("Ignoring unrelated Bonjour service \(service.name)")
            return
        }
        selfAirPlayLog("Resolving matching \(isAirPlay ? "AirPlay" : "RAOP") service \(service.name)")
        service.delegate = self
        service.includesPeerToPeer = true
        resolvingServices.append(service)
        service.resolve(withTimeout: 5)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        selfAirPlayLog("Bonjour browser failed: \(errorDict)")
        finish(.failure(NSError(
            domain: NetService.errorDomain,
            code: errorDict[NetService.errorCode]?.intValue ?? -1,
            userInfo: [NSLocalizedDescriptionKey: "Bonjour browsing failed: \(errorDict)"]
        )))
    }

    func netServiceDidResolveAddress(_ sender: NetService) {
        selfAirPlayLog("Bonjour resolved name=\(sender.name), type=\(sender.type), port=\(sender.port), addresses=\(sender.addresses?.count ?? 0), TXT=\(sender.txtRecordData()?.count ?? 0) bytes")
        guard sender.port > 0, sender.port <= Int(UInt16.max) else {
            finish(.failure(ResolveError.invalidPort))
            return
        }

        let service = ResolvedService(
            name: sender.name,
            port: UInt16(sender.port),
            txtRecord: sender.txtRecordData() ?? Data()
        )
        if sender.type.hasPrefix("_airplay") {
            airPlay = service
        } else if sender.type.hasPrefix("_raop") {
            raop = service
        }

        if let airPlay, let raop {
            finish(.success(Services(airPlay: airPlay, raop: raop)))
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        selfAirPlayLog("Bonjour did not resolve name=\(sender.name), type=\(sender.type): \(errorDict)")
    }

    private func finish(_ result: Result<Services, Error>) {
        guard let continuation else { return }
        switch result {
        case .success:
            selfAirPlayLog("Bonjour resolver completed successfully")
        case .failure(let error):
            selfAirPlayLog("Bonjour resolver failed: \(error.localizedDescription)")
        }
        self.continuation = nil
        timeoutTask?.cancel()
        timeoutTask = nil
        browsers.forEach { $0.stop() }
        resolvingServices.forEach { $0.stop() }
        browsers.removeAll()
        resolvingServices.removeAll()
        continuation.resume(with: result)
    }
}

private extension NEVPNStatus {
    var logName: String {
        switch self {
        case .invalid: return "invalid"
        case .disconnected: return "disconnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        case .reasserting: return "reasserting"
        case .disconnecting: return "disconnecting"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}
