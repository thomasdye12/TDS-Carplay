//
//  TDSCarPlayControlCommandCenter.swift
//  TDS Video
//
//  Created by Codex on 24/06/2026.
//

import CoreFoundation
import Foundation
import UIKit

final class TDSCarPlayControlCommandCenter {
    static let shared = TDSCarPlayControlCommandCenter()

    private var isStarted = false
    private let viewMoveStep: CGFloat = 16
    private let pageScrollStep: CGFloat = 220
    private let fitZoomStep = 0.03
    private var lastPlayPauseRunTime: CFAbsoluteTime = 0

    private init() {}

    func start() {
        guard !isStarted else { return }
        isStarted = true

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let commandCenter = Unmanaged<TDSCarPlayControlCommandCenter>
                    .fromOpaque(observer)
                    .takeUnretainedValue()
                commandCenter.handlePendingCommand()
            },
            TDSCarPlayControlBridge.notificationName as CFString,
            nil,
            .deliverImmediately
        )

        handlePendingCommand()
    }

    func run(_ command: TDSCarPlayControlCommand) {
        DispatchQueue.main.async {
            let webController = CustomWebViewController.shared

            switch command {
            case .openYouTube:
                webController.loadURL(CustomWebViewController.youtubeURL)
                TDSVideoShared.shared.CarPlayComp?(
                    .init(type: .web, URL: CustomWebViewController.youtubeURL, reloadWeb: false)
                )
            case .scrollPageUp:
                webController.scrollBy(x: 0, y: -self.pageScrollStep)
            case .scrollPageDown:
                webController.scrollBy(x: 0, y: self.pageScrollStep)
            case .fitVideo:
                webController.fitYouTubeVideoToCurrentView()
            case .fitVideoZoomIn:
                webController.adjustYouTubeFitScale(by: self.fitZoomStep)
                webController.fitYouTubeVideoToCurrentView()
            case .fitVideoZoomOut:
                webController.adjustYouTubeFitScale(by: -self.fitZoomStep)
                webController.fitYouTubeVideoToCurrentView()
            case .playPause:
                let now = CFAbsoluteTimeGetCurrent()
                guard now - self.lastPlayPauseRunTime > 0.6 else {
                    print("TDS CarPlay ignored repeated play/pause command")
                    return
                }
                self.lastPlayPauseRunTime = now
                webController.toggleCurrentPageVideoPlayback()
            case .youtubePreviousItem:
                webController.focusPreviousYouTubeItem()
            case .youtubeNextItem:
                webController.focusNextYouTubeItem()
            case .youtubeSelectItem:
                webController.selectFocusedYouTubeItem()
            case .contentZoomIn:
                webController.resizeContent(by: 1.1)
            case .contentZoomOut:
                webController.resizeContent(by: 0.9)
            case .viewZoomIn:
                webController.resize(by: 1.05)
            case .viewZoomOut:
                webController.resize(by: 0.95)
            case .viewLeft:
                webController.moveHorizontally(by: -self.viewMoveStep)
            case .viewRight:
                webController.moveHorizontally(by: self.viewMoveStep)
            case .viewUp:
                webController.moveVertically(by: -self.viewMoveStep)
            case .viewDown:
                webController.moveVertically(by: self.viewMoveStep)
            case .applyLayout:
                _ = webController.applySavedSettingsForCurrentDomain()
            case .saveLayout:
                webController.saveViewSettings()
            case .reloadBrowser:
                webController.reloadPage()
            case .bringBrowserToCarPlay:
                TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: webController.webView?.url, reloadWeb: false))
            }
        }
    }

    private func handlePendingCommand() {
        guard let command = TDSCarPlayControlBridge.consumePendingCommand() else { return }
        run(command)
    }

    deinit {
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(TDSCarPlayControlBridge.notificationName as CFString),
            nil
        )
    }
}
