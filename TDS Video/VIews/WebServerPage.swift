//
//  WebServerPage.swift
//  TDS Video
//
//  Created by Thomas Dye on 16/04/2025.
//

import SwiftUI

struct WebServerPage: View {
    @State private var ipAddresses: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Live View Available")
                .font(.title)
                .bold()

            Text("While screen recording is active, you can view this device from another device on the same network by opening the following address in a web browser:")
            Text("This is a work in progress, so please be patient, some features may not work yet. I have added this at request to support cars like Tesla where CarPlay is not available.")
                .font(.caption)
            Text("if you like this, please let me know and I will work on improving the functionality")
                .font(.caption)
            Text("No sound is handled!")
            Divider()
            Text("IP address to connect to the screen")
            ForEach(ipAddresses, id: \.self) { ip in
                Text("http://\(ip):8080")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                
            }

            Spacer()
        }
        .padding()
        .onAppear {
            self.ipAddresses = HTTPServer.shared.getAllIPAddresses().map {
                $0.components(separatedBy: ": ").last ?? $0
            }
        }
    }
}
