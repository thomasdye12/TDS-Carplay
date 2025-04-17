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
        CustomWebViewController.shared.IsIncar = false
        return webViewController
    }

    func updateUIViewController(_ uiViewController: CustomWebViewController, context: Context) {}
}

struct WebViewContainer: View {
    @State private var showCarButtons = false
    @State private var showURLInput = false
    @State private var userInputURL: String = ""

    var body: some View {
        ZStack {
            WebView()
                .ignoresSafeArea()

            // You could place overlay loading UI or status feedback here
        }
        .navigationTitle("Web Browser")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    CustomWebViewController.shared.loadURL(URL(string: "https://google.com")!)
                } label: {
                    Label("Google", systemImage: "globe")
                }

                Button {
                    TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: nil))
                } label: {
                    Label("To Car", systemImage: "car.fill")
                }

                Menu {
                    Button("Control Page Buttons") {
                        showCarButtons = true
                    }
                    Button("Enter URL") {
                        showURLInput = true
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showURLInput) {
            URLInputSheet(showURLInput: $showURLInput, userInputURL: $userInputURL)
        }
        .sheet(isPresented: $showCarButtons) {
            WebViewButtons()
        }
    }
}

struct URLInputSheet: View {
    @Binding var showURLInput: Bool
    @Binding var userInputURL: String
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
                            CustomWebViewController.shared.loadURL(url)
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
                            CustomWebViewController.shared.loadURL(shared)
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
}
