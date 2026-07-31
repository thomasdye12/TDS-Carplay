//
//  CarPlaySceneDelegate.swift
//  TDS doc store
//
//  Created by thomas on 23/09/2022.
//

import CarPlay
import UIKit
import AVKit


extension CPTemplateApplicationScene {



    func _shouldCreateCarWindow(){
        print("CPTemplateApplicationScene CREATING")
    }
}



class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPMapTemplateDelegate, CPSearchTemplateDelegate {
    private enum CarPlayMapControlMode {
        case video
        case browser
    }

    var window: UIWindow?
    var interfaceController: CPInterfaceController?
    var player: AVPlayer?
    var playerViewController: CustomVideoPlayerViewController?
    var webViewController:CarPlayViewControllerProtocol?
    var templateApplicationScene: CPTemplateApplicationScene?
    var mapTemplate: CPMapTemplate?
    var CarPlayVideoImageView: UIImageView = UIImageView()
    let offsetStyle: SingleEdgeOffset = .left(40) // <- change this to .right(40), .top(20), etc.
    private let mapPanStep: CGFloat = 18
    private var lastMapPanTranslation: CGPoint = .zero
    private var didReceivePreciseMapPanGesture = false
    private var currentMapPanMaximumTranslation: CGFloat = 0
    private var currentMapPanStartTime: Date?
    private var lastMapTapTime: Date?
    private var mapControlMode: CarPlayMapControlMode = .video
    private let mapTapMovementThreshold: CGFloat = 8
    private let mapTapDurationThreshold: TimeInterval = 0.35
    private let mapDoubleTapInterval: TimeInterval = 0.45
    private var youtubeSearchText = ""
    private var youtubeSearchGeneration = 0
    private var youtubeSearchResults: [TDSYouTubeSearchResult] = []
    private var youtubeRecommendationsGeneration = 0
    private var youtubeSearchPreferenceObserver: NSObjectProtocol?
    private let youtubeThumbnailCache = NSCache<NSURL, UIImage>()



    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        print("We called the OLD SCENE")
    }


    //
    //
        func deliveringInterfaceControllerToDelegate(_ interfaceController: CPInterfaceController) {
            print("this is here 1")
        }

         func  _deliverInterfaceControllerToDelegate(_ interfaceController: CPInterfaceController) {
            print("this is here 2")
        }




