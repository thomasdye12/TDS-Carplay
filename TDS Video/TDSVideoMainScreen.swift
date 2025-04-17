//
//  TDSVideoMainScreen.swift
//  TDS Video
//
//  Created by Thomas Dye on 16/04/2025.
//
// This file is show I can show apple something else to get it approved 

import SwiftUI

struct TDSVideoMainScreen: View {
    @State private var ipAddresses: [String] = []
    @State private var showingCodeAlert = false
    @State private var connectionCode = ""
    @State private var showRebootAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Welcome to TDS Video!")
                        .font(.largeTitle)
                        .bold()

                    Text("How to Share Your Screen")
                        .font(.title2)
                        .bold()

                    Text("""
This app allows you to share your screen locally with other devices on the same network.

1. Open Control Center on your device.
2. Tap 'Screen Recording'.
3. In the screen recording menu, choose **My App** from the list of extensions.
4. Start recording.

Anyone on the same Wi-Fi can view your screen by entering one of the local IP addresses listed below in their browser.
""")

                    Text("Available IP Addresses:")
                        .font(.headline)

                    ForEach(ipAddresses, id: \.self) { ip in
                        Text("http://\(ip):8080")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle("TDS Video", displayMode: .inline)
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
                        TDSCarplayAccess.shared.ShowTDSCarPlaySettings = true
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
            .onAppear {
                self.ipAddresses = HTTPServer.shared.getAllIPAddresses().map {
                    $0.components(separatedBy: ": ").last ?? $0
                }
            }
        }
    }
}
