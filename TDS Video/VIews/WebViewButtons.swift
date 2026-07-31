//
//  WebViewButtons.swift
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

import SwiftUI

struct WebViewButtons: View {
    @State var buttonColour: Color = .purple
    @State var centerButtonColour: Color = .purple
    @State private var quickSelects: [WebQuickSelect] = CustomWebViewController.shared.loadQuickSelects()
    @State private var quickSelectURL = ""
    @State private var statusText = ""
    @State private var overlayDiagnostics = ""
    @AppStorage(TDSBrowserSettings.iOSBrowserEngineKey) private var browserEngine = TDSIOSBrowserEngine.standard.rawValue
    @AppStorage(CustomWebViewController.youtubeFullscreenEnabledKey) private var youtubeFullscreenEnabled = true
    @AppStorage(CustomWebViewController.youtubeAutoFitEnabledKey) private var youtubeAutoFitEnabled = true
    @AppStorage(CustomWebViewController.youtubeFitScaleKey) private var youtubeFitScale = CustomWebViewController.youtubeFitScaleDefault
    @AppStorage(CustomWebViewController.youtubeAutoFitDelayKey) private var youtubeAutoFitDelay = 3.0
    @AppStorage(CustomWebViewController.youtubeCustomPickerEnabledKey) private var youtubeCustomPickerEnabled = true
    @AppStorage(CustomWebViewController.youtubePickerSearchEnabledKey) private var youtubePickerSearchEnabled = false
    @AppStorage(CustomWebViewController.youtubeNativeRecommendationsEnabledKey) private var youtubeNativeRecommendationsEnabled = false
    let Size: CGFloat = 300
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Cursor Navigation")
                    .font(.headline)

                cursorControl

                Divider()

                Text("Scroll Content")
                    .font(.headline)

                scrollControls

                Divider()

                Text("Resize Web Content")
                    .font(.headline)

                resizeControls

                Divider()

                Text("Move Viewport")
                    .font(.headline)

                viewportControls

                Divider()

                saveControls

                Divider()

                youtubeControls

                Divider()

                liveActivityControls

                Divider()

                quickSelectControls

                Divider()

