//
//  TDSCarPlayControlShared.swift
//  TDS Video
//
//  Created by Codex on 24/06/2026.
//

import ActivityKit
import CoreFoundation
import Foundation

enum TDSCarPlayControlCommand: String, Codable, CaseIterable {
    case openYouTube
    case scrollPageUp
    case scrollPageDown
    case fitVideo
    case fitVideoZoomIn
    case fitVideoZoomOut
    case playPause
    case youtubePreviousItem
    case youtubeNextItem
    case youtubeSelectItem
    case contentZoomIn
    case contentZoomOut
    case viewZoomIn
    case viewZoomOut
    case viewLeft
    case viewRight
    case viewUp
    case viewDown
    case applyLayout
    case saveLayout
    case reloadBrowser
    case bringBrowserToCarPlay
}

enum TDSCarPlayControlBridge {
    static let appGroupIdentifier = "group.net.thomasdye.TDS-docs"
    static let commandKey = "TDSCarPlayControlCommand"
    static let commandTimestampKey = "TDSCarPlayControlCommandTimestamp"
    static let notificationName = "group.net.thomasdye.TDS-docs.TDSCarPlayControlCommand"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static func post(_ command: TDSCarPlayControlCommand) {
        let defaults = sharedDefaults
        defaults?.set(command.rawValue, forKey: commandKey)
        defaults?.set(Date().timeIntervalSince1970, forKey: commandTimestampKey)
        defaults?.synchronize()

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )
    }

    static func consumePendingCommand() -> TDSCarPlayControlCommand? {
        guard let rawValue = sharedDefaults?.string(forKey: commandKey),
              let command = TDSCarPlayControlCommand(rawValue: rawValue) else {
            return nil
        }

        sharedDefaults?.removeObject(forKey: commandKey)
        return command
    }
}

struct TDSCarPlayControlsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var lastUpdated: Date
    }

    var title: String
}
