//
//  ScreenMirroingSettings.swift
//  TDS Video
//
//  Created by Thomas Dye on 20/03/2025.
//

import SwiftUI

struct ScreenMirroingSettings: View {
    
    @ObservedObject var videoAPI = ScreenCaptureManager.shared
    @AppStorage("CarIsRightHanded") private var carIsRightHanded: Bool = false
    
    var body: some View {
        Form {
            Section(header: Label("Orientation", systemImage: "rectangle.rotate")) {
                Picker("Screen Mirroring Orientation", selection: $videoAPI.selectedOrientation) {
                    ForEach(ScreenOrientation.allCases, id: \.self) { orientation in
                        Text(orientation.humanReadable())
                            .tag(orientation)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(header: Label("Aspect Ratio", systemImage: "aspectratio")) {
                Picker("Aspect Ratio", selection: $videoAPI.selectedAspectRatio) {
                    ForEach(AspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.humanReadableName())
                            .tag(ratio)
                    }
                }
                .pickerStyle(.menu)

                Text("Choose the display aspect ratio best suited to your vehicle screen.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Label("Screen Offset", systemImage: "arrow.left.and.right")) {
                Picker("Offset Side", selection: Binding(
                    get: { OffsetOption.from(offset: videoAPI.Screenoffset) },
                    set: {
                        videoAPI.Screenoffset = $0.offset
                        ScreenCaptureManager.shared.CarPlaysideofcarchange?($0.offset)
                    }
                )) {
                    ForEach(OffsetOption.allCases) { option in
                        Text(option.displayName)
                            .tag(option)
                    }
                }
                .pickerStyle(.menu)

                Text("Current Offset: \(videoAPI.Screenoffset.rawValue)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

//            Section(header: Label("Car Configuration", systemImage: "car")) {
//                Toggle("Right-Hand Drive Car", isOn: $carIsRightHanded)
//                
//                Text("Toggle this if your car is right-hand drive. This adjusts screen layout and controls accordingly.")
//                    .font(.caption2)
//                    .foregroundColor(.secondary)
//            }
        }
        .navigationTitle("Mirroring Settings")
    }
}
