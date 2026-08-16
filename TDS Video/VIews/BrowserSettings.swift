import SwiftUI
import UIKit

enum TDSIOSBrowserEngine: String, CaseIterable, Identifiable {
    case standard
    case minimal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .minimal:
            return "Custom"
        }
    }
}

enum TDSBrowserSettings {
    static let iOSBrowserEngineKey = "TDSIOSBrowserEngine"
}

final class MinimalBrowserHost {
    static let shared = MinimalBrowserHost()

    weak var controller: MinimalBrowserViewController?

    private init() {}

    func loadURL(_ url: URL) {
        controller?.load(url)
    }

    func loadURLString(_ urlString: String) {
        controller?.loadURLString(urlString)
    }

    func reload() {
        controller?.reload()
    }

    func goBack() {
        controller?.goBack()
    }

    func goForward() {
        controller?.goForward()
    }
}

struct MinimalBrowserRepresentable: UIViewControllerRepresentable {
    let initialURLString: String?

    func makeUIViewController(context: Context) -> MinimalBrowserViewController {
        let controller = MinimalBrowserViewController(urlString: initialURLString)
        controller.allowsInlineMediaPlayback = true
        controller.userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1"
        MinimalBrowserHost.shared.controller = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: MinimalBrowserViewController, context: Context) {
        MinimalBrowserHost.shared.controller = uiViewController
    }
}

