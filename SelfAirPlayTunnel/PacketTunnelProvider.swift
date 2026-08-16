import Foundation
import NetworkExtension
import os

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private enum Address {
        static let local = [UInt8](arrayLiteral: 198, 18, 0, 1)
        static let peer = [UInt8](arrayLiteral: 198, 18, 0, 2)
        static let multicastDNS = [UInt8](arrayLiteral: 224, 0, 0, 251)
    }

    private let logger = Logger(subsystem: "net.thomasdye.TDS-Video2.SelfAirPlayTunnel", category: "PacketReflection")
    private var isRunning = false
    private var reflectedPacketCount: UInt64 = 0
    private var inspectedPacketCount: UInt64 = 0
    private var announcementCount: UInt64 = 0
    private var unicastAnnouncementCount: UInt64 = 0
    private var mdnsQueryCount: UInt64 = 0
    private var mdnsResponseCount: UInt64 = 0
    private var announcementTimer: DispatchSourceTimer?
    private var providerConfiguration: [String: Any]?

    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        emitLog("startTunnel called; bundle=\(Bundle.main.bundleIdentifier ?? "unknown"), options=\(options?.keys.sorted() ?? [])")
        if let configuration = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration {
            providerConfiguration = configuration
            emitLog("Provider configuration keys=\(configuration.keys.sorted()); AirPlay=\(configuration["airPlayName"] ?? "missing"):\(configuration["airPlayPort"] ?? "missing"), RAOP=\(configuration["raopName"] ?? "missing"):\(configuration["raopPort"] ?? "missing")")
        } else {
            emitLog("ERROR: protocolConfiguration has no providerConfiguration dictionary")
        }
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.252"])
        ipv4.includedRoutes = [
            NEIPv4Route(destinationAddress: "198.18.0.2", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "224.0.0.251", subnetMask: "255.255.255.255")
        ]
        settings.ipv4Settings = ipv4
        settings.mtu = 1500

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self else {
                completionHandler(error)
                return
            }
            if let error {
                self.emitLog("ERROR installing tunnel settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }

            self.isRunning = true
            self.readPackets()
            self.startBonjourAnnouncements()
            self.emitLog("Tunnel settings installed: local=198.18.0.1/30, included routes=198.18.0.2/32 + 224.0.0.251/32, MTU=1500")
            completionHandler(nil)
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        isRunning = false
        announcementTimer?.cancel()
        announcementTimer = nil
        emitLog("Tunnel stopped reason=\(reason.rawValue); inspected=\(inspectedPacketCount), reflected=\(reflectedPacketCount), multicast announcements=\(announcementCount), unicast announcements=\(unicastAnnouncementCount), mDNS queries=\(mdnsQueryCount), direct responses=\(mdnsResponseCount)")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        let response: [String: Any] = [
            "running": isRunning,
            "reflectedPackets": reflectedPacketCount,
            "inspectedPackets": inspectedPacketCount,
            "bonjourAnnouncements": announcementCount,
            "unicastAnnouncements": unicastAnnouncementCount,
            "mdnsQueries": mdnsQueryCount,
            "mdnsResponses": mdnsResponseCount,
            "localAddress": "198.18.0.1",
            "peerAddress": "198.18.0.2"
        ]
        completionHandler?(try? PropertyListSerialization.data(
            fromPropertyList: response,
            format: .binary,
            options: 0
        ))
    }

    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self, self.isRunning else { return }

            var reflected: [Data] = []
            var reflectedProtocols: [NSNumber] = []
            for (packet, family) in zip(packets, protocols) where family.int32Value == AF_INET {
                self.inspectedPacketCount += 1
                if self.inspectedPacketCount <= 20 {
                    self.emitLog("Packet #\(self.inspectedPacketCount): \(Self.packetDescription(packet))")
                }
                if Self.isMDNSQuery(packet),
                   let configuration = self.providerConfiguration,
                   let response = Self.makeBonjourAnnouncement(
                       configuration: configuration,
                       destination: Self.sourceAddress(of: packet) ?? Address.local
                   ) {
                    self.mdnsQueryCount += 1
                    self.mdnsResponseCount += 1
                    reflected.append(response)
                    reflectedProtocols.append(NSNumber(value: AF_INET))
                    if self.mdnsQueryCount <= 10 || self.mdnsQueryCount.isMultiple(of: 25) {
                        self.emitLog("Answered mDNS query #\(self.mdnsQueryCount) with direct synthetic response to \(Self.sourceAddress(of: packet)?.map(String.init).joined(separator: ".") ?? "198.18.0.1")")
                    }
                } else if let packet = Self.reflectIPv4Packet(packet) {
                    reflected.append(packet)
                    reflectedProtocols.append(NSNumber(value: AF_INET))
                }
            }

            if !reflected.isEmpty {
                self.reflectedPacketCount += UInt64(reflected.count)
                let accepted = self.packetFlow.writePackets(reflected, withProtocols: reflectedProtocols)
                if self.reflectedPacketCount <= 20 || self.reflectedPacketCount.isMultiple(of: 100) {
                    self.emitLog("Reflected batch=\(reflected.count), total=\(self.reflectedPacketCount), writeAccepted=\(accepted)")
                }
            }
            self.readPackets()
        }
    }

    private static func reflectIPv4Packet(_ data: Data) -> Data? {
        var bytes = [UInt8](data)
        guard bytes.count >= 28, bytes[0] >> 4 == 4 else { return nil }

        let headerLength = Int(bytes[0] & 0x0f) * 4
        let totalLength = Int(bytes[2]) << 8 | Int(bytes[3])
        guard headerLength >= 20,
              totalLength >= headerLength + 8,
              totalLength <= bytes.count else { return nil }

        let fragmentField = UInt16(bytes[6]) << 8 | UInt16(bytes[7])
        guard fragmentField & 0x3fff == 0,
              Array(bytes[12..<16]) == Address.local,
              Array(bytes[16..<20]) == Address.peer,
              bytes[9] == IPPROTO_TCP || bytes[9] == IPPROTO_UDP else { return nil }

        bytes.replaceSubrange(12..<16, with: Address.peer)
        bytes.replaceSubrange(16..<20, with: Address.local)

        bytes[10] = 0
        bytes[11] = 0
        let ipChecksum = internetChecksum(bytes[0..<headerLength])
        bytes[10] = UInt8(ipChecksum >> 8)
        bytes[11] = UInt8(ipChecksum & 0xff)

        let transportLength = totalLength - headerLength
        let checksumOffset = bytes[9] == IPPROTO_TCP ? headerLength + 16 : headerLength + 6
        guard checksumOffset + 1 < totalLength else { return nil }
        bytes[checksumOffset] = 0
        bytes[checksumOffset + 1] = 0

        var pseudoHeader = Array(bytes[12..<20])
        pseudoHeader.append(0)
        pseudoHeader.append(bytes[9])
        pseudoHeader.append(UInt8(transportLength >> 8))
        pseudoHeader.append(UInt8(transportLength & 0xff))
        pseudoHeader.append(contentsOf: bytes[headerLength..<totalLength])
        var transportChecksum = internetChecksum(pseudoHeader[...])
        if bytes[9] == IPPROTO_UDP && transportChecksum == 0 {
            transportChecksum = 0xffff
        }
        bytes[checksumOffset] = UInt8(transportChecksum >> 8)
        bytes[checksumOffset + 1] = UInt8(transportChecksum & 0xff)

        return Data(bytes[0..<totalLength])
    }

    private func startBonjourAnnouncements() {
        guard let configuration = providerConfiguration,
              let multicastPacket = Self.makeBonjourAnnouncement(
                  configuration: configuration,
                  destination: Address.multicastDNS
              ),
              let unicastPacket = Self.makeBonjourAnnouncement(
                  configuration: configuration,
                  destination: Address.local
              ) else {
            emitLog("ERROR: could not build Bonjour announcement from provider configuration")
            return
        }
        emitLog("Built synthetic Bonjour announcements: multicast=\(multicastPacket.count) bytes, inbound unicast=\(unicastPacket.count) bytes")

        let sendAnnouncement = { [weak self] in
            guard let self, self.isRunning else { return }
            self.announcementCount += 1
            self.unicastAnnouncementCount += 1
            let accepted = self.packetFlow.writePackets(
                [multicastPacket, unicastPacket],
                withProtocols: [NSNumber(value: AF_INET), NSNumber(value: AF_INET)]
            )
            if self.announcementCount <= 3 || self.announcementCount.isMultiple(of: 10) {
                self.emitLog("Injected Bonjour announcement pair #\(self.announcementCount) (multicast + inbound unicast to 198.18.0.1), writeAccepted=\(accepted)")
            }
        }
        sendAnnouncement()

        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now() + 1, repeating: 2)
        timer.setEventHandler(handler: sendAnnouncement)
        announcementTimer = timer
        timer.resume()
    }

    private static func makeBonjourAnnouncement(
        configuration: [String: Any],
        destination: [UInt8]
    ) -> Data? {
        guard let airPlayName = configuration["airPlayName"] as? String,
              let airPlayPort = (configuration["airPlayPort"] as? NSNumber)?.uint16Value,
              let airPlayTXT = configuration["airPlayTXT"] as? Data,
              let raopName = configuration["raopName"] as? String,
              let raopPort = (configuration["raopPort"] as? NSNumber)?.uint16Value,
              let raopTXT = configuration["raopTXT"] as? Data else { return nil }

        let host = "tds-self-airplay.local"
        let airPlayType = "_airplay._tcp.local"
        let raopType = "_raop._tcp.local"
        let airPlayInstance = "\(airPlayName).\(airPlayType)"
        let raopInstance = "\(raopName).\(raopType)"

        var dns = Data()
        dns.appendUInt16(0)
        dns.appendUInt16(0x8400)
        dns.appendUInt16(0)
        dns.appendUInt16(7)
        dns.appendUInt16(0)
        dns.appendUInt16(0)
        dns.appendDNSRecord(name: airPlayType, type: 12, value: Data.dnsName(airPlayInstance))
        dns.appendDNSRecord(name: raopType, type: 12, value: Data.dnsName(raopInstance))
        dns.appendDNSRecord(name: airPlayInstance, type: 33, value: Data.srv(port: airPlayPort, host: host), cacheFlush: true)
        dns.appendDNSRecord(name: airPlayInstance, type: 16, value: airPlayTXT, cacheFlush: true)
        dns.appendDNSRecord(name: raopInstance, type: 33, value: Data.srv(port: raopPort, host: host), cacheFlush: true)
        dns.appendDNSRecord(name: raopInstance, type: 16, value: raopTXT, cacheFlush: true)
        dns.appendDNSRecord(name: host, type: 1, value: Data(Address.peer), cacheFlush: true)

        return makeIPv4UDPPacket(
            source: Address.peer,
            destination: destination,
            sourcePort: 5353,
            destinationPort: 5353,
            payload: dns
        )
    }

    private static func makeIPv4UDPPacket(
        source: [UInt8],
        destination: [UInt8],
        sourcePort: UInt16,
        destinationPort: UInt16,
        payload: Data
    ) -> Data {
        let udpLength = 8 + payload.count
        let totalLength = 20 + udpLength
        var bytes = [UInt8](repeating: 0, count: totalLength)
        bytes[0] = 0x45
        bytes[2] = UInt8(totalLength >> 8)
        bytes[3] = UInt8(totalLength & 0xff)
        bytes[6] = 0x40
        bytes[8] = 255
        bytes[9] = UInt8(IPPROTO_UDP)
        bytes.replaceSubrange(12..<16, with: source)
        bytes.replaceSubrange(16..<20, with: destination)
        bytes[20] = UInt8(sourcePort >> 8)
        bytes[21] = UInt8(sourcePort & 0xff)
        bytes[22] = UInt8(destinationPort >> 8)
        bytes[23] = UInt8(destinationPort & 0xff)
        bytes[24] = UInt8(udpLength >> 8)
        bytes[25] = UInt8(udpLength & 0xff)
        bytes.replaceSubrange(28..<totalLength, with: payload)

        let ipChecksum = internetChecksum(bytes[0..<20])
        bytes[10] = UInt8(ipChecksum >> 8)
        bytes[11] = UInt8(ipChecksum & 0xff)

        var pseudoHeader = source + destination + [0, UInt8(IPPROTO_UDP), UInt8(udpLength >> 8), UInt8(udpLength & 0xff)]
        pseudoHeader.append(contentsOf: bytes[20..<totalLength])
        var udpChecksum = internetChecksum(pseudoHeader[...])
        if udpChecksum == 0 { udpChecksum = 0xffff }
        bytes[26] = UInt8(udpChecksum >> 8)
        bytes[27] = UInt8(udpChecksum & 0xff)
        return Data(bytes)
    }

    private static func internetChecksum<S: Sequence>(_ bytes: S) -> UInt16 where S.Element == UInt8 {
        var sum: UInt32 = 0
        var highByte: UInt8?
        for byte in bytes {
            if let high = highByte {
                sum += UInt32(UInt16(high) << 8 | UInt16(byte))
                highByte = nil
            } else {
                highByte = byte
            }
        }
        if let high = highByte { sum += UInt32(UInt16(high) << 8) }
        while sum >> 16 != 0 { sum = (sum & 0xffff) + (sum >> 16) }
        return ~UInt16(sum & 0xffff)
    }

    private static func packetDescription(_ data: Data) -> String {
        let bytes = [UInt8](data)
        guard bytes.count >= 20, bytes[0] >> 4 == 4 else {
            return "non-IPv4 or short packet, length=\(bytes.count)"
        }
        let source = bytes[12..<16].map(String.init).joined(separator: ".")
        let destination = bytes[16..<20].map(String.init).joined(separator: ".")
        let name: String
        switch bytes[9] {
        case UInt8(IPPROTO_TCP): name = "TCP"
        case UInt8(IPPROTO_UDP): name = "UDP"
        default: name = "protocol \(bytes[9])"
        }
        return "\(name) \(source) -> \(destination), length=\(bytes.count)"
    }

    private static func sourceAddress(of data: Data) -> [UInt8]? {
        let bytes = [UInt8](data)
        guard bytes.count >= 20, bytes[0] >> 4 == 4 else { return nil }
        return Array(bytes[12..<16])
    }

    private static func isMDNSQuery(_ data: Data) -> Bool {
        let bytes = [UInt8](data)
        guard bytes.count >= 40,
              bytes[0] >> 4 == 4,
              bytes[9] == UInt8(IPPROTO_UDP),
              Array(bytes[16..<20]) == Address.multicastDNS else { return false }
        let headerLength = Int(bytes[0] & 0x0f) * 4
        guard headerLength >= 20, bytes.count >= headerLength + 20 else { return false }
        let destinationPort = UInt16(bytes[headerLength + 2]) << 8 | UInt16(bytes[headerLength + 3])
        guard destinationPort == 5353 else { return false }
        let dnsFlags = UInt16(bytes[headerLength + 10]) << 8 | UInt16(bytes[headerLength + 11])
        return dnsFlags & 0x8000 == 0
    }

    private func emitLog(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        NSLog("[SelfAirPlayTunnel] %@", message)
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8(value >> 8))
        append(UInt8(value & 0xff))
    }

    static func dnsName(_ name: String) -> Data {
        var result = Data()
        for label in name.split(separator: ".", omittingEmptySubsequences: true) {
            let bytes = Data(label.utf8.prefix(63))
            result.append(UInt8(bytes.count))
            result.append(bytes)
        }
        result.append(0)
        return result
    }

    static func srv(port: UInt16, host: String) -> Data {
        var result = Data()
        result.appendUInt16(0)
        result.appendUInt16(0)
        result.appendUInt16(port)
        result.append(dnsName(host))
        return result
    }

    mutating func appendDNSRecord(name: String, type: UInt16, value: Data, cacheFlush: Bool = false) {
        append(Self.dnsName(name))
        appendUInt16(type)
        appendUInt16(cacheFlush ? 0x8001 : 0x0001)
        append(contentsOf: [0, 0, 0, 120])
        appendUInt16(UInt16(value.count))
        append(value)
    }
}