//    func templateApplicationScene(
//        _ scene: CPTemplateApplicationScene,
//        didConnect interfaceController: CPInterfaceController,
//        to window: CPWindow
//    ) {
//        self.interfaceController = interfaceController
//        self.window = window
//
//        let item = CPListItem(text: "Test", detailText: "Attached")
//        let section = CPListSection(items: [item])
//        let template = CPListTemplate(title: "TDS", sections: [section])
//
//        interfaceController.setRootTemplate(template, animated: false) { success, error in
//            print("setRootTemplate success=\(success) error=\(String(describing: error))")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                print("scene state after root template:", scene.activationState.rawValue)
//                print("window isKey:", window.isKeyWindow)
//                print(window)
//            }
//        }
//
//
//        window.rootViewController = UIViewController()
//        window.rootViewController?.view.backgroundColor = .black
//        loadIOS()
//    }


    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController, to window: CPWindow) {






        print("We called the NEW SCENE")
        print(window)
        print(window.templateApplicationScene)
        let screen = window.screen

        let customWindow = UIWindow(frame: screen.bounds)
        customWindow.screen = screen
        customWindow.backgroundColor = .white // Or any color you prefer

        // Create a root view controller (required for the window)
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .systemBackground
        customWindow.rootViewController = rootViewController
//        showImageRowDemo(on: interfaceController)
        // Make the window visible
        customWindow.makeKeyAndVisible()
        print(customWindow)

//        interfaceController.setRootTemplate(CPGridTemplate(title: "TEST", gridButtons: []), animated: true)


        if TDSCarplayAccess.shared.ShowTDSCarPlaySettings == false  {

            return
        }
//        let bool:Bool = templateApplicationScene._shouldCreateCarWindow()
//        print(bool)
        /*emplateApplicationScene.test()*/

        self.interfaceController = interfaceController
        observeYouTubeSearchPreference()
        print(templateApplicationScene.carWindow.isUserInteractionEnabled)
//        self.interfaceController._carwin
        window.windowLevel = .normal
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()



        self.window = window
        self.window?.isUserInteractionEnabled = true
        self.window?.isMultipleTouchEnabled = true
        TDSVideoShared.shared.window = window
        print("keys")
        print(window.isKeyWindow)
        print(window.windowLevel)
        print(window.screen.snapshotView(afterScreenUpdates: true))
        print(window.canBecomeKey)
        window.makeKeyAndVisible()
        installCarPlayControlMapTemplate()
        loadIOS()
        if let rootView = self.window?.rootViewController?.view {
            TDSAirPlayReceiverManager.shared.registerCarPlayContainer(rootView)
        }
        //        print(self.window?.screen)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
//            //            self.loadWebPage(url: URL(string: "https://thomasdye.net")!)
//        })
        TDSVideoShared.shared.CarPlayComp = { url in
            ScreenCaptureManager.shared.IncomingVideoDetected = false
            switch url.type {
            case .video:
                if let mediaURL = url.URL {
                    self.playVideo(url: mediaURL)
                }

                case .web:
                self.loadWebPage()
                if url.reloadWeb != false, let webURL = url.URL {
                    CustomWebViewController.shared.loadURL(webURL)
                }

                case .rawVideo:
                self.rawVideo(player:  url.AVplayer)

            case .IOSAPP:
                DispatchQueue.main.async {
                    self.loadIOS()
                }
            }



        }

        TDSVideoURlFromOutSideOFAppListener.shared.onUpdate = {url in
            print(url)
            if let url = URL(string: url) {
                self.loadSharedURLInCar(url)
            }
        }



    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController,
                                  from window: CPWindow) {
        TDSAirPlayReceiverManager.shared.unregisterCarPlayContainer()
        stopObservingYouTubeSearchPreference()
        youtubeSearchGeneration += 1
        youtubeRecommendationsGeneration += 1
        youtubeSearchResults = []
        self.interfaceController = nil
        self.window = nil
    }



    func showImageRowDemo(on interfaceController: CPInterfaceController) {
        let image1 = UIImage(named: "test1") ?? UIImage(systemName: "photo")!
        let image2 = UIImage(named: "test1") ?? UIImage(systemName: "play.rectangle")!
        let image3 = UIImage(named: "test1") ?? UIImage(systemName: "sparkles.tv")!

        let item = CPListImageRowItem(
            text: "Image Row Demo",
            images: [image1, image2, image3]
        )

//        item.detailText = "CPListImageRowItem preview"

        item.handler = { item, completion in
            print("Tapped image row")
            completion()
        }

        let section = CPListSection(items: [item])
        let template = CPListTemplate(title: "Images", sections: [section])

        interfaceController.setRootTemplate(template, animated: false) { success, error in
            print("setRootTemplate success=\(success) error=\(String(describing: error))")
        }
    }

    private func loadSharedURLInCar(_ url: URL) {
        CustomWebViewController.shared.loadURL(url)
        loadWebPage()
    }


    func interfaceController(_ interfaceController: CPInterfaceController, didConnectWith window: CPWindow, style: UIUserInterfaceStyle) {
        print("We called the NEW SCENE with STYLE")
        if TDSCarplayAccess.shared.ShowTDSCarPlaySettings == false  {

            return
        }


        self.interfaceController = interfaceController
        observeYouTubeSearchPreference()
//        print(templateApplicationScene.carWindow.isUserInteractionEnabled)
//        self.interfaceController._carwin
        window.windowLevel = .normal
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()



        self.window = window
        self.window?.isUserInteractionEnabled = true
        self.window?.isMultipleTouchEnabled = true
        TDSVideoShared.shared.window = window
        print("keys")
        print(window.isKeyWindow)
        print(window.canBecomeKey)
        window.makeKeyAndVisible()
//        self.interfaceController?.presentTemplate(self.mapTemplate!, animated: true)
        loadIOS()
        //        print(self.window?.screen)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
//            //            self.loadWebPage(url: URL(string: "https://thomasdye.net")!)
//        })
        TDSVideoShared.shared.CarPlayComp = { url in
            ScreenCaptureManager.shared.IncomingVideoDetected = false
            switch url.type {
            case .video:
                if let mediaURL = url.URL {
                    self.playVideo(url: mediaURL)
                }

                case .web:
                self.loadWebPage()
                if url.reloadWeb != false, let webURL = url.URL {
                    CustomWebViewController.shared.loadURL(webURL)
                }

                case .rawVideo:
                self.rawVideo(player:  url.AVplayer)

            case .IOSAPP:
                DispatchQueue.main.async {
                    self.loadIOS()
                }
            }



        }

        TDSVideoURlFromOutSideOFAppListener.shared.onUpdate = {url in
            print(url)
            if let url = URL(string: url) {
                self.loadSharedURLInCar(url)
            }
        }





    }

    func rawVideo(player:AVPlayer?) {

        guard let player else { return }
        let newPlayer = CustomVideoPlayerViewController()

        if let rootViewController = self.window?.rootViewController {
            rootViewController.addChild(newPlayer)
            rootViewController.view.addSubview(newPlayer.view)
            newPlayer.view.frame = rootViewController.view.bounds
            newPlayer.didMove(toParent: rootViewController)
            newPlayer.setupPlayer(player: player)
            //                playerViewController.
            //                       playerViewController.setupPlayer(url: url)
        }
    }


    func playVideo(url:URL) {
                self.playerViewController = nil
                self.window?.rootViewController = UIViewController()

//
        self.playerViewController = CustomVideoPlayerViewController()

        guard let playerViewController = playerViewController else {

            print("no root view")
            return }
//        playerViewController.player = AVPlayer(url: url)

                if let rootViewController = self.window?.rootViewController  {
                    rootViewController.addChild(playerViewController)
                    rootViewController.view.addSubview(playerViewController.view)
                    playerViewController.view.frame = rootViewController.view.bounds
                    playerViewController.didMove(toParent: rootViewController)
                    //                playerViewController.
                    playerViewController.setupPlayer(url: url)
                }



//        let player  = AVPlayerViewController()
//                player.player = AVPlayer(url: url)
//        //        player.volumeControlsCanShowSlider = false
//
//
//        let playerViewController = player
//
//
//        if let rootViewController = ErrorHandling.Shared.MainVC {
//            rootViewController.addChild(playerViewController)
//            rootViewController.view.addSubview(playerViewController.view)
//            playerViewController.view.frame = rootViewController.view.bounds
//            playerViewController.didMove(toParent: rootViewController)
//            //                playerViewController.
//            //                       playerViewController.setupPlayer(url: url)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
//            let avcontent = playerViewController.player
//            let newPlayer = CustomVideoPlayerViewController()
//
//            if let rootViewController = self.window?.rootViewController {
//                rootViewController.addChild(newPlayer)
//                rootViewController.view.addSubview(newPlayer.view)
//                newPlayer.view.frame = rootViewController.view.bounds
//                newPlayer.didMove(toParent: rootViewController)
//                newPlayer.setupPlayer(player: avcontent!)
//                //                playerViewController.
//                //                       playerViewController.setupPlayer(url: url)
//            }
//
//
//        })
    }






    func loadWebPage() {
        installCarPlayControlMapTemplate()
        ScreenCaptureManager.shared.CarPlaysideofcarchange = { _ in
            DispatchQueue.main.async {
                CustomWebViewController.shared.applyCurrentOffsetForBrowser()
                _ = CustomWebViewController.shared.applySavedSettingsForCurrentDomain()
            }
        }
        webViewController = CustomWebViewController.shared.loadViewIncar(self.window)
    }

    private func installCarPlayControlMapTemplate() {
        guard let interfaceController else { return }

        let template = mapTemplate ?? CPMapTemplate()
        template.mapDelegate = self
        configureMapTemplateControls(template)
        mapTemplate = template

        interfaceController.setRootTemplate(template, animated: false) { success, error in
            print("CarPlay map controls installed success=\(success) error=\(String(describing: error))")
        }
    }

    private func configureMapTemplateControls(_ template: CPMapTemplate) {
        switch mapControlMode {
        case .video:
            template.mapButtons = [
                makeMapButton(systemImage: "rectangle.inset.filled", command: .fitVideo),
                makeMapButton(systemImage: "plus.magnifyingglass", command: .fitVideoZoomIn),
                makeMapButton(systemImage: "minus.magnifyingglass", command: .fitVideoZoomOut),
                makeMapButton(systemImage: "playpause.fill", command: .playPause)
            ]
            template.leadingNavigationBarButtons = [
                makeBarButton(title: "C+", command: .contentZoomIn),
                makeBarButton(title: "C-", command: .contentZoomOut)
            ]
            template.trailingNavigationBarButtons = [
                makeBarButton(title: "Web", command: .bringBrowserToCarPlay),
                makeModeBarButton(title: "Browse", mode: .browser)
            ]
        case .browser:
            var mapButtons = [makeYouTubeHomeMapButton()]
            if youtubeNativeSearchEnabled {
                mapButtons.append(makeYouTubeSearchMapButton())
            } else {
                mapButtons.append(makeMapButton(systemImage: "arrow.up.circle.fill", command: .scrollPageUp))
                mapButtons.append(makeMapButton(systemImage: "arrow.down.circle.fill", command: .scrollPageDown))
            }
            mapButtons.append(makeMapButton(systemImage: "checkmark.circle.fill", command: .youtubeSelectItem))
            template.mapButtons = mapButtons
            template.leadingNavigationBarButtons = [
                makeBarButton(title: "Prev", command: .youtubePreviousItem),
                makeBarButton(title: "Next", command: .youtubeNextItem)
            ]
            template.trailingNavigationBarButtons = [
                makeBarButton(title: "Reload", command: .reloadBrowser),
                makeModeBarButton(title: "Video", mode: .video)
            ]
        }
    }

    private var youtubeNativeSearchEnabled: Bool {
        let defaults = UserDefaults.standard
        let pickerEnabled = defaults.object(forKey: CustomWebViewController.youtubeCustomPickerEnabledKey) as? Bool ?? true
        let searchEnabled = defaults.object(forKey: CustomWebViewController.youtubePickerSearchEnabledKey) as? Bool ?? false
        return pickerEnabled && searchEnabled
    }

    private var youtubeNativeRecommendationsEnabled: Bool {
        let defaults = UserDefaults.standard
        let pickerEnabled = defaults.object(forKey: CustomWebViewController.youtubeCustomPickerEnabledKey) as? Bool ?? true
        return pickerEnabled && defaults.bool(forKey: CustomWebViewController.youtubeNativeRecommendationsEnabledKey)
    }

    private func observeYouTubeSearchPreference() {
        guard youtubeSearchPreferenceObserver == nil else { return }
        youtubeSearchPreferenceObserver = NotificationCenter.default.addObserver(
            forName: CustomWebViewController.youtubePickerSearchPreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let mapTemplate = self.mapTemplate else { return }
            self.configureMapTemplateControls(mapTemplate)
        }
    }

    private func stopObservingYouTubeSearchPreference() {
        guard let youtubeSearchPreferenceObserver else { return }
        NotificationCenter.default.removeObserver(youtubeSearchPreferenceObserver)
        self.youtubeSearchPreferenceObserver = nil
    }

    private func makeYouTubeSearchMapButton() -> CPMapButton {
        let button = CPMapButton { [weak self] _ in
            self?.showYouTubeSearch()
        }
        button.image = UIImage(systemName: "magnifyingglass")
        return button
    }

    private func makeYouTubeHomeMapButton() -> CPMapButton {
        let button = CPMapButton { [weak self] _ in
            guard let self else { return }
            if self.youtubeNativeRecommendationsEnabled {
                self.showYouTubeRecommendations()
            } else {
                TDSCarPlayControlCommandCenter.shared.run(.openYouTube)
            }
        }
        button.image = UIImage(systemName: "play.rectangle.fill")
        return button
    }

    private func showYouTubeSearch() {
        guard youtubeNativeSearchEnabled, let interfaceController else { return }
        youtubeSearchText = ""
        youtubeSearchResults = []
        youtubeSearchGeneration += 1

        let searchTemplate = CPSearchTemplate()
        searchTemplate.delegate = self
        interfaceController.pushTemplate(searchTemplate, animated: true) { success, error in
            print("CarPlay YouTube search opened success=\(success) error=\(String(describing: error))")
        }
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    ) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        youtubeSearchText = query
        youtubeSearchGeneration += 1
        let generation = youtubeSearchGeneration

        guard query.count >= 2 else {
            youtubeSearchResults = []
            completionHandler([])
            return
        }

        CustomWebViewController.shared.searchYouTube(for: query) { [weak self] result in
            guard let self else {
                completionHandler([])
                return
            }
            guard generation == self.youtubeSearchGeneration else {
                completionHandler([])
                return
            }

            switch result {
            case .success(let results):
                self.youtubeSearchResults = results
                completionHandler(results.map { self.makeYouTubeSearchItem(for: $0, includeHandler: false) })
            case .failure(let error):
                print("CarPlay YouTube search failed: \(error.localizedDescription)")
                self.youtubeSearchResults = []
                let item = CPListItem(text: "Search unavailable", detailText: "Open YouTube Home and try again")
                item.isEnabled = false
                completionHandler([item])
            }
        }
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }
        guard let urlString = item.userInfo as? String,
              let url = URL(string: urlString) else { return }
        openYouTubeSearchResult(url)
    }

    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {
        guard !youtubeSearchResults.isEmpty, let interfaceController else { return }
        let items = youtubeSearchResults.map { makeYouTubeSearchItem(for: $0, includeHandler: true) }
        let section = CPListSection(items: items)
        let resultsTemplate = CPListTemplate(
            title: youtubeSearchText.isEmpty ? "YouTube Results" : youtubeSearchText,
            sections: [section]
        )
        interfaceController.pushTemplate(resultsTemplate, animated: true) { success, error in
            print("CarPlay YouTube results opened success=\(success) error=\(String(describing: error))")
        }
    }

    private func makeYouTubeSearchItem(
        for result: TDSYouTubeSearchResult,
        includeHandler: Bool
    ) -> CPListItem {
        let detail = [result.channel, result.details].filter { !$0.isEmpty }.joined(separator: " • ")
        let item = CPListItem(
            text: result.title,
            detailText: detail.isEmpty ? nil : detail,
            image: nil,
            accessoryImage: nil,
            accessoryType: .disclosureIndicator
        )
        item.userInfo = result.videoURL.absoluteString
        if includeHandler {
            item.handler = { [weak self] _, completion in
                self?.openYouTubeSearchResult(result.videoURL)
                completion()
            }
        }
        loadYouTubeThumbnail(result.thumbnailURL, into: item)
        return item
    }

    private func loadYouTubeThumbnail(_ url: URL?, into item: CPListItem) {
        guard let url else { return }
        if let image = youtubeThumbnailCache.object(forKey: url as NSURL) {
            item.setImage(image)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self, weak item] data, _, _ in
            guard let self, let item, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                let thumbnail = self.carPlayListThumbnail(from: image)
                self.youtubeThumbnailCache.setObject(thumbnail, forKey: url as NSURL)
                item.setImage(thumbnail)
            }
        }.resume()
    }

    private func carPlayListThumbnail(from image: UIImage) -> UIImage {
        let maximumSize = CPListItem.maximumImageSize
        guard image.size.width > maximumSize.width || image.size.height > maximumSize.height else {
            return image
        }
        let scale = min(maximumSize.width / image.size.width, maximumSize.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func openYouTubeSearchResult(_ url: URL) {
        youtubeRecommendationsGeneration += 1
        let playbackURL = youtubePlaybackURL(from: url)
        CustomWebViewController.shared.loadURL(playbackURL)

        let showSelectedVideo = {
            TDSVideoShared.shared.CarPlayComp?(
                .init(type: .web, URL: playbackURL, reloadWeb: false)
            )
            CustomWebViewController.shared.playYouTubeVideoWhenReady()
        }

        guard let interfaceController else {
            showSelectedVideo()
            return
        }
        interfaceController.popToRootTemplate(animated: true) { success, error in
            print("CarPlay YouTube result selected success=\(success) error=\(String(describing: error))")
            DispatchQueue.main.async(execute: showSelectedVideo)
        }
    }

    private func youtubePlaybackURL(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              components.host?.lowercased().contains("youtube.com") == true else {
            return url
        }
        var queryItems = components.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "autoplay" }) {
            queryItems.append(URLQueryItem(name: "autoplay", value: "1"))
        }
        components.queryItems = queryItems
        return components.url ?? url
    }

    private func showYouTubeRecommendations() {
        guard youtubeNativeRecommendationsEnabled, let interfaceController else { return }
        youtubeRecommendationsGeneration += 1
        let generation = youtubeRecommendationsGeneration

        let loadingItem = CPListItem(text: "Loading recommendations…", detailText: "Using your signed-in YouTube Home feed")
        loadingItem.isEnabled = false
        let template = CPListTemplate(
            title: "Recommended",
            sections: [CPListSection(items: [loadingItem])]
        )
        interfaceController.pushTemplate(template, animated: true) { success, error in
            print("CarPlay YouTube recommendations opened success=\(success) error=\(String(describing: error))")
        }

        let currentURL = CustomWebViewController.shared.webView?.url
        let currentHost = currentURL?.host?.lowercased() ?? ""
        let isYouTubeHome = currentHost.contains("youtube.com") &&
            (currentURL?.path.isEmpty == true || currentURL?.path == "/")
        if !isYouTubeHome {
            CustomWebViewController.shared.loadURL(CustomWebViewController.youtubeURL)
        }
        loadYouTubeRecommendations(into: template, generation: generation, attempt: 0)
    }

    private func loadYouTubeRecommendations(
        into template: CPListTemplate,
        generation: Int,
        attempt: Int
    ) {
        let delay = attempt == 0 ? 0.35 : 0.65
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak template] in
            guard let self, let template, generation == self.youtubeRecommendationsGeneration else { return }
            CustomWebViewController.shared.loadYouTubeRecommendations { [weak self, weak template] result in
                guard let self, let template, generation == self.youtubeRecommendationsGeneration else { return }
                switch result {
                case .success(let recommendations) where !recommendations.isEmpty:
                    self.loadRecommendationImages(recommendations, into: template, generation: generation)
                case .success:
                    if attempt < 7 {
                        self.loadYouTubeRecommendations(
                            into: template,
                            generation: generation,
                            attempt: attempt + 1
                        )
                    } else {
                        self.showRecommendationsMessage(
                            "No recommendations found",
                            detail: "Refresh YouTube Home and try again",
                            in: template
                        )
                    }
                case .failure(let error):
                    if attempt < 7 {
                        self.loadYouTubeRecommendations(
                            into: template,
                            generation: generation,
                            attempt: attempt + 1
                        )
                    } else {
                        print("CarPlay YouTube recommendations failed: \(error.localizedDescription)")
                        self.showRecommendationsMessage(
                            "Recommendations unavailable",
                            detail: "Open YouTube Home and try again",
                            in: template
                        )
                    }
                }
            }
        }
    }

    private func loadRecommendationImages(
        _ recommendations: [TDSYouTubeSearchResult],
        into template: CPListTemplate,
        generation: Int
    ) {
        let recommendations = Array(recommendations.prefix(36))
        let group = DispatchGroup()
        let lock = NSLock()
        var images: [String: UIImage] = [:]

        for recommendation in recommendations {
            guard let url = recommendation.thumbnailURL else { continue }
            if let cached = youtubeThumbnailCache.object(forKey: url as NSURL) {
                images[recommendation.id] = cached
                continue
            }
            group.enter()
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                defer { group.leave() }
                guard let self, let data, let image = UIImage(data: data) else { return }
                let prepared = self.carPlayRecommendationThumbnail(from: image)
                self.youtubeThumbnailCache.setObject(prepared, forKey: url as NSURL)
                lock.lock()
                images[recommendation.id] = prepared
                lock.unlock()
            }.resume()
        }

        group.notify(queue: .main) { [weak self, weak template] in
            guard let self, let template, generation == self.youtubeRecommendationsGeneration else { return }
            let rows: [CPListImageRowItem]
            if #available(iOS 26.0, *) {
                let rowImages = recommendations.map {
                    images[$0.id] ?? UIImage(systemName: "play.rectangle.fill")!
                }
                rows = [self.makeRecommendationImageRow(videos: recommendations, images: rowImages)]
            } else {
                rows = stride(from: 0, to: recommendations.count, by: 3).map { start in
                    let end = min(start + 3, recommendations.count)
                    let videos = Array(recommendations[start..<end])
                    let rowImages = videos.map {
                        images[$0.id] ?? UIImage(systemName: "play.rectangle.fill")!
                    }
                    return self.makeRecommendationImageRow(videos: videos, images: rowImages)
                }
            }
            template.updateSections([CPListSection(items: rows)])
        }
    }

    private func makeRecommendationImageRow(
        videos: [TDSYouTubeSearchResult],
        images: [UIImage]
    ) -> CPListImageRowItem {
        let row: CPListImageRowItem
        if #available(iOS 26.0, *) {
            let elements = zip(videos, images).map { video, image in
                let subtitle = [video.channel, video.details]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • ")
                return CPListImageRowItemRowElement(
                    image: image,
                    title: video.title,
                    subtitle: subtitle.isEmpty ? nil : subtitle
                )
            }
            row = CPListImageRowItem(text: nil, elements: elements, allowsMultipleLines: true)
        } else if #available(iOS 17.4, *) {
            row = CPListImageRowItem(
                text: "Recommended",
                images: images,
                imageTitles: videos.map(\.title)
            )
        } else {
            row = CPListImageRowItem(text: videos.first?.title ?? "Recommended", images: images)
        }
        row.listImageRowHandler = { [weak self] _, index, completion in
            defer { completion() }
            guard videos.indices.contains(index) else { return }
            self?.openYouTubeSearchResult(videos[index].videoURL)
        }
        row.handler = { [weak self] _, completion in
            defer { completion() }
            guard let first = videos.first else { return }
            self?.openYouTubeSearchResult(first.videoURL)
        }
        return row
    }

    private func carPlayRecommendationThumbnail(from image: UIImage) -> UIImage {
        let maximumSize: CGSize
        if #available(iOS 26.0, *) {
            maximumSize = CPListImageRowItemRowElement.maximumImageSize
        } else {
            maximumSize = CPListImageRowItem.maximumImageSize
        }
        let scale = min(maximumSize.width / image.size.width, maximumSize.height / image.size.height, 1)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: size).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private func showRecommendationsMessage(_ text: String, detail: String, in template: CPListTemplate) {
        let item = CPListItem(text: text, detailText: detail)
        item.isEnabled = false
        template.updateSections([CPListSection(items: [item])])
    }

    private func makeMapButton(systemImage: String, command: TDSCarPlayControlCommand) -> CPMapButton {
        let button = CPMapButton { _ in
            print("CarPlay map button tapped command=\(command.rawValue)")
            TDSCarPlayControlCommandCenter.shared.run(command)
        }
        button.image = UIImage(systemName: systemImage)
        return button
    }

    private func makeBarButton(title: String, command: TDSCarPlayControlCommand) -> CPBarButton {
        let button = CPBarButton(title: title) { _ in
            print("CarPlay bar button tapped title=\(title) command=\(command.rawValue)")
            TDSCarPlayControlCommandCenter.shared.run(command)
        }
        return button
    }

    private func makeModeBarButton(title: String, mode: CarPlayMapControlMode) -> CPBarButton {
        let button = CPBarButton(title: title) { [weak self] _ in
            guard let self else { return }
            print("CarPlay map control mode changed to \(mode)")
            self.mapControlMode = mode
            self.installCarPlayControlMapTemplate()
        }
        return button
    }

    func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        lastMapPanTranslation = .zero
        currentMapPanMaximumTranslation = 0
        currentMapPanStartTime = Date()
        print("CarPlay map control pan started step=\(mapPanStep)")
    }

    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didUpdatePanGestureWithTranslation translation: CGPoint,
        velocity: CGPoint
    ) {
        didReceivePreciseMapPanGesture = true

        let delta = CGPoint(
            x: translation.x - lastMapPanTranslation.x,
            y: translation.y - lastMapPanTranslation.y
        )
        lastMapPanTranslation = translation
        currentMapPanMaximumTranslation = max(
            currentMapPanMaximumTranslation,
            hypot(translation.x, translation.y)
        )

        CustomWebViewController.shared.scrollBy(x: -delta.x, y: -delta.y)

        print("CarPlay map control precise scroll translation=\(translation) delta=\(delta) velocity=\(velocity)")
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        var directionNames: [String] = []

        if direction.contains(.left) {
            directionNames.append("left")
            if !didReceivePreciseMapPanGesture {
                CustomWebViewController.shared.scrollBy(x: mapPanStep, y: 0)
            }
        }
        if direction.contains(.right) {
            directionNames.append("right")
            if !didReceivePreciseMapPanGesture {
                CustomWebViewController.shared.scrollBy(x: -mapPanStep, y: 0)
            }
        }
        if direction.contains(.up) {
            directionNames.append("up")
            if !didReceivePreciseMapPanGesture {
                CustomWebViewController.shared.scrollBy(x: 0, y: mapPanStep)
            }
        }
        if direction.contains(.down) {
            directionNames.append("down")
            if !didReceivePreciseMapPanGesture {
                CustomWebViewController.shared.scrollBy(x: 0, y: -mapPanStep)
            }
        }

        let readableDirection = directionNames.isEmpty ? "unknown" : directionNames.joined(separator: "+")
        print("CarPlay map control fallback scroll direction=\(readableDirection) raw=\(direction.rawValue)")
    }

    func mapTemplate(
        _ mapTemplate: CPMapTemplate,
        didEndPanGestureWithVelocity velocity: CGPoint
    ) {
        lastMapPanTranslation = .zero
        handlePossibleCarPlayMapTap()
        print("CarPlay map control precise pan ended velocity=\(velocity)")
    }

    func mapTemplateDidEndPanGesture(_ mapTemplate: CPMapTemplate) {
        lastMapPanTranslation = .zero
        handlePossibleCarPlayMapTap()
        print("CarPlay map control pan ended")
    }

    private func handlePossibleCarPlayMapTap() {
        guard let startTime = currentMapPanStartTime else { return }

        defer {
            currentMapPanStartTime = nil
            currentMapPanMaximumTranslation = 0
        }

        let now = Date()
        let duration = now.timeIntervalSince(startTime)
        guard duration <= mapTapDurationThreshold,
              currentMapPanMaximumTranslation <= mapTapMovementThreshold else { return }

        if let lastMapTapTime,
           now.timeIntervalSince(lastMapTapTime) <= mapDoubleTapInterval {
            self.lastMapTapTime = nil
            print("CarPlay map control double tap detected; clicking current cursor position")
            CustomWebViewController.shared.select()
        } else {
            lastMapTapTime = now
            print("CarPlay map control tap candidate detected; waiting for second tap")
        }
    }


    func loadIOS() {

        ScreenCaptureManager.shared.CarPlaysideofcarchange = { offset in
            DispatchQueue.main.async {
                if let rootViewController = self.window?.rootViewController {
                    // Remove all existing constraints affecting CarPlayVideoImageView
                    NSLayoutConstraint.deactivate(self.CarPlayVideoImageView.constraints)
                    self.CarPlayVideoImageView.removeFromSuperview()
                    rootViewController.view.addSubview(self.CarPlayVideoImageView)
                    self.CarPlayVideoImageView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        self.CarPlayVideoImageView.topAnchor.constraint(equalTo: rootViewController.view.topAnchor, constant: offset.topValue),
                        self.CarPlayVideoImageView.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor, constant: offset.bottomValue),
                        self.CarPlayVideoImageView.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor, constant: offset.leftValue),
                        self.CarPlayVideoImageView.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor, constant: offset.rightValue)
                    ])

                    rootViewController.view.setNeedsLayout()
                    rootViewController.view.layoutIfNeeded()
                }
            }
        }



        for subview in window!.subviews {
            subview.removeFromSuperview()
            print(subview)
        }

         self.window?.isUserInteractionEnabled = true
         self.window?.rootViewController = UIViewController()
         self.window?.rootViewController?.view.isUserInteractionEnabled = true


         // Properly add the CustomWebViewController's view to the window
         if let rootViewController = self.window?.rootViewController {
             CarPlayVideoImageView.backgroundColor = .black
             CarPlayVideoImageView.contentMode = .init(rawValue: ScreenCaptureManager.shared.selectedAspectRatio.rawValue) ??  .scaleAspectFill
             rootViewController.view.addSubview(CarPlayVideoImageView)
             CarPlayVideoImageView.translatesAutoresizingMaskIntoConstraints = false
             NSLayoutConstraint.activate([
                 CarPlayVideoImageView.topAnchor.constraint(equalTo: rootViewController.view.topAnchor, constant: offsetStyle.topValue),
                 CarPlayVideoImageView.bottomAnchor.constraint(equalTo: rootViewController.view.bottomAnchor, constant: offsetStyle.bottomValue),
                 CarPlayVideoImageView.leadingAnchor.constraint(equalTo: rootViewController.view.leadingAnchor, constant: offsetStyle.leftValue),
                 CarPlayVideoImageView.trailingAnchor.constraint(equalTo: rootViewController.view.trailingAnchor, constant: offsetStyle.rightValue)
             ])
             CarPlayVideoImageView.backgroundColor = .black
             ScreenCaptureManager.shared.addImageView(imageView: CarPlayVideoImageView,orientation: .init(rawValue: ScreenCaptureManager.shared.selectedOrientation.rawValue) ?? .left)
             TDSAirPlayReceiverManager.shared.registerCarPlayContainer(rootViewController.view)
         }


    }


    func templateApplicationDashboardScene(_ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didConnect dashboardController: CPDashboardController, to window: UIWindow) {

        print("CONNECTED TO DASHBOARD")
//        // Retain references to the dashboard controller and window for
//        // the entire duration of the CarPlay Dashboard session.
//        self.dashboardController = dashboardController
//        self.dashboardWindow = window
//
//        // Assign the window's root view controller to the view controller
//        // that draws your map content.
//        window.rootViewController = MapRenderingViewController()
//
//        // Create your shortcut buttons and add them to the dashboard.
//        dashboardController.shortcutButtons = makeShortcutButtons()
    }


}