                extraControls
            }
            .padding()
        }
        .onAppear {
            refreshQuickSelects()
            CustomWebViewController.shared.setYouTubeFullscreenEnabled(youtubeFullscreenEnabled)
            CustomWebViewController.shared.setYouTubeAutoFitEnabled(youtubeAutoFitEnabled)
            CustomWebViewController.shared.setYouTubeFitScale(youtubeFitScale)
            CustomWebViewController.shared.setYouTubeAutoFitDelay(youtubeAutoFitDelay)
            CustomWebViewController.shared.setYouTubeCustomPickerEnabled(youtubeCustomPickerEnabled)
            CustomWebViewController.shared.setYouTubePickerSearchEnabled(youtubePickerSearchEnabled)
            CustomWebViewController.shared.setYouTubeNativeRecommendationsEnabled(youtubeNativeRecommendationsEnabled)
        }
        .onChange(of: youtubeFullscreenEnabled) { _, newValue in
            CustomWebViewController.shared.setYouTubeFullscreenEnabled(newValue)
            statusText = newValue ? "YouTube fullscreen enabled" : "YouTube fullscreen disabled"
        }
        .onChange(of: youtubeAutoFitEnabled) { _, newValue in
            CustomWebViewController.shared.setYouTubeAutoFitEnabled(newValue)
            statusText = newValue ? "YouTube auto-fit enabled" : "YouTube auto-fit disabled"
        }
        .onChange(of: youtubeFitScale) { _, newValue in
            CustomWebViewController.shared.setYouTubeFitScale(newValue)
            statusText = "YouTube fit zoom \(String(format: "%.2f", newValue))"
        }
        .onChange(of: youtubeAutoFitDelay) { _, newValue in
            CustomWebViewController.shared.setYouTubeAutoFitDelay(newValue)
            statusText = "YouTube auto-fit delay \(String(format: "%.1f", newValue))s"
        }
        .onChange(of: youtubeCustomPickerEnabled) { _, newValue in
            CustomWebViewController.shared.setYouTubeCustomPickerEnabled(newValue)
            statusText = newValue ? "Custom YouTube homepage enabled" : "Normal YouTube homepage enabled"
        }
        .onChange(of: youtubePickerSearchEnabled) { _, newValue in
            CustomWebViewController.shared.setYouTubePickerSearchEnabled(newValue)
            statusText = newValue ? "YouTube picker search enabled" : "YouTube picker search disabled"
        }
        .onChange(of: youtubeNativeRecommendationsEnabled) { _, newValue in
            CustomWebViewController.shared.setYouTubeNativeRecommendationsEnabled(newValue)
            statusText = newValue ? "Native recommendation list enabled" : "Native recommendation list disabled"
        }
    }

    // MARK: - Controls

    private var cursorControl: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                controlButton("chevron.up") {
                    CustomWebViewController.shared.moveCursorUp(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorUp(by: 50)
                })
                Spacer()
            }

            HStack {
                controlButton("chevron.left") {
                    CustomWebViewController.shared.moveCursorLeft(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorLeft(by: 50)
                })

                selectButton

                controlButton("chevron.right") {
                    CustomWebViewController.shared.moveCursorRight(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorRight(by: 50)
                })
            }

            HStack {
                Spacer()
                controlButton("chevron.down") {
                    CustomWebViewController.shared.moveCursorDown(by: 10)
                }
                .simultaneousGesture(longPressGesture {
                    CustomWebViewController.shared.moveCursorDown(by: 50)
                })
                Spacer()
            }
        }
    }

    private var scrollControls: some View {
        HStack {
            controlButton("arrow.up.circle") {
                CustomWebViewController.shared.scrollBy(x: 0, y: -100)
            }
            controlButton("arrow.down.circle") {
                CustomWebViewController.shared.scrollBy(x: 0, y: 100)
            }
        }
    }

    private var resizeControls: some View {
        HStack {
            controlButton("plus.magnifyingglass") {
                CustomWebViewController.shared.resizeContent(by: 1.1)
            }
            controlButton("minus.magnifyingglass") {
                CustomWebViewController.shared.resizeContent(by: 0.9)
            }
        }
    }

    private var viewportControls: some View {
        VStack {
            HStack {
                controlButton("chevron.left") {
                    CustomWebViewController.shared.moveHorizontally(by: -10)
                }
                controlButton("chevron.right") {
                    CustomWebViewController.shared.moveHorizontally(by: 10)
                }
            }
            HStack {
                controlButton("chevron.up") {
                    CustomWebViewController.shared.moveVertically(by: -10)
                }
                controlButton("chevron.down") {
                    CustomWebViewController.shared.moveVertically(by: 10)
                }
            }
        }
    }

    private var saveControls: some View {
        VStack(spacing: 12) {
            Button {
                CustomWebViewController.shared.applyCurrentOffsetForBrowser()
                _ = CustomWebViewController.shared.applySavedSettingsForCurrentDomain()
                statusText = "Applied car offset and domain settings"
            } label: {
                Label("Apply Car Offset", systemImage: "arrow.left.and.right")
            }

            Button {
                CustomWebViewController.shared.saveViewSettings()
                statusText = "Saved current layout for this domain"
            } label: {
                Label("Save Domain Layout", systemImage: "square.and.arrow.down")
            }

            Button {
                if CustomWebViewController.shared.applySavedSettingsForCurrentDomain() {
                    statusText = "Applied saved layout"
                } else {
                    statusText = "No saved layout for this domain"
                }
            } label: {
                Label("Apply Domain Layout", systemImage: "rectangle.and.hand.point.up.left")
            }

            Button(role: .destructive) {
                CustomWebViewController.shared.deleteSettingsForCurrentDomain()
                statusText = "Reset layout for this domain"
            } label: {
                Label("Reset Domain Layout", systemImage: "trash")
            }

            if !statusText.isEmpty {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private var youtubeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YouTube")
                .font(.headline)

            Toggle("Custom CarPlay homepage", isOn: $youtubeCustomPickerEnabled)

            Toggle("YouTube search (Beta)", isOn: $youtubePickerSearchEnabled)
                .disabled(!youtubeCustomPickerEnabled)

            Toggle("Native recommendation list (Beta)", isOn: $youtubeNativeRecommendationsEnabled)
                .disabled(!youtubeCustomPickerEnabled)

            Toggle("Try fullscreen on playback", isOn: $youtubeFullscreenEnabled)

            Toggle("Auto-fit after video loads", isOn: $youtubeAutoFitEnabled)

            Button {
                openYouTubeSignIn()
                statusText = "Opened YouTube sign in"
            } label: {
                Label("Sign In / Switch YouTube Account", systemImage: "person.crop.circle")
            }
            .buttonStyle(.borderedProminent)

            VStack(alignment: .leading) {
                Text("Fit Zoom \(String(format: "%.2f", youtubeFitScale))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $youtubeFitScale, in: CustomWebViewController.youtubeFitScaleRange, step: 0.01)
                HStack {
                    Button {
                        adjustYouTubeFitScale(by: -0.02)
                    } label: {
                        Label("Smaller", systemImage: "minus.magnifyingglass")
                    }

                    Button {
                        adjustYouTubeFitScale(by: 0.02)
                    } label: {
                        Label("Bigger", systemImage: "plus.magnifyingglass")
                    }

                    Button {
                        setYouTubeFitScale(CustomWebViewController.youtubeFitScaleDefault)
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading) {
                Text("Auto-fit Delay \(String(format: "%.1f", youtubeAutoFitDelay))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $youtubeAutoFitDelay, in: 0.5...8.0, step: 0.5)
            }

            Button {
                CustomWebViewController.shared.requestYouTubeFullscreenNow()
                statusText = "Requested YouTube fullscreen"
            } label: {
                Label("Try Fullscreen Now", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            .buttonStyle(.bordered)

            Button {
                CustomWebViewController.shared.setYouTubeFitScale(youtubeFitScale)
                CustomWebViewController.shared.fitYouTubeVideoToCurrentView()
                statusText = "Fit YouTube video at \(String(format: "%.2f", youtubeFitScale)) zoom"
            } label: {
                Label("Fit Video To Current View", systemImage: "rectangle.inset.filled")
            }
            .buttonStyle(.bordered)

            Button {
                CustomWebViewController.shared.scheduleYouTubeAutoFitNow()
                statusText = "Scheduled fit after \(String(format: "%.1f", youtubeAutoFitDelay))s"
            } label: {
                Label("Fit After Delay Now", systemImage: "timer")
            }
            .buttonStyle(.bordered)

            Button {
                CustomWebViewController.shared.inspectCurrentVideoOverlays { report in
                    overlayDiagnostics = report
                    statusText = "Outlined elements above the video"
                }
            } label: {
                Label("Inspect Video Overlays", systemImage: "viewfinder")
            }
            .buttonStyle(.borderedProminent)

            if !overlayDiagnostics.isEmpty {
                Text(overlayDiagnostics)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)

                Button("Clear Inspection") {
                    CustomWebViewController.shared.clearVideoOverlayInspection()
                    overlayDiagnostics = ""
                    statusText = "Cleared overlay outlines"
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var quickSelectControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Selects")
                .font(.headline)

            HStack {
                TextField("https://example.com", text: $quickSelectURL)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)

                Button {
                    addQuickSelectFromInput()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(quickSelectURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Button {
                CustomWebViewController.shared.saveCurrentURLAsQuickSelect()
                refreshQuickSelects()
                statusText = "Saved current URL as quick select"
            } label: {
                Label("Save Current URL", systemImage: "bookmark")
            }
            .buttonStyle(.bordered)

            ForEach(quickSelects) { quickSelect in
                HStack {
                    Button {
                        loadQuickSelect(quickSelect)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(quickSelect.title)
                                .font(.body)
                            Text(quickSelect.urlString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        CustomWebViewController.shared.deleteQuickSelect(quickSelect)
                        refreshQuickSelects()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var liveActivityControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Controls")
                .font(.headline)

            Button {
                startCarPlayControlsLiveActivity()
            } label: {
                Label("Start Live Controls", systemImage: "rectangle.badge.hand.point.up")
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                stopCarPlayControlsLiveActivity()
            } label: {
                Label("Stop Live Controls", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
        }
    }

    private var extraControls: some View {
        VStack(spacing: 12) {
            HStack {
                controlButton("magnifyingglass") {
                    CustomWebViewController.shared.resetZoom()
                }

                controlButton("arrow.counterclockwise.circle") {
                    CustomWebViewController.shared.reloadPage()
                }

                Button {
                    CustomWebViewController.shared.toggleCursor()
                } label: {
                    Image("Cursor")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: Size / 7)
                        .foregroundColor(buttonColour)
                }
                .buttonStyle(.plain)
            }

            Button {
                CustomWebViewController.shared.playCurrentPageVideoInCustomPlayer()
            } label: {
                Label("Try Custom Video Player", systemImage: "play.tv")
            }
            .buttonStyle(.bordered)

            Button {
                bringBrowserToCarPlay()
            } label: {
                Label("Bring Browser To CarPlay", systemImage: "car.front.waves.up")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Components

    private var selectButton: some View {
        Button(action: {
            CustomWebViewController.shared.select()
        }) {
            ZStack {
                Circle()
                    .fill(centerButtonColour)
                    .frame(width: Size / 3, height: Size / 3)
                    .shadow(color: .gray, radius: 10)
                Text("Select")
                    .foregroundColor(buttonColour)
                    .bold()
            }
        }
    }

    private func controlButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Size / 7)
                .foregroundColor(buttonColour)
        }
        .buttonStyle(.plain)
    }

    private func longPressGesture(action: @escaping () -> Void) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in action() }
    }

    private func refreshQuickSelects() {
        quickSelects = CustomWebViewController.shared.loadQuickSelects()
    }

    private func openYouTubeSignIn() {
        if browserEngine == TDSIOSBrowserEngine.minimal.rawValue {
            MinimalBrowserHost.shared.loadURL(CustomWebViewController.youtubeSignInURL)
        } else {
            CustomWebViewController.shared.loadURL(CustomWebViewController.youtubeSignInURL)
        }
    }

    private func adjustYouTubeFitScale(by amount: Double) {
        setYouTubeFitScale(youtubeFitScale + amount)
    }

    private func setYouTubeFitScale(_ scale: Double) {
        let range = CustomWebViewController.youtubeFitScaleRange
        youtubeFitScale = min(max(scale, range.lowerBound), range.upperBound)
        CustomWebViewController.shared.setYouTubeFitScale(youtubeFitScale)
        CustomWebViewController.shared.fitYouTubeVideoToCurrentView()
        statusText = "YouTube fit zoom \(String(format: "%.2f", youtubeFitScale))"
    }

    private func addQuickSelectFromInput() {
        let trimmed = quickSelectURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: normalized) else { return }

        CustomWebViewController.shared.addQuickSelect(title: url.host ?? normalized, url: url)
        quickSelectURL = ""
        refreshQuickSelects()
        loadQuickSelect(WebQuickSelect(id: UUID(), title: url.host ?? normalized, urlString: url.absoluteString))
    }

    private func loadQuickSelect(_ quickSelect: WebQuickSelect) {
        guard let url = URL(string: quickSelect.urlString) else { return }
        CustomWebViewController.shared.loadURL(url)
        TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: url))
        statusText = "Loaded \(quickSelect.title)"
    }

    private func bringBrowserToCarPlay() {
        let currentURL = CustomWebViewController.shared.webView?.url
        TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: currentURL, reloadWeb: false))
        statusText = currentURL == nil ? "Sent browser to CarPlay" : "Sent current browser page to CarPlay"
    }

    private func startCarPlayControlsLiveActivity() {
        guard #available(iOS 16.1, *) else {
            statusText = "Live Activities need iOS 16.1 or newer"
            return
        }

        do {
            try TDSCarPlayControlsLiveActivityManager.start()
            statusText = "Live controls started"
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func stopCarPlayControlsLiveActivity() {
        guard #available(iOS 16.1, *) else { return }

        Task {
            await TDSCarPlayControlsLiveActivityManager.stopAll()
            await MainActor.run {
                statusText = "Live controls stopped"
            }
        }
    }
}

#Preview {
    WebViewButtons()
}
