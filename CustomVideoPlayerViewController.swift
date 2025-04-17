//
//  CustomVideoPlayerViewController.swift
//  TDS Video
//
//  Created by Thomas Dye on 05/08/2024.
//

import UIKit
import AVFoundation
import MediaPlayer


class CustomVideoPlayerViewController: UIViewController {
//    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black

        setupRemoteCommandCenter()
    }

    func setupPlayer(url: URL) {
        TDSVideoShared.shared.VideoPlayerForFile = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player:  TDSVideoShared.shared.VideoPlayerForFile )
        guard let playerLayer = playerLayer else { return }

        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspect
        view.layer.insertSublayer(playerLayer, at: 0)
        
        // Set up Now Playing Info
        setupNowPlayingInfo()
    }
    
    func setupPlayer(player: AVPlayer) {
        TDSVideoShared.shared.VideoPlayerForFile  = player
        playerLayer = AVPlayerLayer(player:  TDSVideoShared.shared.VideoPlayerForFile )
        guard let playerLayer = playerLayer else { return }

        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resize
        view.layer.insertSublayer(playerLayer, at: 0)
        
        // Set up Now Playing Info
        setupNowPlayingInfo()
    }
    
    func setupPlayerlayer(playerLayer: AVPlayerLayer) {
        
        self.playerLayer = playerLayer

        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resize
        view.layer.insertSublayer(playerLayer, at: 0)
        
        // Set up Now Playing Info
        setupNowPlayingInfo()
//        setupRemoteTransportControls()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        TDSVideoShared.shared.VideoPlayerForFile?.play()
        updateNowPlayingInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TDSVideoShared.shared.VideoPlayerForFile?.pause()
    }

    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] event in
            if  TDSVideoShared.shared.VideoPlayerForFile?.rate == 0.0 {
                TDSVideoShared.shared.VideoPlayerForFile?.play()
                self.updateNowPlayingInfo()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if  TDSVideoShared.shared.VideoPlayerForFile?.rate != 0.0 {
                TDSVideoShared.shared.VideoPlayerForFile?.pause()
                self.updateNowPlayingInfo()
                return .success
            }
            return .commandFailed
        }

        commandCenter.togglePlayPauseCommand.addTarget { [unowned self] event in
            if  TDSVideoShared.shared.VideoPlayerForFile?.rate == 0.0 {
                TDSVideoShared.shared.VideoPlayerForFile?.play()
            } else {
                TDSVideoShared.shared.VideoPlayerForFile?.pause()
            }
            self.updateNowPlayingInfo()
            return .success
        }

        commandCenter.skipForwardCommand.addTarget { [unowned self] event in
            self.skipForward()
            self.updateNowPlayingInfo()
            return .success
        }

        commandCenter.skipBackwardCommand.addTarget { [unowned self] event in
            self.skipBackward()
            self.updateNowPlayingInfo()
            return .success
        }

        commandCenter.skipForwardCommand.preferredIntervals = [15] // Skip forward 15 seconds
        commandCenter.skipBackwardCommand.preferredIntervals = [15] // Skip backward 15 seconds
        
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard
                let self = self,
                let player =  TDSVideoShared.shared.VideoPlayerForFile,
                let positionEvent = event as? MPChangePlaybackPositionCommandEvent
            else { return .commandFailed }

            let newTime = CMTimeMakeWithSeconds(positionEvent.positionTime, preferredTimescale: 1)
            player.seek(to: newTime) { _ in
                self.updateNowPlayingInfo()
            }
            return .success
        }
    }

    func setupNowPlayingInfo() {
        guard let currentItem =  TDSVideoShared.shared.VideoPlayerForFile?.currentItem else { return }

        var nowPlayingInfo = [String: Any]()

        // Set title & artist (shows up in Control Center)
        nowPlayingInfo[MPMediaItemPropertyTitle] = "TDS Video In Car Player"
        nowPlayingInfo[MPMediaItemPropertyArtist] = ""

        // Duration
        let durationInSeconds = CMTimeGetSeconds(currentItem.asset.duration)
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = durationInSeconds

        // Current playback time & rate
        let currentTimeInSeconds = CMTimeGetSeconds( TDSVideoShared.shared.VideoPlayerForFile?.currentTime() ?? .zero)
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTimeInSeconds
        // Rate of 1.0 = normal speed, 0.0 = paused
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] =  TDSVideoShared.shared.VideoPlayerForFile?.rate ?? 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    


    func updateNowPlayingInfo() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        if let player =  TDSVideoShared.shared.VideoPlayerForFile, let currentItem = player.currentItem {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player.currentTime())
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func skipForward() {
        guard let player =  TDSVideoShared.shared.VideoPlayerForFile , let currentItem = player.currentItem else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 15.0
        if newTime < CMTimeGetSeconds(currentItem.duration) {
            let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: currentItem.asset.duration.timescale)
            player.seek(to: time)
        }
    }

    func skipBackward() {
        guard let player =  TDSVideoShared.shared.VideoPlayerForFile  else { return }
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = max(currentTime - 15.0, 0)
        let time = CMTimeMakeWithSeconds(newTime, preferredTimescale: player.currentItem?.asset.duration.timescale ?? 1)
        player.seek(to: time)
    }
    

    
}
