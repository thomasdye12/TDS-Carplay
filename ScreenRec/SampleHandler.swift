//
//  SampleHandler.swift
//  ScreenRec
//
//  Created by Thomas Dye on 11/01/2025.
//

import ReplayKit
import Network
import VideoToolbox
//import Transcoding

import ReplayKit
import Network
import VideoToolbox
import AVFoundation

class SampleHandler: RPBroadcastSampleHandler {

    // MARK: - Network Connection to Main App
    public var connection: NWConnection?
    private let host = NWEndpoint.Host("127.0.0.1")
    private let port = NWEndpoint.Port(integerLiteral: 12345)
    

    let videoEncoderAnnexBAdaptor = VideoEncoderAnnexBAdaptor(
        videoEncoder: VideoEncoder(config: .ultraLowLatency)
    )
    
    // MARK: - Broadcast Lifecycle
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        print("broadcast started")
        // Optionally, create/Configure compression session if needed:
        // createCompressionSession(width: 720, height: 1280)
        
        // Establish the connection and start listening for Annex B data
        connect()
    }

    override func broadcastFinished() {
        print("broadcast finished")
        

        
        // Cancel the network connection
        connection?.cancel()
    }
    
    /// Sets up the NWConnection and handles automatic reconnect
    private func connect() {
        HTTPServer.shared.Start()
        videoEncoderAnnexBAdaptor.videoEncoder.invalidate()
        // Create a new NWConnection
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        // Monitor connection state
        connection?.stateUpdateHandler = { [weak self] newState in
            guard let self = self else { return }
            switch newState {
            case .ready:
                print("Connection is ready")
                self.receiveMessage()
            case .failed(let error):
                print("Connection failed with error: \(error.localizedDescription)")
                self.handleConnectionError()
            case .waiting(let error):
                // .waiting often indicates network issues or transition; you can decide to retry here too.
                print("Connection is waiting with error: \(error.localizedDescription)")
                self.handleConnectionError()
            case .cancelled:
                print("Connection cancelled")
            default:
                break
            }
        }

        // Start the connection
        connection?.start(queue: .global(qos: .background))
        
        // Create a Task that sends data from the annexBData AsyncSequence
        Task {
            for await data in videoEncoderAnnexBAdaptor.annexBData {
                print("Sending \(data.count) bytes")
                connection?.send(content: data, completion: .contentProcessed({ error in
                    if let error = error {
                        print("Send error:", error)
                    }
                }))
            }
        }
    }
    
    private func receiveMessage() {
            guard let connection = connection else { return }

            connection.receive(minimumIncompleteLength: 2, maximumLength: 2048) { data, context, isComplete, error in
                if let data = data, !data.isEmpty {
                    let message = String(data: data, encoding: .utf8) ?? "Unknown"
                    
                    print("Received message: \(message)")
                    if message == "RECONNECT" {
                        self.videoEncoderAnnexBAdaptor.videoEncoder.invalidate()
                    }
                    if message == "STOP" {
                        let error = NSError(
                            domain: "com.example.broadcast",
                            code: 1001,
                            userInfo: [NSLocalizedDescriptionKey: "STOPPED FROM APP"]
                        )
                        self.finishBroadcastWithError(error)
                    }
                    
                    
                } else if let error = error {
                    print("Error receiving message: \(error)")
                }

                // Call receiveMessage() again to keep receiving data
                if isComplete == false {
                    self.receiveMessage()
                }
            }
        }
    /// Handle connection errors by cancelling and attempting to reconnect
    private func handleConnectionError() {
        connection?.cancel()
        connection = nil
        
        // Simple retry after 2 seconds
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) { [weak self] in
            print("Attempting to reconnect…")
            self?.connect()
        }
    }

    /// Called for each incoming video/audio sample from the entire device screen
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer,
                                      with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            // Encode the video frame to H.264
            videoEncoderAnnexBAdaptor.videoEncoder.encode(sampleBuffer)
            if HTTPServer.shared.isRunning {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                   let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                   let context = CIContext()
                   
                   if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                       HTTPServer.shared.send(image: cgImage)
                   }
            }
           
            
        case .audioApp, .audioMic:
            // Handle audio encoding here if desired
            break
        @unknown default:
            break
        }
    }
}
