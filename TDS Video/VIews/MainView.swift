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
//    @State private var authStatus = CLLocationManager.authorizationStatus()
    @ObservedObject var videoAPI = TDSVideoAPI.shared
    @State private var showingCodeAlert = false
    @State private var connectionCode = ""
    @State private var showRebootAlert = false
    @State var isStationary = false
    @StateObject private var locationAPI = TDSLocationAPI.shared
    var body: some View {
        NavigationStack {
            List {
//                location access
//                Section(header: Text("Safety")) {
//                     // 1) Permission flow
//                     switch authStatus {
//                     case .notDetermined:
//                         Button("Allow Location Access") {
//                             locationAPI.requestLocationPermission()
//                         }
//                         
//                     case .restricted, .denied:
//                         Text("Location access denied. Please enable in Settings.")
//                             .foregroundColor(.red)
//                         
//                     case .authorizedWhenInUse, .authorizedAlways:
//                         // 2) Permission ok, so we can check stationary
//                         Button(action: {
//                             locationAPI.startUpdatingLocation()
//                         }) {
//                             HStack {
//                                 Image(systemName: locationAPI.isStationary ? "checkmark.circle" : "location")
//                                 Text(locationAPI.isStationary ? "Stationary ✓" : "Check Stationary Status")
//                             }
//                         }
//                         .disabled(locationAPI.isStationary)    // once stationary, you can’t press again
//
//                         // 3) Status text
//                         Text(locationAPI.isStationary
//                              ? "You’re stationary. Safety Mode enabled."
//                              : "Remain still to enable Safety Mode.")
//                             .font(.subheadline)
//                             .foregroundColor(.secondary)
//
//                     @unknown default:
//                         Text("Unknown authorization status.")
//                     }
//                 }
                
                
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
//                .disabled(!locationAPI.isStationary)

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
            // keep authStatus up to date when app comes back to foreground
//                   .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
//                       authStatus = CLLocationManager.authorizationStatus()
//                   }
                   .toolbar {
                       ToolbarItem(placement: .navigationBarLeading) {
                           Button("Enter Code") {
                               showingCodeAlert = true
                           }
                       }
                   }
                   .alert("Enter Connection Code", isPresented: $showingCodeAlert, actions: {
                       TextField("Connection Code", text: $connectionCode)
                       Button("OK") {
                           if connectionCode.lowercased() == "carplay" {
                               // Trigger reboot instruction
                               TDSCarplayAccess.shared.DisableIsStationary = true
                               showRebootAlert = true
                           }
                           connectionCode = ""
                       }
                       Button("Cancel", role: .cancel) {
                           connectionCode = ""
                       }
                   }, message: {
                       Text("Enter the connection code to proceed.")
                   })
                   .alert("Reboot Required", isPresented: $showRebootAlert) {
                       Button("OK", role: .cancel) {}
                   } message: {
                       Text("CarPlay mode is now enabled. Please close and reopen the app for changes to take effect.")
                   }
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
        openURL("https://github.com/thomasdye12/TDS-Carplay")
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
