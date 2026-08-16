import AirPlayReceiver
import AVFoundation
import SwiftUI
import UIKit
import os

@MainActor
final class TDSAirPlayReceiverManager: ObservableObject {
    static let shared = TDSAirPlayReceiverManager()

    @Published private(set) var isEnabled = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var carPlayViewScale: Double

    static let carPlayViewScaleKey = "TDSAirPlayCarPlayViewScale"
    static let carPlayViewScaleDefault = 1.0
    static let carPlayViewScaleRange: ClosedRange<Double> = 0.5...2.0

    private let receiverView: AirPlayReceiverView
    private let standbyView = TDSAirPlayStandbyView()
    private weak var carPlayContainer: UIView?
    private var standbyTimer: Timer?
    private var receiverViewConstraints: [NSLayoutConstraint] = []
    private var standbyViewConstraints: [NSLayoutConstraint] = []
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "net.thomasdye.TDS-Video2",
        category: "AirPlayReceiver"
    )

    private init() {
        let savedScale = UserDefaults.standard.object(forKey: Self.carPlayViewScaleKey) as? Double ?? Self.carPlayViewScaleDefault
        carPlayViewScale = Self.clampCarPlayViewScale(savedScale)

        receiverView = AirPlayReceiverView(
            configuration: .init(
                name: "TDS Carplay",
                advertisedWidth: 1920,
                advertisedHeight: 1080,
                orientation: .landscape,
                audioEnabled: true
            )
        )
        receiverView.scalingMode = .aspectFit
        receiverView.backgroundColor = .black
        receiverView.showsWaitingMessage = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    func setCarPlayViewScale(_ scale: Double) {
        let clampedScale = Self.clampCarPlayViewScale(scale)
        guard carPlayViewScale != clampedScale else { return }

        carPlayViewScale = clampedScale
        UserDefaults.standard.set(clampedScale, forKey: Self.carPlayViewScaleKey)
        attachToCarPlayIfAvailable()
    }

    func setEnabled(_ enabled: Bool) {
        log("setEnabled(\(enabled)); current=\(isEnabled), appState=\(UIApplication.shared.applicationState.rawValue), hasCarPlayContainer=\(carPlayContainer != nil)")
        guard enabled != isEnabled else { return }

        if enabled {
            do {
                log("Starting AirPlayReceiverView named TDS Carplay")
                try receiverView.start()
                isEnabled = true
                errorMessage = nil
                log("AirPlayReceiverView.start() succeeded")
                attachToCarPlayIfAvailable()
            } catch {
                log("ERROR starting AirPlay receiver: \(error.localizedDescription)")
                receiverView.stop()
                isEnabled = false
                errorMessage = error.localizedDescription
            }
        } else {
            log("Stopping AirPlay receiver")
            NSLayoutConstraint.deactivate(receiverViewConstraints)
            NSLayoutConstraint.deactivate(standbyViewConstraints)
            receiverViewConstraints = []
            standbyViewConstraints = []
            receiverView.stop()
            receiverView.removeFromSuperview()
            stopStandbyUpdates()
            isEnabled = false
            errorMessage = nil
        }
    }

    func registerCarPlayContainer(_ container: UIView) {
        log("CarPlay container registered; bounds=\(container.bounds)")
        carPlayContainer = container
        attachToCarPlayIfAvailable()
    }

    func unregisterCarPlayContainer() {
        log("CarPlay container unregistered")
        NSLayoutConstraint.deactivate(receiverViewConstraints)
        NSLayoutConstraint.deactivate(standbyViewConstraints)
        receiverViewConstraints = []
        standbyViewConstraints = []
        receiverView.removeFromSuperview()
        carPlayContainer = nil
        stopStandbyUpdates()

        if UIApplication.shared.applicationState == .background {
            setEnabled(false)
        }
    }

    @objc private func appDidEnterBackground() {
        // A connected CarPlay scene can remain active after the phone scene is
        // backgrounded. Keep receiving while that visible scene owns the view.
        guard carPlayContainer == nil else {
            log("App backgrounded but CarPlay container remains active; keeping receiver running")
            return
        }
        log("App backgrounded without CarPlay container; stopping receiver")
        setEnabled(false)
    }

    private func attachToCarPlayIfAvailable() {
        guard isEnabled, let container = carPlayContainer else {
            log("Receiver not attached: enabled=\(isEnabled), hasCarPlayContainer=\(carPlayContainer != nil)")
            return
        }
        log("Attaching receiver view to CarPlay at scale \(carPlayViewScale)")

        NSLayoutConstraint.deactivate(receiverViewConstraints)
        NSLayoutConstraint.deactivate(standbyViewConstraints)
        receiverViewConstraints = []
        standbyViewConstraints = []
        receiverView.removeFromSuperview()
        receiverView.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .black
        container.clipsToBounds = true
        container.addSubview(receiverView)
        let scale = CGFloat(carPlayViewScale)
        receiverViewConstraints = [
            receiverView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            receiverView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            receiverView.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: scale),
            receiverView.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: scale)
        ]
        NSLayoutConstraint.activate(receiverViewConstraints)

        standbyView.removeFromSuperview()
        standbyView.translatesAutoresizingMaskIntoConstraints = false
        receiverView.addSubview(standbyView)
        standbyViewConstraints = [
            standbyView.leadingAnchor.constraint(equalTo: receiverView.leadingAnchor),
            standbyView.trailingAnchor.constraint(equalTo: receiverView.trailingAnchor),
            standbyView.topAnchor.constraint(equalTo: receiverView.topAnchor),
            standbyView.bottomAnchor.constraint(equalTo: receiverView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(standbyViewConstraints)
        standbyView.isHidden = false
        startStandbyUpdates()
    }

    private static func clampCarPlayViewScale(_ scale: Double) -> Double {
        min(max(scale, carPlayViewScaleRange.lowerBound), carPlayViewScaleRange.upperBound)
    }

    private func startStandbyUpdates() {
        stopStandbyUpdates()
        standbyTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                let layer = self.receiverView.layer as? AVSampleBufferDisplayLayer
                self.standbyView.isHidden = layer?.status == .rendering
            }
        }
    }

    private func stopStandbyUpdates() {
        standbyTimer?.invalidate()
        standbyTimer = nil
    }

    private func log(_ message: String) {
        logger.notice("\(message, privacy: .public)")
        print("[AirPlayReceiver] \(message)")
    }
}

