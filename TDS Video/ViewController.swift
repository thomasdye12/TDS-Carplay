//
//  ViewController.swift
//  TDS McdonaldsApi
//
//  Created by Thomas Dye on 02/08/2024.
//

import UIKit
import SwiftUI

import Network
import ReplayKit
import AVFoundation




class ViewController: UIViewController {
   
    override func viewDidLoad() {
        self.view.backgroundColor = .black
        
        Task {
            
            if TDSCarplayAccess.shared.ShowTDSCarPlaySettings == false  {
                
                
                let hostingController = UIHostingController(rootView: TDSVideoMainScreen())
                self.addChild(hostingController)
                self.view.addSubview(hostingController.view)
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostingController.view.leadingAnchor.constraint(equalTo:  self.view.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo:  self.view.trailingAnchor),
                    hostingController.view.topAnchor.constraint(equalTo:  self.view.topAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo:  self.view.bottomAnchor)
                ])
                hostingController.didMove(toParent: self)
                
                return
            }
            
            ScreenCaptureManager.shared.start()
    //        auth.APNSObject.RequestAPNS()

            print(UserDefaults.standard.bool(forKey: "CarIsRightHanded"))
            let tempDirectory = FileManager.default.temporaryDirectory
            TDSVideoAPI.shared.deleteOldFiles(from: tempDirectory, olderThan: 4)
            
//            TDSLocationAPI.shared.requestLocationPermission()
            DispatchQueue.global(qos: .background).async {
//                TDSLocationAPI.shared.startUpdatingLocation()
            }
            
          

            
            let hostingController = UIHostingController(rootView: MainView())
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo:  self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo:  self.view.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo:  self.view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo:  self.view.bottomAnchor)
            ])
            hostingController.didMove(toParent: self)
            await TDSVideoAPI.shared.DeviceBooted(VC: self)
        }
      
//        auth.Request_AccountCreate(viewController: self, comp: {res in
//            
//            
//        })
  
    }

    


//        private func configureCaptureSession() {
//            // 1. Set session preset (e.g., high resolution)
//            captureSession.sessionPreset = .high
//
//            // 2. Select default video device
//            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
//                                                            for: .video,
//                                                            position: .back) else {
//                print("Unable to access back camera!")
//                return
//            }
//
//            // 3. Create input
//            do {
//                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
//                if captureSession.canAddInput(videoDeviceInput) {
//                    captureSession.addInput(videoDeviceInput)
//                }
//            } catch {
//                print("Error creating video device input: \(error.localizedDescription)")
//                return
//            }
//
//            // 4. Configure output
//            videoOutput.videoSettings = [
//                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
//            ]
//            videoOutput.alwaysDiscardsLateVideoFrames = true
//
//            // 5. Set queue & delegate
//            let videoQueue = DispatchQueue(label: "camera.video.queue")
//            videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
//
//            // 6. Add output
//            if captureSession.canAddOutput(videoOutput) {
//                captureSession.addOutput(videoOutput)
//            }
//
//            // (Optional) Adjust orientation if needed
//            guard let connection = videoOutput.connection(with: .video),
//                  connection.isVideoOrientationSupported else {
//                return
//            }
//            connection.videoOrientation = .portrait
//        }

}


//extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//    func captureOutput(_ output: AVCaptureOutput,
//                       didOutput sampleBuffer: CMSampleBuffer,
//                       from connection: AVCaptureConnection) {
//        self.captureOutput(sampleBuffer: sampleBuffer)
//    }
//}
func saveImageToDocumentsDirectory(image: UIImage) -> URL? {
    // Get the document directory URL
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("Error: Could not access document directory.")
        return nil
    }
    
    // Format the current date to create a unique file name
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let fileName = dateFormatter.string(from: Date()) + ".png"
    
    // Create the file URL
    let fileURL = documentsDirectory.appendingPathComponent(fileName)
    
    // Convert the UIImage to PNG data
    guard let imageData = image.pngData() else {
        print("Error: Could not convert image to PNG data.")
        return nil
    }
    
    // Write the data to the file
    do {
        try imageData.write(to: fileURL)
        print("Image saved successfully to \(fileURL)")
        return fileURL
    } catch {
        print("Error saving image: \(error)")
        return nil
    }
}
