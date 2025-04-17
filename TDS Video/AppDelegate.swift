//
//  AppDelegate.swift
//  TDS McdonaldsApi
//
//  Created by Thomas Dye on 02/08/2024.
//

import UIKit
import CarPlay

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var observer: NSKeyValueObservation?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    
//    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
//        print(window)
//    }

    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        print("Scene  Connected")
    }
    
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        print("Scene  Disconenced")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
            // Application entered the background
            print("The app has entered the background.")
            // Perform any background tasks or cleanup here
        }

        func applicationWillEnterForeground(_ application: UIApplication) {
            // Application will enter the foreground
            print("The app will enter the foreground.")
        }
    func applicationWillTerminate(_ application: UIApplication) {
        // Code to execute just before the app terminates
        print("App will terminate")
        ScreenCaptureManager.shared.Stop()
    }
    
    @objc private func handleSharedURL(_ notification: Notification) {
        if let urlString = notification.userInfo?["url"] as? String,
           let url = URL(string: urlString) {
            print("Received shared URL: \(url)")
            // Handle the URL in the app
        }
    }

    @objc private func handleSharedVideo(_ notification: Notification) {
        if let videoURLString = notification.userInfo?["videoURL"] as? String,
           let videoURL = URL(string: videoURLString) {
            print("Received shared video URL: \(videoURL)")
            // Handle the video in the app
        }
    }

    // Handle changes
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(keyPath)
        if keyPath == "TDVideo-SharedURL" {
            let userDefaults = UserDefaults(suiteName: "group.net.thomasdye.TDS-docs")

            if let sharedURLString = userDefaults?.string(forKey: "TDVideo-SharedURL"),
               let sharedURL = URL(string: sharedURLString) {
                
                print("Live shared URL received: \(sharedURL)")

                // Clear after retrieving
                userDefaults?.removeObject(forKey: "TDSSharedURL")
            }
        }
    }
}

