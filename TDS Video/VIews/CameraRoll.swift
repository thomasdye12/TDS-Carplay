//
//  CameraRoll.swift
//  TDS Video
//
//  Created by Thomas Dye on 19/03/2025.
//

import SwiftUI
import AVKit
import UniformTypeIdentifiers
import PhotosUI

struct SingleVideoPicker: View {
    @State private var isVideoPickerPresented = false
    @State private var selectedVideoURL: URL?
    @State private var isPlaying = false
    @State private var savedVideos: [URL] = []
    @State private var isPhotosPickerPresented = false
    private let videoFolder = FileManager.default.temporaryDirectory.appendingPathComponent("SavedVideos", isDirectory: true)

    var body: some View {
        VStack(spacing: 20) {
            Text("Pick a file you would like, wait while it is made available, then press the Send to car button.")
                .multilineTextAlignment(.center)

            if let videoURL = selectedVideoURL {
                let player = TDSVideoShared.shared.VideoPlayerForFile

                HStack(spacing: 30) {
                    Button(action: { skip(by: -10) }) {
                        Label("Back 10s", systemImage: "gobackward.10")
                    }

                    Button(action: {
                        if isPlaying {
                            player?.pause()
                        } else {
                            player?.play()
                        }
                        isPlaying.toggle()
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                    }

                    Button(action: { skip(by: 10) }) {
                        Label("Forward 10s", systemImage: "goforward.10")
                    }
                }

                Button("Send to car") {
                    var data = CarplayComClass(type: .video)
                    data.URL = videoURL
                    TDSVideoShared.shared.CarPlayComp?(data)
                }
                .padding(.top)
            }

            Divider()

            Text("Saved Videos")
                .font(.headline)

            List {
                ForEach(savedVideos, id: \.self) { url in
                    HStack {
                        Text(url.lastPathComponent)
                            .lineLimit(1)
                        Spacer()
//                        Button("Play") {
//                            selectedVideoURL = url
//                            TDSVideoShared.shared.VideoPlayer = AVPlayer(url: url)
//                            isPlaying = false
//                        }
//                        .padding(.horizontal)

                        Button(role: .destructive) {
                            deleteVideo(url)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .frame(height: 200)

            Button("Pick a New File") {
                isVideoPickerPresented = true
            }
            .fileImporter(
                isPresented: $isVideoPickerPresented,
                allowedContentTypes: [.movie],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let fileURL = try result.get().first else { return }

                    guard fileURL.startAccessingSecurityScopedResource() else {
                        print("Unable to access security-scoped resource.")
                        return
                    }
                    defer { fileURL.stopAccessingSecurityScopedResource() }

                    try createVideoFolderIfNeeded()

                    let destinationURL = videoFolder.appendingPathComponent(fileURL.lastPathComponent)

                    // Handle duplicates
                    var uniqueURL = destinationURL
                    var count = 1
                    while FileManager.default.fileExists(atPath: uniqueURL.path) {
                        uniqueURL = videoFolder.appendingPathComponent("\(fileURL.deletingPathExtension().lastPathComponent)-\(count).mov")
                        count += 1
                    }

                    try FileManager.default.copyItem(at: fileURL, to: uniqueURL)

                    savedVideos.append(uniqueURL)
                    selectedVideoURL = uniqueURL
                    TDSVideoShared.shared.VideoPlayer = AVPlayer(url: uniqueURL)
                    isPlaying = false

                } catch {
                    print("Error importing file: \(error.localizedDescription)")
                }
            }
            Button("Pick from Photos") {
                isPhotosPickerPresented = true
            }
            .sheet(isPresented: $isPhotosPickerPresented) {
                PhotoVideoPicker { url in
                    if let url = url {
                        handleNewVideo(url)
                    }
                }
            }
        }
        .padding()
        .onAppear(perform: loadSavedVideos)
    }

    private func skip(by seconds: Double) {
        guard let player = TDSVideoShared.shared.VideoPlayerForFile else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeGetSeconds(currentTime) + seconds
        let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: currentTime.timescale)
        player.seek(to: time)
    }

    private func createVideoFolderIfNeeded() throws {
        if !FileManager.default.fileExists(atPath: videoFolder.path) {
            try FileManager.default.createDirectory(at: videoFolder, withIntermediateDirectories: true)
        }
    }

    private func loadSavedVideos() {
        do {
            try createVideoFolderIfNeeded()
            let urls = try FileManager.default.contentsOfDirectory(at: videoFolder, includingPropertiesForKeys: nil)
            savedVideos = urls.filter { $0.pathExtension.lowercased() == "mov" }
        } catch {
            print("Error loading saved videos: \(error.localizedDescription)")
        }
    }

    private func deleteVideo(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            savedVideos.removeAll { $0 == url }
            if selectedVideoURL == url {
                selectedVideoURL = nil
                isPlaying = false
            }
        } catch {
            print("Failed to delete video: \(error.localizedDescription)")
        }
    }
    
    private func handleNewVideo(_ fileURL: URL) {
        do {
            try createVideoFolderIfNeeded()

            let destinationURL = videoFolder.appendingPathComponent(fileURL.lastPathComponent)
            var uniqueURL = destinationURL
            var count = 1
            while FileManager.default.fileExists(atPath: uniqueURL.path) {
                uniqueURL = videoFolder.appendingPathComponent("\(fileURL.deletingPathExtension().lastPathComponent)-\(count).mov")
                count += 1
            }

            try FileManager.default.copyItem(at: fileURL, to: uniqueURL)

            savedVideos.append(uniqueURL)
            selectedVideoURL = uniqueURL
            TDSVideoShared.shared.VideoPlayer = AVPlayer(url: uniqueURL)
            isPlaying = false

        } catch {
            print("Error importing file: \(error.localizedDescription)")
        }
    }

    
}


struct PhotoVideoPicker: UIViewControllerRepresentable {
    var onVideoPicked: (URL?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .videos

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onVideoPicked: onVideoPicked)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var onVideoPicked: (URL?) -> Void

        init(onVideoPicked: @escaping (URL?) -> Void) {
            self.onVideoPicked = onVideoPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
                onVideoPicked(nil)
                return
            }

            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url = url else {
                    print("Error loading video: \(error?.localizedDescription ?? "Unknown error")")
                    self.onVideoPicked(nil)
                    return
                }

                // Move the file to a temp URL to keep it
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    DispatchQueue.main.async {
                        self.onVideoPicked(tempURL)
                    }
                } catch {
                    print("Copy failed: \(error)")
                    DispatchQueue.main.async {
                        self.onVideoPicked(nil)
                    }
                }
            }
        }
    }
}
