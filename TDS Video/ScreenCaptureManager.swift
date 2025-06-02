//
//  ScreenCaptureManager.swift
//  TDS Video
//
//  Created by Thomas Dye on 11/01/2025.
//
import UIKit
import AVFoundation
import ReplayKit
import Network

struct ScreenCaptureManagerImageViews {
    var imageview:UIImageView
    var imageorientation: UIImage.Orientation
    
}

class ScreenCaptureManager: NSObject,ObservableObject {
    
    private var listener: NWListener?
    private var connection: NWConnection?
    
    var IncomingVideoDetected: Bool = false
    var CarPlaysideofcarchange: ((SingleEdgeOffset) -> Void)?
//    var IncomingVideoDetectedComp: (() -> Void)?
  
    static let shared = ScreenCaptureManager()
    var ImageViews: [ScreenCaptureManagerImageViews] = []
    // The decoder that will handle incoming H.264 or HEVC frames.
    let videoDecoderAnnexBAdaptor = VideoDecoderAnnexBAdaptor(
        videoDecoder: VideoDecoder(config: .init(realTime: true)),
        codec: .hevc
    )
    
    override init() {
      
        selectedOrientation = ScreenOrientation(rawValue: UserDefaults.standard.integer(forKey: "selectedOrientation")) ?? .left
        selectedAspectRatio = AspectRatio(rawValue: UserDefaults.standard.integer(forKey: "SelectedAspectRatio")) ?? .scaleAspectFit
        if let saved = UserDefaults.standard.string(forKey: "OffsetPreference"),
           let restoredOffset = SingleEdgeOffset(rawValue: saved) {
            // use restoredOffset
            Screenoffset = restoredOffset
        }
       
        
    }
    


    @Published var selectedOrientation: ScreenOrientation = .left  {
        didSet {
            UserDefaults.standard.set(selectedOrientation.rawValue, forKey: "selectedOrientation")
            ScreenCaptureManager.shared.UpdateOrientation(selectedOrientation)
        }
    }
    
    @Published var selectedAspectRatio: AspectRatio = .scaleAspectFit  {
        didSet {
            UserDefaults.standard.set(selectedAspectRatio.rawValue, forKey: "SelectedAspectRatio")
            ScreenCaptureManager.shared.UpdateAspectRatio(selectedAspectRatio)
        }
    }
    
    @Published   var Screenoffset: SingleEdgeOffset = .left(40) {
        didSet {
            UserDefaults.standard.set(Screenoffset.rawValue, forKey: "OffsetPreference")
            ScreenCaptureManager.shared.CarPlaysideofcarchange?(Screenoffset)
        }
    }
    
    private let ciContext = CIContext()
    
    // MARK: - Public Interface
    
