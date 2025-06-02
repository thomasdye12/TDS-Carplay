//
//  SceneDelegate.swift
//  TDS McdonaldsApi
//
//  Created by Thomas Dye on 02/08/2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }


    
    func sceneDidEnterBackground(_ scene: UIScene) {
           // Scene entered the background
           print("The scene has entered the background.")
           // Save data or release resources here
        ScreenCaptureManager.shared.InBackground()
       }

       func sceneWillEnterForeground(_ scene: UIScene) {
           // Scene will enter the foreground
           print("The scene will enter the foreground.")
       }

       func sceneDidBecomeActive(_ scene: UIScene) {
           // Scene became active
           print("The scene is active.")
           ScreenCaptureManager.shared.InForeground()
           let userDefaults = UserDefaults(suiteName: "group.net.thomasdye.TDS-docs")

               // Observe changes to "TDSSharedURL"
//               userDefaults?.addObserver(self, forKeyPath: "TDSSharedURL", options: .new, context: nil)

               if let sharedURLString = userDefaults?.string(forKey: "TDVideo-SharedURL"),
                  let sharedURL = URL(string: sharedURLString) {
                   CustomWebViewController.shared.initView()
                   CustomWebViewController.shared.loadURL(sharedURL)
                   TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: sharedURL))
                 
               

                   // Handle immediately if already saved
                   userDefaults?.removeObject(forKey: "TDVideo-SharedURL")
               }
       }

       func sceneWillResignActive(_ scene: UIScene) {
           // Scene will resign active
           print("The scene is about to become inactive.")
       }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url

        print("App opened with URL: \(url.absoluteString)")

        if url.scheme?.lowercased() == "tdsvideo" { // Ensure case matches
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let queryItems = components.queryItems,
               let sharedURLString = queryItems.first(where: { $0.name == "url" })?.value,
               let sharedURL = URL(string: sharedURLString.removingPercentEncoding ?? "") {

                print("Received shared URL in app: \(sharedURL)")
                // Handle the shared URL (e.g., update UI or store for later use)
            }
        }
        
        if url.scheme?.lowercased() == "tdsvideopayment" {
            TDSVideoAPI.shared.HidePaymentScreen()
            
        }
        
    }



}