enum SingleEdgeOffset {
    case none
    case top(CGFloat)
    case bottom(CGFloat)
    case left(CGFloat)
    case right(CGFloat)
}

extension SingleEdgeOffset {
    var topValue: CGFloat {
        if case .top(let v) = self { return v } else { return 0 }
    }
    var bottomValue: CGFloat {
        if case .bottom(let v) = self { return -v } else { return 0 }
    }
    var leftValue: CGFloat {
        if case .left(let v) = self { return v } else { return 0 }
    }
    var rightValue: CGFloat {
        if case .right(let v) = self { return -v } else { return 0 }
    }

    func insetRect(in bounds: CGRect) -> CGRect {
        bounds.inset(by: UIEdgeInsets(
            top: topValue,
            left: leftValue,
            bottom: -bottomValue,
            right: -rightValue
        ))
    }
}
extension SingleEdgeOffset {
    // Presets
    static let leftDefault: SingleEdgeOffset = .left(20)
    static let rightDefault: SingleEdgeOffset = .right(20)
    static let topDefault: SingleEdgeOffset = .top(40)
    static let bottomDefault: SingleEdgeOffset = .bottom(40)
    static let noneDefault: SingleEdgeOffset = .none
}
extension SingleEdgeOffset {
    var rawValue: String {
        switch self {
        case .none: return "none"
        case .top(let v): return "top:\(v)"
        case .bottom(let v): return "bottom:\(v)"
        case .left(let v): return "left:\(v)"
        case .right(let v): return "right:\(v)"
        }
    }

    init?(rawValue: String) {
        if rawValue == "none" {
            self = .none
            return
        }
        let parts = rawValue.split(separator: ":")
        guard parts.count == 2,
              let value = Double(parts[1]) else {
            return nil
        }
        switch parts[0] {
        case "top": self = .top(CGFloat(value))
        case "bottom": self = .bottom(CGFloat(value))
        case "left": self = .left(CGFloat(value))
        case "right": self = .right(CGFloat(value))
        default: return nil
        }
    }
}

enum OffsetOption: String, CaseIterable, Identifiable {
    case none, top, bottom, left, right

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .top: return "Top "
        case .bottom: return "Bottom "
        case .left: return "Left"
        case .right: return "Right"
        }
    }

    var offset: SingleEdgeOffset {
        switch self {
        case .none: return .none
        case .top: return .top(40)
        case .bottom: return .bottom(40)
        case .left: return .left(20)
        case .right: return .right(20)
        }
    }

    static func from(offset: SingleEdgeOffset) -> OffsetOption {
        switch offset {
        case .none: return .none
        case .top: return .top
        case .bottom: return .bottom
        case .left: return .left
        case .right: return .right
        }
    }
}
