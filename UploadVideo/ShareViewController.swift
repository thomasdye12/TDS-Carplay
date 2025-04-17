//
//  ShareViewController.swift
//  UploadVideo
//
//  Created by Thomas Dye on 05/08/2024.
//

import UIKit
import Social
import MobileCoreServices
import AVFoundation

class ShareViewController: SLComposeServiceViewController {
    
    override func isContentValid() -> Bool {
        return true
    }
    
    override func didSelectPost() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments else {
            return
        }
        
        for attachment in attachments {
            print(attachment)
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                handleURL(attachment: attachment)
            } else if attachment.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                handleVideo(attachment: attachment)
            }
        }
    }
    
    private func handleURL(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.url.identifier as String, options: nil) { (item, error) in
            if let url = item as? URL {
                self.saveURL(url: url)
            }
        }
    }
    
    private func handleVideo(attachment: NSItemProvider) {
        attachment.loadItem(forTypeIdentifier: UTType.movie.identifier as String, options: nil) { (item, error) in
            if let url = item as? URL {
                self.saveVideo(url: url)
            }
        }
    }
    
    private func saveURL(url: URL) {
        let sharedDefaults = UserDefaults(suiteName: "group.net.thomasdye.TDS-docs")
        sharedDefaults?.set(url.absoluteString, forKey: "TDVideo-SharedURL")
        
        // Post cross-process notification
               let notificationName = "group.net.thomasdye.TDS-docs.TDVideo-SharedURL"
               CFNotificationCenterPostNotification(
                   CFNotificationCenterGetDarwinNotifyCenter(),
                   CFNotificationName(notificationName as CFString),
                   nil,
                   nil,
                   true
               )

        // Complete request to close extension
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }



    
    private func saveVideo(url: URL) {
        saveURL(url: url)
    }
    private func openAppWithURL(url: URL) {
        let encodedURL = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let scheme = "TDSVideo://shared-url?url=\(encodedURL)"
        
        if let appURL = URL(string: scheme) {
            DispatchQueue.main.async {
                self.extensionContext?.open(appURL, completionHandler: { success in
                    if success {
                        print("Opened main app successfully")
                    } else {
                        print("Failed to open main app")
                    }
                })
            }
        } else {
            print("Invalid URL: \(scheme)")
        }
    }

    
    override func configurationItems() -> [Any]! {
        return []
    }
}