struct AppSettingsView: View {
    @StateObject private var airPlayReceiver = TDSAirPlayReceiverManager.shared
    @StateObject private var selfAirPlay = TDSSelfAirPlayManager.shared
    @AppStorage(TDSBrowserSettings.iOSBrowserEngineKey) private var browserEngine = TDSIOSBrowserEngine.standard.rawValue
    @AppStorage(CustomWebViewController.youtubeFullscreenEnabledKey) private var youtubeFullscreenEnabled = true
    @AppStorage(CustomWebViewController.youtubeAutoFitEnabledKey) private var youtubeAutoFitEnabled = true
    @AppStorage(CustomWebViewController.youtubeFitScaleKey) private var youtubeFitScale = CustomWebViewController.youtubeFitScaleDefault
    @AppStorage(CustomWebViewController.youtubeAutoFitDelayKey) private var youtubeAutoFitDelay = 3.0
    @AppStorage(CustomWebViewController.youtubeCustomPickerEnabledKey) private var youtubeCustomPickerEnabled = true
    @AppStorage(CustomWebViewController.youtubePickerSearchEnabledKey) private var youtubePickerSearchEnabled = false
    @AppStorage(CustomWebViewController.youtubeNativeRecommendationsEnabledKey) private var youtubeNativeRecommendationsEnabled = false
    @State private var iconChangeMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("AirPlay Receiver") {
                    Toggle("Receive AirPlay", isOn: Binding(
                        get: { airPlayReceiver.isEnabled },
                        set: { airPlayReceiver.setEnabled($0) }
                    ))
                    .disabled(selfAirPlay.state.isEnabled)

                    LabeledContent("Receiver name", value: "TDS Carplay")

                    VStack(alignment: .leading) {
                        Text("CarPlay zoom \(String(format: "%.2f", airPlayReceiver.carPlayViewScale))")
                        Slider(
                            value: Binding(
                                get: { airPlayReceiver.carPlayViewScale },
                                set: { airPlayReceiver.setCarPlayViewScale($0) }
                            ),
                            in: TDSAirPlayReceiverManager.carPlayViewScaleRange,
                            step: 0.05
                        )
                    }

                    if let errorMessage = airPlayReceiver.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    } else {
                        Text(airPlayReceiver.isEnabled
                             ? "Ready for another device on this Wi-Fi network. It stays active while CarPlay is connected, even if the phone screen is no longer showing the app."
                             : "Off by default to save power. It turns off when the app backgrounds unless CarPlay is still connected.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Self AirPlay (Experimental)") {
                    Toggle("Show on this iPhone", isOn: Binding(
                        get: { selfAirPlay.state.isEnabled },
                        set: { selfAirPlay.setEnabled($0) }
                    ))

                    Text(selfAirPlay.state.description)
                        .font(.footnote)
                        .foregroundStyle(selfAirPlayErrorColor)

                    Text("This creates a local VPN that makes the receiver look like a separate device at 198.18.0.2. It cannot be used at the same time as another VPN.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("iOS Browser") {
                    Picker("Engine", selection: $browserEngine) {
                        ForEach(TDSIOSBrowserEngine.allCases) { engine in
                            Text(engine.title).tag(engine.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(browserEngine == TDSIOSBrowserEngine.minimal.rawValue
                         ? "Uses the custom browser you added for the iOS browser tab."
                         : "Uses the existing WKWebView browser with all current CarPlay control hooks.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("App Icon") {
                    Button {
                        setAppIcon("TV")
                    } label: {
                        Label("Use TV Icon", systemImage: "tv")
                    }
                    .disabled(!UIApplication.shared.supportsAlternateIcons || UIApplication.shared.alternateIconName == "TV")

                    Button {
                        setAppIcon(nil)
                    } label: {
                        Label("Use Default Icon", systemImage: "app")
                    }
                    .disabled(!UIApplication.shared.supportsAlternateIcons || UIApplication.shared.alternateIconName == nil)

                    if let iconChangeMessage {
                        Text(iconChangeMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("YouTube") {
                    Toggle("Custom CarPlay homepage", isOn: $youtubeCustomPickerEnabled)
                        .onChange(of: youtubeCustomPickerEnabled) { _, newValue in
                            CustomWebViewController.shared.setYouTubeCustomPickerEnabled(newValue)
                        }

                    Text(youtubeCustomPickerEnabled
                         ? "Shows the simplified recommendation picker on YouTube Home."
                         : "Shows YouTube's usual signed-in homepage.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("YouTube search (Beta)", isOn: $youtubePickerSearchEnabled)
                        .disabled(!youtubeCustomPickerEnabled)
                        .onChange(of: youtubePickerSearchEnabled) { _, newValue in
                            CustomWebViewController.shared.setYouTubePickerSearchEnabled(newValue)
                        }

                    Text("Adds a native Search map button and CarPlay keyboard to the YouTube browser controls.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Native recommendation list (Beta)", isOn: $youtubeNativeRecommendationsEnabled)
                        .disabled(!youtubeCustomPickerEnabled)
                        .onChange(of: youtubeNativeRecommendationsEnabled) { _, newValue in
                            CustomWebViewController.shared.setYouTubeNativeRecommendationsEnabled(newValue)
                        }

                    Text("Opens recommendations in tappable CarPlay image rows with larger thumbnails.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Fit video to current view", isOn: $youtubeFullscreenEnabled)
                        .onChange(of: youtubeFullscreenEnabled) { _, newValue in
                            CustomWebViewController.shared.setYouTubeFullscreenEnabled(newValue)
                        }

                    Toggle("Auto-fit after load", isOn: $youtubeAutoFitEnabled)
                        .onChange(of: youtubeAutoFitEnabled) { _, newValue in
                            CustomWebViewController.shared.setYouTubeAutoFitEnabled(newValue)
                        }

                    VStack(alignment: .leading) {
                        Text("Fit zoom \(String(format: "%.2f", youtubeFitScale))")
                        Slider(value: $youtubeFitScale, in: CustomWebViewController.youtubeFitScaleRange, step: 0.01)
                            .onChange(of: youtubeFitScale) { _, newValue in
                                CustomWebViewController.shared.setYouTubeFitScale(newValue)
                            }
                    }

                    VStack(alignment: .leading) {
                        Text("Auto-fit delay \(String(format: "%.1f", youtubeAutoFitDelay))s")
                        Slider(value: $youtubeAutoFitDelay, in: 0.5...8.0, step: 0.5)
                            .onChange(of: youtubeAutoFitDelay) { _, newValue in
                                CustomWebViewController.shared.setYouTubeAutoFitDelay(newValue)
                            }
                    }
                }

                Section("CarPlay Controls") {
                    NavigationLink(destination: WebViewButtons()) {
                        Label("Advanced Web Controls", systemImage: "cursorarrow.rays")
                    }

                    Button {
                        startLiveControls()
                    } label: {
                        Label("Start Live Controls", systemImage: "play.circle")
                    }

                    Button(role: .destructive) {
                        stopLiveControls()
                    } label: {
                        Label("Stop Live Controls", systemImage: "stop.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var selfAirPlayErrorColor: Color {
        if case .error = selfAirPlay.state { return .red }
        return .secondary
    }

    private func startLiveControls() {
        guard #available(iOS 16.1, *) else { return }

        do {
            try TDSCarPlayControlsLiveActivityManager.start()
        } catch {
            print("Failed to start Live Activity controls: \(error.localizedDescription)")
        }
    }

    private func stopLiveControls() {
        guard #available(iOS 16.1, *) else { return }

        Task {
            await TDSCarPlayControlsLiveActivityManager.stopAll()
        }
    }

    private func setAppIcon(_ iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            iconChangeMessage = "Alternate app icons are not available on this device."
            return
        }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            Task { @MainActor in
                if let error {
                    iconChangeMessage = error.localizedDescription
                } else {
                    iconChangeMessage = iconName == nil ? "Default icon selected." : "TV icon selected."
                }
            }
        }
    }
}