    func start() {
        startLocalServer()
        // Not used in your snippet, but you can initialize
        // or configure anything you need here.
        
        videoDecoderAnnexBAdaptor.videoDecoder.ErrorFrameHandler = { error in
            print("handle that error here")
            self.Reconnect()
           
        }
        Task {
            for await decodedSampleBuffer in videoDecoderAnnexBAdaptor.videoDecoder.decodedSampleBuffers {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(decodedSampleBuffer) else { continue }
                
                // Convert CVPixelBuffer -> UIImage
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                guard let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) else { continue }
              
                
     
                // Invoke callback on the main thread
//                DispatchQueue.main.async {
//                    complete(uiImage)
//                    // e.g. imageView.image = uiImage
//                }
                if !self.IncomingVideoDetected  {
                    TDSVideoShared.shared.CarPlayComp?(.init(type: .IOSAPP))
                    self.IncomingVideoDetected = true
                }
                if TDSVideoAPI.shared.showPayment == true {
                    
                } else {
                    DispatchQueue.main.async {
                        for ImageView in self.ImageViews {
                            let uiImage = UIImage(cgImage: cgImage, scale: 1, orientation: ImageView.imageorientation)
                            ImageView.imageview.image = uiImage
                        }
                    }
                    if HTTPServer.shared.isRunning {
                        HTTPServer.shared.send(image: cgImage)
                    }
                }
            }
        }
    }
    
   
    
    
    
    func addImageView(imageView: UIImageView,orientation: UIImage.Orientation = .up) {
        self.ImageViews.append(.init(imageview: imageView, imageorientation: orientation))
    }
    
    func InBackground(){
        
    }
    func InForeground(){
//        videoDecoderAnnexBAdaptor.videoDecoder.invalidate()
        self.Reconnect()
    }
    
    func showPopup(VC: UIViewController,
                   imageView: UIImageView,
                   complete: @escaping (UIImage) -> Void) {
        
        self.ImageViews.append(.init(imageview: imageView, imageorientation: .up))
        // 1) Start listening for incoming connections from the broadcast extension

        
        // 2) Continuously handle decoded frames in an async context
   
        
        // 3) Present the Broadcast Activity VC so the user can start the screen broadcast
        RPBroadcastActivityViewController.load { broadcastAVC, error in
            guard let broadcastAVC = broadcastAVC else {
                print("Error loading Broadcast Activity View Controller: \(String(describing: error))")
                return
            }
            
            broadcastAVC.delegate = self
            broadcastAVC.modalPresentationStyle = .popover
            VC.present(broadcastAVC, animated: true, completion: nil)
        }
    }
    
    func UpdateOrientation(_ orientation: ScreenOrientation){
        for (index,imageView) in self.ImageViews.enumerated() {
            self.ImageViews[index].imageorientation = .init(rawValue: orientation.rawValue) ?? .left
        }
    }
    func UpdateAspectRatio(_ orientation: AspectRatio){
        for (index,imageView) in self.ImageViews.enumerated() {
            self.ImageViews[index].imageview.contentMode = .init(rawValue: orientation.rawValue) ?? .scaleAspectFill
        }
    }
    
    // MARK: - NWListener & NWConnection
    
    /// Sets up a TCP listener on port 12345
    func startLocalServer() {
        do {
            listener = try NWListener(using: .tcp, on: 12345)
        } catch {
            print("Failed to create listener:", error)
            return
        }
        
        // Whenever a new client (the broadcast extension) connects, we handle it here
        listener?.newConnectionHandler = { [weak self] newConnection in
            guard let self = self else { return }
           
            // If you only want one active connection at a time,
            // you can cancel the old one:
            if let existingConnection = self.connection {
//                videoDecoderAnnexBAdaptor.videoDecoder.invalidate()
                existingConnection.cancel()
            }
            
            self.connection = newConnection
            
            // Observe the connection state so we can detect failures, closures, etc.
            newConnection.stateUpdateHandler = { [weak self] newState in
                guard let self = self else { return }
                switch newState {
                case .ready:
                    print("Server-side: Connection is ready: \(newConnection.endpoint)")
                case .failed(let error):
                    print("Server-side: Connection failed: \(error)")
                    newConnection.cancel()
                    // The listener is still active, so the extension can reconnect.
                case .waiting(let error):
                    print("Server-side: Connection waiting: \(error)")
                case .cancelled:
                    print("Server-side: Connection cancelled.")
                default:
                    break
                }
            }
            
            // Start the connection and begin receiving frames
            newConnection.start(queue: .global(qos: .background))
            self.receiveFrames(on: newConnection)
        }
        
        // Start listening in the background
        listener?.start(queue: .global(qos: .background))
        print("Listening on port 12345")
    }
    
    /// Recursively receives incoming data from the client (broadcast extension).
    private func receiveFrames(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { [weak self] data, _, isEOF, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                // Pass raw AnnexB bytes into your decoder
                self.videoDecoderAnnexBAdaptor.decode(data)
                // Call receiveFrames again to keep receiving continuously
                self.receiveFrames(on: connection)
            } else if isEOF {
                // The client closed the connection
                print("Connection closed by client.")
            } else if let error = error {
                print("Server-side: Receive error: \(error)")
            }
        }
    }
    
    // MARK: - (Unused in snippet)
    
    func captureOutput(sampleBuffer: CMSampleBuffer) {
        // Provided in your snippet but not used here
    }
    
    func Reconnect(){
        let data = "RECONNECT".data(using: .utf8) ?? Data()
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                print("Message sent successfully.")
            }})
    }
    func Stop(){
        let data = "STOP".data(using: .utf8) ?? Data()
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                print("Message sent successfully.")
            }})
    }
}



extension ScreenCaptureManager: RPBroadcastActivityViewControllerDelegate {
    func broadcastActivityViewController(_ broadcastActivityViewController: RPBroadcastActivityViewController,
                                         didFinishWith broadcastController: RPBroadcastController?,
                                         error: Error?) {
        guard error == nil else {
            print("Broadcast Activity VC error: \(error!)")
            return
        }
        
        broadcastActivityViewController.dismiss(animated: true) {
            guard let broadcastController = broadcastController else { return }
            
            // Now you can start the actual broadcast
            broadcastController.startBroadcast { [weak self] error in
                if let error = error {
                    print("Could not start broadcast: \(error)")
                } else {
                    print("Broadcast started successfully!")
                    
                 
                }
            }
        }
    }
}


extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
    
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
