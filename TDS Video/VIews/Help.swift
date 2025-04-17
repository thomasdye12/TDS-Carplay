//
//  Help.swift
//  TDS Video
//
//  Created by Thomas Dye on 19/03/2025.
//

import SwiftUI

struct Help: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("📺 Screen Recording Setup")
                        .font(.headline)
                    
                    Text("""
1. Open the app.
2. Start screen recording using the app extension:
   - Open Control Centre.
   - Long-press the screen recording button.
   - Select **TDS Video** from the dropdown.
3. This screen recording will begin streaming.
4. Open the client app to view the stream.
""")

                    Text("❗️ If the TDS Video extension doesn't appear, the system may not have updated the list of available apps. Try waiting a few moments or restarting your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                Group {
                    Text("🌐 Web Page Streaming")
                        .font(.headline)

                    Text("""
1. Open the Web View screen.
2. Press **Reload** to enter a URL (e.g., `home` for Google).
3. Tap **Car Load** to stream the web content to the car display.
4. Leave the web view, then press **Load Web View** to restore the view.
5. Use the **WebView Buttons** screen to adjust or control the page.
""")

                    Text("Tip: For left-handed cars, a toggle is available in settings to adjust the screen layout.")
                }

                Divider()

                Group {
                    Text("⚠️ Dealing with Lag")
                        .font(.headline)

                    Text("""
Occasional lag can occur. If you experience issues:
- Close both apps completely.
- Reopen and retry the screen recording process.
""")
                }

                Divider()

                Group {
                    Text("ℹ️ Other Info")
                        .font(.headline)

                    Text("""
**Why no AirPlay?**
Audio routing to CarPlay through AirPlay is not currently possible due to system limitations. Implementing this would cause audio to be rerouted through AirPlay, not the car.
""")
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Help")
    }
}
