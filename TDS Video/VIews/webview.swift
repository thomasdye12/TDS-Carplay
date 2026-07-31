//
//  webview.swift
//  TDS Video
//
//  Created by Thomas Dye on 05/08/2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CustomWebViewController {
        let webViewController = CustomWebViewController.shared
        webViewController.applyIOSLayoutForBrowser()
        return webViewController
    }

    func updateUIViewController(_ uiViewController: CustomWebViewController, context: Context) {
        uiViewController.applyIOSLayoutForBrowser()
    }
}

struct WebViewContainer: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCarButtons = false
    @State private var showURLInput = false
    @State private var userInputURL: String = ""
    @State private var quickSelects: [WebQuickSelect] = CustomWebViewController.shared.loadQuickSelects()
    @AppStorage(TDSBrowserSettings.iOSBrowserEngineKey) private var browserEngine = TDSIOSBrowserEngine.standard.rawValue

    private var usesMinimalBrowser: Bool {
        browserEngine == TDSIOSBrowserEngine.minimal.rawValue
    }

    var body: some View {
        ZStack(alignment: .top) {
            if usesMinimalBrowser {
                MinimalBrowserRepresentable(initialURLString: CustomWebViewController.youtubeURL.absoluteString)
                    .ignoresSafeArea()
            } else {
                WebView()
                    .ignoresSafeArea()
            }

            // You could place overlay loading UI or status feedback here

            browserOverlayControls
                .safeAreaPadding(.top, 6)
                .padding(.horizontal, 10)
        }
        .navigationTitle(usesMinimalBrowser ? "Custom Browser" : "Web Browser")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showURLInput) {
            URLInputSheet(showURLInput: $showURLInput, userInputURL: $userInputURL)
        }
        .sheet(isPresented: $showCarButtons) {
            WebViewButtons()
        }
        .onAppear {
            quickSelects = CustomWebViewController.shared.loadQuickSelects()
        }
    }

    private var browserOverlayControls: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .browserOverlayButton()
            }
            .accessibilityLabel("Close Browser")

            Spacer()

            Button {
                loadURL(CustomWebViewController.youtubeSignInURL)
            } label: {
                Image(systemName: "person.crop.circle")
                    .browserOverlayButton()
            }
            .accessibilityLabel("YouTube Sign In")

            Button {
                TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: nil))
            } label: {
                Image(systemName: "car.fill")
                    .browserOverlayButton()
            }
            .accessibilityLabel("Send Browser to CarPlay")

            browserMenu
        }
    }

    private var browserMenu: some View {
        Menu {
            Button("YouTube Sign In / Switch Account", systemImage: "person.crop.circle") {
                loadURL(CustomWebViewController.youtubeSignInURL)
            }

            Button("Google", systemImage: "globe") {
                loadURL(URL(string: "https://google.com")!)
            }

            ForEach(quickSelects) { quickSelect in
                Button(quickSelect.title) {
                    if let url = URL(string: quickSelect.urlString) {
                        loadURL(url)
                        TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: url))
                    }
                }
            }

            Divider()

            Button("Save Current URL") {
                CustomWebViewController.shared.saveCurrentURLAsQuickSelect()
                quickSelects = CustomWebViewController.shared.loadQuickSelects()
            }

            if usesMinimalBrowser {
                Button("Back") {
                    MinimalBrowserHost.shared.goBack()
                }
                Button("Forward") {
                    MinimalBrowserHost.shared.goForward()
                }
                Button("Reload") {
                    MinimalBrowserHost.shared.reload()
                }
            }

            Button("Control Page Buttons") {
                showCarButtons = true
            }
            Button("Enter URL") {
                showURLInput = true
            }
        } label: {
            Image(systemName: "ellipsis")
                .browserOverlayButton()
        }
        .accessibilityLabel("Browser Menu")
    }

    private func loadURL(_ url: URL) {
        if usesMinimalBrowser {
            MinimalBrowserHost.shared.loadURL(url)
        } else {
            CustomWebViewController.shared.loadURL(url)
        }
    }
}

private extension View {
    func browserOverlayButton() -> some View {
        self
            .font(.title3.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(Color.black.opacity(0.72), in: Circle())
    }
}

struct URLInputSheet: View {
    @Binding var showURLInput: Bool
    @Binding var userInputURL: String
    @AppStorage(TDSBrowserSettings.iOSBrowserEngineKey) private var browserEngine = TDSIOSBrowserEngine.standard.rawValue
    @FocusState private var urlFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Custom URL")) {
                    TextField("Enter full URL (https://...)", text: $userInputURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textFieldStyle(.roundedBorder)
                        .focused($urlFieldFocused)

                    Button("Load URL") {
                        if let url = URL(string: userInputURL.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            loadURL(url)
                            showURLInput = false
                        } else {
                            print("Invalid URL")
                        }
                    }
                    .disabled(userInputURL.isEmpty)
                }

                Section(header: Text("Shared URL")) {
                    if let shared = loadSharedURL() {
                        Button("Load Shared URL: \(shared.absoluteString)") {
                            loadURL(shared)
                            showURLInput = false
                        }
                    } else {
                        Text("No shared URL available")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Cancel", role: .cancel) {
                        showURLInput = false
                    }
                }
            }
            .navigationTitle("Enter Web URL")
            .onAppear {
                urlFieldFocused = true
            }
        }
    }

    func loadSharedURL() -> URL? {
        TDSVideoShared.shared.loadSharedURL()
    }

    private func loadURL(_ url: URL) {
        if browserEngine == TDSIOSBrowserEngine.minimal.rawValue {
            MinimalBrowserHost.shared.loadURL(url)
        } else {
            CustomWebViewController.shared.loadURL(url)
        }
    }
}