private final class TDSAirPlayStandbyView: UIView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        gradient.colors = [
            UIColor(red: 0.03, green: 0.08, blue: 0.16, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.32, blue: 0.42, alpha: 1).cgColor,
            UIColor(red: 0.08, green: 0.12, blue: 0.24, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)

        let icon = UIImageView(image: UIImage(systemName: "airplayvideo"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .medium)

        let title = UILabel()
        title.text = "AirPlay to TDS Carplay"
        title.textColor = .white
        title.font = .systemFont(ofSize: 30, weight: .bold)
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.7
        title.textAlignment = .center

        let instructions = UILabel()
        instructions.text = "Open Control Centre on your other device, tap Screen Mirroring, then choose TDS Carplay."
        instructions.textColor = UIColor.white.withAlphaComponent(0.82)
        instructions.font = .systemFont(ofSize: 16, weight: .medium)
        instructions.numberOfLines = 2
        instructions.textAlignment = .center

        let ready = UILabel()
        ready.text = "  READY TO CONNECT  "
        ready.textColor = UIColor(red: 0.55, green: 1, blue: 0.86, alpha: 1)
        ready.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        ready.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        ready.layer.cornerRadius = 13
        ready.clipsToBounds = true
        ready.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, title, instructions, ready])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 44),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -44),
            icon.widthAnchor.constraint(equalToConstant: 72),
            icon.heightAnchor.constraint(equalToConstant: 56),
            instructions.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
            ready.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
