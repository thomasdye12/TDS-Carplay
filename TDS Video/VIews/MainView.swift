//
//  MainView.swift
//  TDS McdonaldsApi
//
//  Created by Thomas Dye on 02/08/2024.
//

import SwiftUI
import ReplayKit

struct MainView: View {
    @State private var accessToken: String = ""
    @ObservedObject var videoAPI = TDSVideoAPI.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Getting Started")) {
                    NavigationLink(destination: Help()) {
                        Label("Help", systemImage: "questionmark.circle")
                    }

                    Button(action: openYouTubeHelp) {
                        Label("Watch Help Video", systemImage: "play.rectangle.fill")
                            .foregroundColor(.blue)
                            .bold()
                    }
                }

                Section(header: Text("Screen Mirroring & Web")) {
                    NavigationLink(destination: ScreenMirroingSettings()) {
                        Label("Screen Mirroring Settings", systemImage: "rectangle.on.rectangle")
                    }
                    NavigationLink(destination: ScreenMirroringView()) {
                        Label("View Screen Mirroring", systemImage: "rectangle.on.rectangle")
                    }

                    NavigationLink(destination: WebViewContainer()) {
                        Label("Open Web Browser", systemImage: "safari")
                    }
                    NavigationLink(destination: WebServerPage()) {
                        Label("HTTP server", systemImage: "safari")
                    }

//                    NavigationLink(destination: WebViewContainer2()) {
//                        Label("DRM Web Content", systemImage: "lock.shield")
//                    }

                    Button(action: {
                        TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: nil))
                    }) {
                        Label("Load Web in Car", systemImage: "car.fill")
                    }

                    NavigationLink(destination: WebViewButtons()) {
                        Label("Web Control Buttons", systemImage: "cursorarrow.rays")
                    }

                    NavigationLink(destination: SingleVideoPicker()) {
                        Label("Stream Video Files", systemImage: "film.stack")
                    }
                }

                Section(footer:
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I hope you are enjoying this app! Consider supporting future development.")
                            .font(.caption)

                        Button(action: openCoffeeDonation) {
                            Label("Buy me a coffee", systemImage: "cup.and.saucer.fill")
                                .foregroundColor(.orange)
                        }

                        Button(action: openGitHubRepo) {
                            Label("GitHub: Feature & Bug Reports", systemImage: "chevron.left.forwardslash.chevron.right")
                                .foregroundColor(.purple)
                        }

                        Text("© 2025 Thomas Dye. All rights reserved.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 6)
                    }
                    .padding(.vertical, 4)
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("TDS CarPlay Tools")
        }
    }

    // MARK: - Actions

    func openYouTubeHelp() {
        openURL("https://youtu.be/gI3Tj2KP290")
    }

    func openCoffeeDonation() {
        openURL("https://buymeacoffee.com/Thomadye")
    }

    func openGitHubRepo() {
        openURL("https://github.com/thomasdye12/TDS-Carplay/tree/main")
    }

    func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}


#Preview {
    MainView()
}
