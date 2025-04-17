//
//  MDapiClass.swift
//  TDS McdonaldsApi
//
//  Created by Thomas Dye on 02/08/2024.
//

import Foundation
import UIKit
import ObjectiveC.runtime
import AVKit

struct  CarplayComClass {
    var type:typeview
    var URL:URL?
    var AVplayer:AVPlayer?
    var reloadWeb:Bool?
//    var
    
    
    
    enum typeview: String, Codable {
        case video = "video"
        case web = "web"
        case IOSAPP = "IOSAPP"
        case rawVideo = "rawVideo"
        
    }
}


@objc class TDSVideoShared: NSObject {
    @objc static let shared = TDSVideoShared()
    var CarPlayComp: ((CarplayComClass) -> Void)?
    
//    var URL:URL?
    var VideoPlayer:AVPlayer?
    var VideoPlayerForFile:AVPlayer?
    var VideoPlayerView:AVPlayerViewController?
    var window:UIWindow?
    var playerLayer: AVPlayerLayer!
    
    @objc func setPlayer(_ player: AVPlayerViewController) {
//          self.VideoPlayer = player
        self.VideoPlayerView = player
        
        player.player?.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            player.player?.pause()
        })
        
        guard let playerView = player.view else {
                  return
              }
//        print(player.player?.currentItem?.asset.url)

              // Find the AVPlayerLayer
              if let sublayers = playerView.layer.sublayers {
                  for layer in sublayers {
                      if let playerLayer = layer as? AVPlayerLayer {
                          self.playerLayer = playerLayer
                          break
                      }
                  }
              }
        
//        player.view.removeFromSuperview()
        let newPlayerView = UIView(frame: self.window!.frame)
        newPlayerView.backgroundColor = .black

               // Add the new UIView to your view hierarchy
        self.window!.addSubview(newPlayerView)

               // Set the frame of the AVPlayerLayer and add it to the new UIView
               playerLayer.frame = newPlayerView.bounds
               newPlayerView.layer.addSublayer(playerLayer)

//               // Play the video
//               player.play()
        
        
        
//        self.CarPlayComp?(CarplayComClass(type: .rawVideo, URL: nil, AVplayer: player))
      }
    
    func loadSharedURL() -> URL? {
        let userDefaults = UserDefaults(suiteName: "group.net.thomasdye.TDS-docs")
        if let urlString = userDefaults?.string(forKey: "TDSSharedURL") {
            return URL(string: urlString)
        }
        return nil
    }

    // TDSSharedVideo

    func loadSharedURLVideo() -> String? {
        let userDefaults = UserDefaults(suiteName: "group.net.thomasdye.TDS-docs")
        if let urlString = userDefaults?.string(forKey: "TDSSharedVideo") {
            return urlString
        }
        return nil
    }
    
    @objc  func SHowCustomONscreenPlayer(_ player:AVPlayer){
        print("here")
    }
    
 
    
    
    
}





class ErrorHandling:NSObject {
    static let Shared = ErrorHandling()
    
    var MainVC:UIViewController?
    
    func showError(_ error:Error) {
        // Create an instance of UIAlertController
        let alert = UIAlertController(title: "There was an issue", message:"\(error)", preferredStyle: .alert)
        
        // Optionally you can add more actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel button tapped")
        }
        alert.addAction(cancelAction)

        DispatchQueue.main.async {
            self.MainVC?.present(alert, animated: true, completion: nil)
        }
    }
    
    func showError(_ error:String) {
        // Create an instance of UIAlertController
        let alert = UIAlertController(title: "There was an issue", message:"\(error)", preferredStyle: .alert)

        
        // Optionally you can add more actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Cancel button tapped")
        }
        alert.addAction(cancelAction)
        DispatchQueue.main.async {
            self.MainVC?.present(alert, animated: true, completion: nil)
        }
        // Present the alert
     
    }
}




class ManagmentURLS {
    static let shared = ManagmentURLS()
    func fetchOrders() -> URL {
        return URL(string: "https://api.thomasdye.net/app/ThomasRandom/mcdonalds/backend/V1/Api/getOrders")!
    }
//     updload token mcdonalds/backend/V1/Api/ "uploadAccessToken"
    
    func UploadToken(_ token:String) -> URL {
        return URL(string: "https://api.thomasdye.net/app/ThomasRandom/mcdonalds/backend/V1/Api/\(token)")!
    }
}


