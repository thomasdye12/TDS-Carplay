//
//  CarplayWKWebView.swift
//  TDS Video
//
//  Created by Thomas Dye on 05/08/2024.
//

import UIKit
import WebKit
import AVKit

struct TDSYouTubeSearchResult {
    let id: String
    let title: String
    let channel: String
    let details: String
    let thumbnailURL: URL?
    let videoURL: URL
}

class CustomWebViewController: CarPlayViewControllerProtocol, WKNavigationDelegate, WKUIDelegate, UIGestureRecognizerDelegate, WKScriptMessageHandler {

    static let shared = CustomWebViewController()
    static let youtubeURL = URL(string: "https://www.youtube.com")!
    static let youtubeSignInURL = URL(string: "https://www.youtube.com/signin?action_handle_signin=true&next=%2F")!
    static let youtubeBrowseZoom: CGFloat = 0.60
    static let youtubeFullscreenEnabledKey = "YouTubeFullscreenEnabled"
    static let youtubeAutoFitEnabledKey = "YouTubeAutoFitEnabled"
    static let youtubeFitScaleKey = "YouTubeFitScale"
    static let youtubeAutoFitDelayKey = "YouTubeAutoFitDelay"
    static let youtubeCustomPickerEnabledKey = "YouTubeCustomPickerEnabled"
    static let youtubePickerSearchEnabledKey = "YouTubePickerSearchEnabled"
    static let youtubeNativeRecommendationsEnabledKey = "YouTubeNativeRecommendationsEnabled"
    static let youtubePickerSearchPreferenceDidChange = Notification.Name("TDSYouTubePickerSearchPreferenceDidChange")
    static let youtubeFitScaleDefault = 1.30
    static let youtubeFitScaleRange = 1.0...2.0
    private let quickSelectsKey = "WebQuickSelects"
    var webView: WKWebView?
    var cursorImageView: UIImageView?
    var containerView: UIView?
    var IsIncar: Bool = false
    var CPwindow:UIWindow?
    private var zoomScale: CGFloat = 1.0
    private let carPlayGestureLoggerPrefix = "tds.carplay.gesture.logger"
    private weak var browserStandbyView: TDSBrowserStandbyView?

    func initView(){
        guard webView == nil else { return }

        // Initialize and configure the container view
        containerView = UIView(frame: self.view.frame)
        containerView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(containerView!)

        // Initialize and configure the web view
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
               }
        config.allowsPictureInPictureMediaPlayback = true

        let youtubeFullscreenEnabled = UserDefaults.standard.object(forKey: Self.youtubeFullscreenEnabledKey) as? Bool ?? true
        let youtubeAutoFitEnabled = UserDefaults.standard.object(forKey: Self.youtubeAutoFitEnabledKey) as? Bool ?? true
        let youtubeFitScale = UserDefaults.standard.object(forKey: Self.youtubeFitScaleKey) as? Double ?? Self.youtubeFitScaleDefault
        let youtubeAutoFitDelay = UserDefaults.standard.object(forKey: Self.youtubeAutoFitDelayKey) as? Double ?? 3.0
        let youtubeCustomPickerEnabled = UserDefaults.standard.object(forKey: Self.youtubeCustomPickerEnabledKey) as? Bool ?? true
        let youtubePickerSearchEnabled = UserDefaults.standard.object(forKey: Self.youtubePickerSearchEnabledKey) as? Bool ?? false
        let script = """
                    (function() {
                        window.tdsYoutubeFullscreenEnabled = \(youtubeFullscreenEnabled ? "true" : "false");
                        window.tdsYoutubeAutoFitEnabled = \(youtubeAutoFitEnabled ? "true" : "false");
                        window.tdsYoutubeFitScale = \(youtubeFitScale);
                        window.tdsYoutubeAutoFitDelay = \(youtubeAutoFitDelay);
                        window.tdsYoutubePickerEnabled = \(youtubeCustomPickerEnabled ? "true" : "false");
                        window.tdsYoutubePickerSearchEnabled = \(youtubePickerSearchEnabled ? "true" : "false");

                        window.tdsIsYouTube = function() {
                            return window.location.hostname.includes('youtube.com') || window.location.hostname.includes('youtu.be');
                        };

                        window.tdsIsYouTubePlaybackPage = function() {
                            const path = window.location.pathname.toLowerCase();
                            return ['/watch', '/shorts', '/embed', '/live'].some(
                                prefix => path === prefix || path.startsWith(prefix + '/')
                            );
                        };

                        window.tdsInstallYouTubeOverlayHiding = function() {
                            if (document.getElementById('tds-youtube-native-controls-only-style')) {
                                return true;
                            }

                            const root = document.head || document.documentElement;
                            if (!root) {
                                setTimeout(window.tdsInstallYouTubeOverlayHiding, 0);
                                return false;
                            }

                            const style = document.createElement('style');
                            style.id = 'tds-youtube-native-controls-only-style';
                            style.textContent = `
                                html.tds-youtube-native-controls-only .ytp-chrome-bottom,
                                html.tds-youtube-native-controls-only .ytp-chrome-top,
                                html.tds-youtube-native-controls-only .ytp-gradient-bottom,
                                html.tds-youtube-native-controls-only .ytp-gradient-top,
                                html.tds-youtube-native-controls-only .ytp-pause-overlay,
                                html.tds-youtube-native-controls-only .ytp-large-play-button,
                                html.tds-youtube-native-controls-only .ytp-bezel,
                                html.tds-youtube-native-controls-only .ytp-spinner,
                                html.tds-youtube-native-controls-only .ytp-scroll-min,
                                html.tds-youtube-native-controls-only .ytp-popup.ytp-contextmenu,
                                html.tds-youtube-native-controls-only .ytp-contextmenu,
                                html.tds-youtube-native-controls-only yt-player-overlay-video-details-renderer,
                                html.tds-youtube-native-controls-only .ytPlayerOverlayVideoDetailsRendererHost,
                                html.tds-youtube-native-controls-only .video-custom-annotations,
                                html.tds-youtube-native-controls-only .video-annotations,
                                html.tds-youtube-native-controls-only .ytp-iv-video-content {
                                    display: none !important;
                                    visibility: hidden !important;
                                    opacity: 0 !important;
                                    pointer-events: none !important;
                                }
                            `;
                            root.appendChild(style);
                            return true;
                        };

                        window.tdsReportYouTubeNavigation = function() {
                            if (window.top !== window || !window.tdsIsYouTube()) { return; }
                            window.tdsInstallYouTubeOverlayHiding();
                            document.documentElement?.classList.toggle(
                                'tds-youtube-native-controls-only',
                                window.tdsIsYouTubePlaybackPage()
                            );
                            window.webkit?.messageHandlers?.tdsYouTubeNavigation?.postMessage(window.location.href);
                        };

                        ['DOMContentLoaded', 'load', 'yt-navigate-finish', 'yt-page-data-updated'].forEach(eventName => {
                            window.addEventListener(eventName, window.tdsReportYouTubeNavigation, true);
                            document.addEventListener(eventName, window.tdsReportYouTubeNavigation, true);
                        });
                        window.tdsInstallYouTubeOverlayHiding();
                        setTimeout(window.tdsReportYouTubeNavigation, 0);

                        // YouTube's signed-in home feed is the source of truth for the
                        // recommendations. This replaces only the browsing surface with
                        // a larger, calmer CarPlay-oriented picker; watch pages still use
                        // the normal YouTube player and therefore the same cookies/session.
                        window.tdsInstallYouTubePicker = function() {
                            if (window.top !== window || !window.tdsIsYouTube()) { return; }
                            if (!window.tdsYoutubePickerEnabled) {
                                document.getElementById('tds-youtube-picker')?.setAttribute('hidden', '');
                                return;
                            }

                            const pickerId = 'tds-youtube-picker';
                            const styleId = 'tds-youtube-picker-style';
                            const recentKey = 'tds-youtube-current-video-v1';
                            const browsePaths = new Set(['/', '/feed/subscriptions']);

                            function isBrowsePage() {
                                return browsePaths.has(window.location.pathname);
                            }

                            function reportPickerStatus(state, count, detail) {
                                const status = [state, Number(count || 0), String(detail || '')].join(':');
                                if (window.tdsYouTubePickerLastStatus === status) { return; }
                                window.tdsYouTubePickerLastStatus = status;
                                window.webkit?.messageHandlers?.tdsYouTubePickerStatus?.postMessage({
                                    state,
                                    count: Number(count || 0),
                                    detail: String(detail || ''),
                                    path: window.location.pathname
                                });
                            }

                            function normaliseText(value) {
                                return String(value || '').replace(/\\s+/g, ' ').trim();
                            }

                            function videoIdFromUrl(value) {
                                try {
                                    const url = new URL(value, window.location.href);
                                    if (url.pathname === '/watch') {
                                        return url.searchParams.get('v');
                                    }
                                    if (url.pathname.startsWith('/shorts/')) {
                                        return url.pathname.split('/')[2] || null;
                                    }
                                } catch (_) {}
                                return null;
                            }

                            function canonicalWatchUrl(value) {
                                const id = videoIdFromUrl(value);
                                return id ? '/watch?v=' + encodeURIComponent(id) : value;
                            }

                            function imageUrlFrom(element) {
                                const image = element.querySelector(
                                    'img.yt-core-image, img#img, ytd-thumbnail img, yt-thumbnail-view-model img, img'
                                );
                                return image?.currentSrc || image?.src || image?.getAttribute('data-thumb') || '';
                            }

                            function progressFrom(element) {
                                const resume = element.querySelector(
                                    'ytd-thumbnail-overlay-resume-playback-renderer, yt-thumbnail-overlay-progress-bar-view-model'
                                );
                                const progress = element.querySelector(
                                    '#progress, .ytd-thumbnail-overlay-resume-playback-renderer #progress, [style*="--yt-thumbnail-overlay-progress-bar"]'
                                );

                                const candidates = [
                                    progress?.style?.width,
                                    progress?.getAttribute?.('aria-valuenow'),
                                    progress?.style?.getPropertyValue?.('--yt-thumbnail-overlay-progress-bar'),
                                    resume?.getAttribute?.('aria-valuenow')
                                ];

                                for (const candidate of candidates) {
                                    const number = Number.parseFloat(candidate);
                                    if (Number.isFinite(number) && number > 0) {
                                        return Math.min(99, number);
                                    }
                                }

                                const label = normaliseText(
                                    resume?.getAttribute?.('aria-label') ||
                                    element.querySelector('[aria-label*="watched"], [aria-label*="progress"]')?.getAttribute('aria-label')
                                );
                                const match = label.match(/(\\d{1,3})\\s*%/);
                                return match ? Math.min(99, Number(match[1])) : 0;
                            }

                            function metadataFromRenderer(renderer) {
                                const anchor = Array.from(renderer.querySelectorAll('a[href*="/watch"], a[href*="/shorts/"]'))
                                    .find(item => videoIdFromUrl(item.href));
                                if (!anchor) { return null; }

                                const id = videoIdFromUrl(anchor.href);
                                if (!id) { return null; }

                                const titleElement = renderer.querySelector(
                                    '#video-title, h3 a, [id="video-title-link"], .yt-lockup-metadata-view-model__title, [aria-label][href*="/watch"]'
                                );
                                const channelElement = renderer.querySelector(
                                    '#channel-name, ytd-channel-name, .yt-content-metadata-view-model__metadata-row:first-child, [class*="byline"]'
                                );
                                const metadataRows = Array.from(renderer.querySelectorAll(
                                    '#metadata-line span, .yt-content-metadata-view-model__metadata-text, [class*="metadata"] span'
                                )).map(item => normaliseText(item.textContent)).filter(Boolean);

                                const title = normaliseText(
                                    titleElement?.getAttribute('title') ||
                                    titleElement?.getAttribute('aria-label') ||
                                    titleElement?.textContent ||
                                    anchor.getAttribute('aria-label')
                                );
                                if (!title) { return null; }

                                const duration = normaliseText(
                                    renderer.querySelector(
                                        'ytd-thumbnail-overlay-time-status-renderer, badge-shape .yt-badge-shape__text, [class*="time-status"]'
                                    )?.textContent
                                );

                                return {
                                    id,
                                    url: canonicalWatchUrl(anchor.href),
                                    title,
                                    channel: normaliseText(channelElement?.textContent),
                                    details: metadataRows.slice(-2).join(' • '),
                                    duration,
                                    thumbnail: imageUrlFrom(renderer) || ('https://i.ytimg.com/vi/' + id + '/hqdefault.jpg'),
                                    progress: progressFrom(renderer),
                                    savedAt: 0
                                };
                            }

                            function textFromYouTubeData(value) {
                                if (!value) { return ''; }
                                if (typeof value === 'string') { return normaliseText(value); }
                                if (typeof value.simpleText === 'string') {
                                    return normaliseText(value.simpleText);
                                }
                                if (Array.isArray(value.runs)) {
                                    return normaliseText(value.runs.map(run => run?.text || '').join(''));
                                }
                                if (typeof value.content === 'string') {
                                    return normaliseText(value.content);
                                }
                                return '';
                            }

                            function itemFromYouTubeDataNode(node) {
                                if (!node || typeof node !== 'object') { return null; }
                                const renderer =
                                    node.videoRenderer ||
                                    node.gridVideoRenderer ||
                                    node.compactVideoRenderer ||
                                    node.richItemRenderer?.content?.videoRenderer ||
                                    null;
                                if (renderer) {
                                    const isReel =
                                        Boolean(renderer.navigationEndpoint?.reelWatchEndpoint) &&
                                        !renderer.navigationEndpoint?.watchEndpoint;
                                    if (isReel) { return null; }

                                    const id =
                                        renderer.videoId ||
                                        renderer.navigationEndpoint?.watchEndpoint?.videoId ||
                                        null;
                                    const title =
                                        textFromYouTubeData(renderer.title) ||
                                        textFromYouTubeData(renderer.headline);
                                    if (!id || !title) { return null; }

                                    const thumbnails = renderer.thumbnail?.thumbnails || [];
                                    const thumbnail = thumbnails.length ?
                                        thumbnails[thumbnails.length - 1]?.url :
                                        ('https://i.ytimg.com/vi/' + id + '/hqdefault.jpg');
                                    const overlays = renderer.thumbnailOverlays || [];
                                    const resumeRenderer = overlays
                                        .map(overlay => overlay?.thumbnailOverlayResumePlaybackRenderer)
                                        .find(Boolean);
                                    const timeRenderer = overlays
                                        .map(overlay => overlay?.thumbnailOverlayTimeStatusRenderer)
                                        .find(Boolean);
                                    const progress = Math.min(
                                        99,
                                        Number(resumeRenderer?.percentDurationWatched || 0)
                                    );

                                    return {
                                        id,
                                        url: '/watch?v=' + encodeURIComponent(id),
                                        title,
                                        channel:
                                            textFromYouTubeData(renderer.ownerText) ||
                                            textFromYouTubeData(renderer.shortBylineText) ||
                                            textFromYouTubeData(renderer.longBylineText),
                                        details: [
                                            textFromYouTubeData(renderer.viewCountText),
                                            textFromYouTubeData(renderer.publishedTimeText)
                                        ].filter(Boolean).join(' • '),
                                        duration:
                                            textFromYouTubeData(renderer.lengthText) ||
                                            textFromYouTubeData(timeRenderer?.text),
                                        thumbnail: thumbnail || ('https://i.ytimg.com/vi/' + id + '/hqdefault.jpg'),
                                        progress,
                                        savedAt: 0
                                    };
                                }

                                // Current WEB responses use lockupViewModel for most
                                // Home-feed cards instead of videoRenderer.
                                const lockup = node.lockupViewModel;
                                const contentType = String(lockup?.contentType || '');
                                if (!lockup || (contentType && !contentType.includes('VIDEO'))) {
                                    return null;
                                }

                                const id =
                                    lockup.contentId ||
                                    lockup.rendererContext?.commandContext?.onTap
                                        ?.innertubeCommand?.watchEndpoint?.videoId ||
                                    null;
                                const metadataModel = lockup.metadata?.lockupMetadataViewModel;
                                const title =
                                    textFromYouTubeData(metadataModel?.title) ||
                                    textFromYouTubeData(lockup.title);
                                if (!id || !title) { return null; }

                                const metadataRows =
                                    metadataModel?.metadata?.contentMetadataViewModel?.metadataRows ||
                                    [];
                                const metadataParts = metadataRows.map(row =>
                                    (row?.metadataParts || [])
                                        .map(part => textFromYouTubeData(part?.text || part))
                                        .filter(Boolean)
                                ).filter(parts => parts.length);
                                const flatMetadata = metadataParts.flat();
                                const channel = flatMetadata[0] || '';
                                const details = flatMetadata.slice(1, 3).join(' • ');

                                const thumbnailModel =
                                    lockup.contentImage?.thumbnailViewModel ||
                                    lockup.contentImage?.collectionThumbnailViewModel
                                        ?.primaryThumbnail?.thumbnailViewModel;
                                const thumbnailSources =
                                    thumbnailModel?.image?.sources ||
                                    thumbnailModel?.thumbnail?.sources ||
                                    [];
                                const thumbnail = thumbnailSources.length ?
                                    thumbnailSources[thumbnailSources.length - 1]?.url :
                                    ('https://i.ytimg.com/vi/' + id + '/hqdefault.jpg');
                                const thumbnailOverlays = thumbnailModel?.overlays || [];
                                const progress = Math.min(
                                    99,
                                    Math.max(
                                        0,
                                        Number(
                                            thumbnailOverlays
                                                .map(overlay =>
                                                    overlay?.thumbnailBottomOverlayViewModel
                                                        ?.progressBar
                                                        ?.thumbnailOverlayProgressBarViewModel
                                                        ?.startPercent
                                                )
                                                .find(value => Number.isFinite(Number(value))) || 0
                                        )
                                    )
                                );

                                function findDuration(value, depth, visited) {
                                    if (!value || depth > 12) { return ''; }
                                    if (typeof value === 'string') {
                                        const text = normaliseText(value);
                                        return /^\\d{1,3}:\\d{2}(?::\\d{2})?$/.test(text) ? text : '';
                                    }
                                    if (typeof value !== 'object' || visited.has(value)) { return ''; }
                                    visited.add(value);
                                    for (const child of Object.values(value)) {
                                        const match = findDuration(child, depth + 1, visited);
                                        if (match) { return match; }
                                    }
                                    return '';
                                }

                                return {
                                    id,
                                    url: '/watch?v=' + encodeURIComponent(id),
                                    title,
                                    channel,
                                    details,
                                    duration: findDuration(
                                        lockup.contentImage,
                                        0,
                                        new WeakSet()
                                    ),
                                    thumbnail: thumbnail || ('https://i.ytimg.com/vi/' + id + '/hqdefault.jpg'),
                                    progress,
                                    savedAt: 0
                                };
                            }

                            function collectFromYouTubeData(sourceOverride) {
                                const app = document.querySelector('ytd-app');
                                const sources = Array.isArray(sourceOverride) ?
                                    sourceOverride.filter(Boolean) :
                                    [
                                        window.ytInitialData,
                                        app?.data?.response,
                                        app?.data
                                    ].filter(Boolean);
                                const results = [];
                                const videoIds = new Set();
                                const visited = new WeakSet();

                                function visit(value, depth) {
                                    if (!value || typeof value !== 'object' || depth > 24 || results.length >= 60) {
                                        return;
                                    }
                                    if (visited.has(value)) { return; }
                                    visited.add(value);

                                    const item = itemFromYouTubeDataNode(value);
                                    if (item && !videoIds.has(item.id)) {
                                        videoIds.add(item.id);
                                        results.push(item);
                                    }

                                    if (Array.isArray(value)) {
                                        value.forEach(child => visit(child, depth + 1));
                                    } else {
                                        Object.keys(value).forEach(key => {
                                            try {
                                                visit(value[key], depth + 1);
                                            } catch (_) {}
                                        });
                                    }
                                }

                                sources.forEach(source => visit(source, 0));
                                return results;
                            }

                            async function youtubeAuthorizationHeader() {
                                const cookieNames = [
                                    'SAPISID',
                                    '__Secure-3PAPISID',
                                    '__Secure-1PAPISID'
                                ];
                                const cookies = Object.fromEntries(
                                    document.cookie.split(';').map(part => {
                                        const separator = part.indexOf('=');
                                        if (separator < 0) { return [part.trim(), '']; }
                                        return [
                                            part.slice(0, separator).trim(),
                                            part.slice(separator + 1)
                                        ];
                                    })
                                );
                                const sapisidName = cookieNames.find(name => cookies[name]);
                                if (!sapisidName) { return ''; }

                                const timestamp = Math.floor(Date.now() / 1000);
                                const input = timestamp + ' ' +
                                    decodeURIComponent(cookies[sapisidName]) + ' ' +
                                    window.location.origin;
                                const digest = await crypto.subtle.digest(
                                    'SHA-1',
                                    new TextEncoder().encode(input)
                                );
                                const hash = Array.from(new Uint8Array(digest))
                                    .map(byte => byte.toString(16).padStart(2, '0'))
                                    .join('');
                                return 'SAPISIDHASH ' + timestamp + '_' + hash;
                            }

                            async function fetchYouTubeRecommendations(attempt) {
                                if (!window.tdsYoutubePickerEnabled ||
                                    !isBrowsePage() ||
                                    window.tdsYouTubeBrowseFetchInFlight) { return; }
                                const now = Date.now();
                                if (window.tdsYouTubeBrowseResponse &&
                                    now - Number(window.tdsYouTubeBrowseFetchedAt || 0) < 30000) {
                                    return;
                                }

                                const ytcfg = window.ytcfg;
                                const context = ytcfg?.get?.('INNERTUBE_CONTEXT');
                                const clientVersion =
                                    context?.client?.clientVersion ||
                                    ytcfg?.get?.('INNERTUBE_CLIENT_VERSION');
                                if (!context || !clientVersion) {
                                    if (Number(attempt || 0) < 24) {
                                        window.setTimeout(
                                            () => fetchYouTubeRecommendations(Number(attempt || 0) + 1),
                                            250
                                        );
                                    } else {
                                        reportPickerStatus('error', 0, 'YouTube API context was unavailable');
                                    }
                                    return;
                                }

                                window.tdsYouTubeBrowseFetchInFlight = true;
                                reportPickerStatus('fetching', 0, 'requesting signed-in Home feed');
                                try {
                                    const authorization = await youtubeAuthorizationHeader();
                                    const loggedIn = Boolean(ytcfg?.get?.('LOGGED_IN'));
                                    const headers = {
                                        'content-type': 'application/json',
                                        'x-origin': window.location.origin,
                                        'x-youtube-bootstrap-logged-in': 'true',
                                        'x-youtube-client-name': String(
                                            ytcfg?.get?.('INNERTUBE_CONTEXT_CLIENT_NAME') ||
                                            ytcfg?.get?.('INNERTUBE_CLIENT_NAME') ||
                                            1
                                        ),
                                        'x-youtube-client-version': String(clientVersion)
                                    };
                                    const visitorData =
                                        context?.client?.visitorData ||
                                        ytcfg?.get?.('VISITOR_DATA');
                                    if (visitorData) {
                                        headers['x-goog-visitor-id'] = String(visitorData);
                                    }
                                    const sessionIndex = ytcfg?.get?.('SESSION_INDEX');
                                    if (sessionIndex !== undefined && sessionIndex !== null) {
                                        headers['x-goog-authuser'] = String(sessionIndex);
                                    }
                                    const delegatedSessionId = ytcfg?.get?.('DELEGATED_SESSION_ID');
                                    if (delegatedSessionId) {
                                        headers['x-goog-pageid'] = String(delegatedSessionId);
                                    }
                                    if (authorization) {
                                        headers.authorization = authorization;
                                    }
                                    reportPickerStatus(
                                        'auth',
                                        0,
                                        'loggedIn=' + (loggedIn ? 'yes' : 'no') +
                                        ' authCookie=' + (authorization ? 'yes' : 'no') +
                                        ' authHeader=' + (headers.authorization ? 'yes' : 'no') +
                                        ' sessionIndex=' +
                                            (sessionIndex !== undefined && sessionIndex !== null ? 'yes' : 'no') +
                                        ' delegated=' + (delegatedSessionId ? 'yes' : 'no')
                                    );

                                    const response = await fetch(
                                        '/youtubei/v1/browse?prettyPrint=false',
                                        {
                                            method: 'POST',
                                            credentials: 'include',
                                            headers,
                                            body: JSON.stringify({
                                                browseId: 'FEwhat_to_watch',
                                                context
                                            })
                                        }
                                    );
                                    if (!response.ok) {
                                        throw new Error('browse request returned HTTP ' + response.status);
                                    }

                                    const responseJSON = await response.json();
                                    const responseLoggedOut =
                                        responseJSON?.responseContext
                                            ?.mainAppWebResponseContext
                                            ?.loggedOut;
                                    const responseText = JSON.stringify(responseJSON);
                                    const lockupCount =
                                        (responseText.match(/"lockupViewModel"/g) || []).length;
                                    const videoRendererCount =
                                        (responseText.match(/"videoRenderer"/g) || []).length;
                                    window.tdsYouTubeBrowseResponse = responseJSON;
                                    window.tdsYouTubeBrowseFetchedAt = Date.now();
                                    reportPickerStatus(
                                        'response',
                                        0,
                                        'http=' + response.status +
                                        ' loggedOut=' +
                                            (responseLoggedOut === true ? 'yes' :
                                                responseLoggedOut === false ? 'no' : 'not-reported') +
                                        ' lockups=' + lockupCount +
                                        ' videoRenderers=' + videoRendererCount
                                    );
                                    window.tdsRenderYouTubePicker?.();
                                } catch (error) {
                                    reportPickerStatus(
                                        'error',
                                        0,
                                        'Home feed request failed: ' +
                                            (error?.name || 'Error') + ': ' +
                                            (error?.message || String(error))
                                    );
                                } finally {
                                    window.tdsYouTubeBrowseFetchInFlight = false;
                                }
                            }

                            window.tdsSearchYouTubeForCarPlay = async function(rawQuery) {
                                const query = normaliseText(rawQuery);
                                if (!window.tdsYoutubePickerEnabled ||
                                    !window.tdsYoutubePickerSearchEnabled ||
                                    !query) {
                                    return [];
                                }

                                const ytcfg = window.ytcfg;
                                const context = ytcfg?.get?.('INNERTUBE_CONTEXT');
                                const clientVersion =
                                    context?.client?.clientVersion ||
                                    ytcfg?.get?.('INNERTUBE_CLIENT_VERSION');
                                if (!context || !clientVersion) {
                                    throw new Error('YouTube search context was unavailable');
                                }

                                const authorization = await youtubeAuthorizationHeader();
                                const headers = {
                                    'content-type': 'application/json',
                                    'x-origin': window.location.origin,
                                    'x-youtube-bootstrap-logged-in': 'true',
                                    'x-youtube-client-name': String(
                                        ytcfg?.get?.('INNERTUBE_CONTEXT_CLIENT_NAME') ||
                                        ytcfg?.get?.('INNERTUBE_CLIENT_NAME') ||
                                        1
                                    ),
                                    'x-youtube-client-version': String(clientVersion)
                                };
                                const visitorData =
                                    context?.client?.visitorData ||
                                    ytcfg?.get?.('VISITOR_DATA');
                                if (visitorData) {
                                    headers['x-goog-visitor-id'] = String(visitorData);
                                }
                                const sessionIndex = ytcfg?.get?.('SESSION_INDEX');
                                if (sessionIndex !== undefined && sessionIndex !== null) {
                                    headers['x-goog-authuser'] = String(sessionIndex);
                                }
                                const delegatedSessionId = ytcfg?.get?.('DELEGATED_SESSION_ID');
                                if (delegatedSessionId) {
                                    headers['x-goog-pageid'] = String(delegatedSessionId);
                                }
                                if (authorization) {
                                    headers.authorization = authorization;
                                }

                                const response = await fetch(
                                    '/youtubei/v1/search?prettyPrint=false',
                                    {
                                        method: 'POST',
                                        credentials: 'include',
                                        headers,
                                        body: JSON.stringify({ query, context })
                                    }
                                );
                                if (!response.ok) {
                                    throw new Error('search request returned HTTP ' + response.status);
                                }

                                return collectFromYouTubeData([await response.json()])
                                    .slice(0, 24)
                                    .map(item => ({
                                        id: String(item.id || ''),
                                        title: normaliseText(item.title),
                                        channel: normaliseText(item.channel),
                                        details: normaliseText(item.details),
                                        thumbnail: String(item.thumbnail || ''),
                                        url: canonicalWatchUrl(item.url)
                                    }))
                                    .filter(item => item.id && item.title && item.url);
                            };

                            function readRecentVideo() {
                                try {
                                    const item = JSON.parse(localStorage.getItem(recentKey) || 'null');
                                    if (!item?.id || !item?.title || !item?.url) { return null; }
                                    if (Date.now() - Number(item.savedAt || 0) > 30 * 24 * 60 * 60 * 1000) {
                                        return null;
                                    }
                                    return item;
                                } catch (_) {
                                    return null;
                                }
                            }

                            function collectRecommendations() {
                                const selectors = [
                                    'ytd-rich-item-renderer',
                                    'ytd-video-renderer',
                                    'ytd-grid-video-renderer',
                                    'yt-lockup-view-model',
                                    'ytd-compact-video-renderer'
                                ];
                                const seen = new Set();
                                const items = [];

                                const apiItems = window.tdsYouTubeBrowseResponse ?
                                    collectFromYouTubeData([window.tdsYouTubeBrowseResponse]) :
                                    [];
                                const pageItems = apiItems.length ? [] : collectFromYouTubeData();
                                const structuredItems = apiItems.length ? apiItems : pageItems;
                                structuredItems.forEach(item => {
                                    if (seen.has(item.id)) { return; }
                                    seen.add(item.id);
                                    items.push(item);
                                });

                                let domItemCount = 0;
                                if (!structuredItems.length) {
                                    document.querySelectorAll(selectors.join(',')).forEach(renderer => {
                                        const item = metadataFromRenderer(renderer);
                                        if (!item || seen.has(item.id)) { return; }
                                        seen.add(item.id);
                                        items.push(item);
                                        domItemCount += 1;
                                    });
                                }
                                window.tdsYouTubePickerSourceCounts = {
                                    api: apiItems.length,
                                    page: pageItems.length,
                                    dom: domItemCount,
                                    recent: 0
                                };

                                const recent = readRecentVideo();
                                if (recent && !seen.has(recent.id) && Number(recent.progress || 0) > 0) {
                                    items.unshift(recent);
                                    window.tdsYouTubePickerSourceCounts.recent = 1;
                                }

                                return items
                                    .map((item, sourceIndex) => ({ ...item, sourceIndex }))
                                    .sort((left, right) => {
                                        const leftResume = Number(left.progress || 0) > 0 ? 1 : 0;
                                        const rightResume = Number(right.progress || 0) > 0 ? 1 : 0;
                                        return (rightResume - leftResume) ||
                                            (Number(right.savedAt || 0) - Number(left.savedAt || 0)) ||
                                            (left.sourceIndex - right.sourceIndex);
                                    })
                                    .slice(0, 60);
                            }

                            window.tdsYouTubeRecommendationsForCarPlay = async function() {
                                if (!window.tdsYoutubePickerEnabled) { return []; }

                                await fetchYouTubeRecommendations(0);
                                for (let attempt = 0;
                                     attempt < 20 && window.tdsYouTubeBrowseFetchInFlight;
                                     attempt += 1) {
                                    await new Promise(resolve => window.setTimeout(resolve, 150));
                                }

                                return collectRecommendations()
                                    .slice(0, 48)
                                    .map(item => ({
                                        id: String(item.id || ''),
                                        title: normaliseText(item.title),
                                        channel: normaliseText(item.channel),
                                        details: normaliseText(item.details),
                                        thumbnail: String(item.thumbnail || ''),
                                        url: canonicalWatchUrl(item.url)
                                    }))
                                    .filter(item => item.id && item.title && item.url);
                            };

                            function installStyle() {
                                if (document.getElementById(styleId)) { return; }
                                const style = document.createElement('style');
                                style.id = styleId;
                                style.textContent = `
                                    #${pickerId} {
                                        position: fixed;
                                        inset: 0;
                                        z-index: 2147483000;
                                        overflow: auto;
                                        overscroll-behavior: contain;
                                        box-sizing: border-box;
                                        padding: 8px 12px 20px;
                                        color: #f8fafc;
                                        background:
                                            radial-gradient(circle at 15% -10%, rgba(225, 29, 72, .24), transparent 38%),
                                            #090d14;
                                        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
                                    }
                                    #${pickerId}[hidden] { display: none !important; }
                                    #${pickerId} * { box-sizing: border-box; }
                                    #${pickerId} .tds-picker-grid {
                                        display: grid;
                                        grid-template-columns: repeat(6, minmax(0, 1fr));
                                        gap: 10px;
                                    }
                                    #${pickerId} .tds-video-card {
                                        position: relative;
                                        display: block;
                                        min-width: 0;
                                        overflow: hidden;
                                        border: 2px solid rgba(255,255,255,.08);
                                        border-radius: 14px;
                                        color: inherit;
                                        background: #151b25;
                                        box-shadow: 0 14px 36px rgba(0,0,0,.25);
                                        text-decoration: none;
                                        transform: translateZ(0);
                                    }
                                    #${pickerId} .tds-video-card:focus,
                                    #${pickerId} .tds-video-card:active {
                                        border-color: #36d7ff;
                                        outline: 5px solid rgba(54, 215, 255, .52);
                                        outline-offset: 3px;
                                    }
                                    #${pickerId} .tds-thumbnail {
                                        position: relative;
                                        overflow: hidden;
                                        aspect-ratio: 16 / 9;
                                        background: #202938;
                                    }
                                    #${pickerId} .tds-thumbnail img {
                                        display: block;
                                        width: 100%;
                                        height: 100%;
                                        object-fit: cover;
                                    }
                                    #${pickerId} .tds-duration,
                                    #${pickerId} .tds-resume-label {
                                        position: absolute;
                                        right: 10px;
                                        bottom: 10px;
                                        padding: 5px 8px;
                                        border-radius: 8px;
                                        color: white;
                                        background: rgba(0,0,0,.82);
                                        font-size: 13px;
                                        font-weight: 800;
                                    }
                                    #${pickerId} .tds-resume-label {
                                        right: auto;
                                        left: 10px;
                                        color: #071017;
                                        background: #52ddff;
                                    }
                                    #${pickerId} .tds-progress-track {
                                        position: absolute;
                                        right: 0;
                                        bottom: 0;
                                        left: 0;
                                        height: 7px;
                                        background: rgba(255,255,255,.23);
                                    }
                                    #${pickerId} .tds-progress-fill {
                                        height: 100%;
                                        background: #ff174b;
                                    }
                                    #${pickerId} .tds-card-copy { padding: 9px 10px 11px; }
                                    #${pickerId} .tds-card-title {
                                        display: -webkit-box;
                                        min-height: 2.5em;
                                        margin: 0;
                                        overflow: hidden;
                                        font-size: clamp(12px, 1.45vw, 16px);
                                        font-weight: 780;
                                        line-height: 1.23;
                                        letter-spacing: -.01em;
                                        -webkit-box-orient: vertical;
                                        -webkit-line-clamp: 2;
                                    }
                                    #${pickerId} .tds-card-meta {
                                        margin: 9px 0 0;
                                        overflow: hidden;
                                        color: #aeb8c7;
                                        font-size: 11px;
                                        line-height: 1.35;
                                        text-overflow: ellipsis;
                                        white-space: nowrap;
                                    }
                                    #${pickerId} .tds-picker-empty {
                                        grid-column: 1 / -1;
                                        padding: 70px 24px;
                                        border: 2px dashed rgba(255,255,255,.18);
                                        border-radius: 22px;
                                        color: #c4ccd8;
                                        text-align: center;
                                        font-size: 20px;
                                    }
                                    @media (max-width: 620px) {
                                        #${pickerId} { padding: 8px 10px 20px; }
                                        #${pickerId} .tds-picker-grid { grid-template-columns: 1fr; }
                                    }
                                `;
                                document.documentElement.appendChild(style);
                            }

                            function cardFor(item) {
                                const card = document.createElement('a');
                                card.className = 'tds-video-card';
                                card.href = item.url;
                                card.setAttribute('aria-label', (item.progress > 0 ? 'Resume ' : 'Watch ') + item.title);

                                const thumbnail = document.createElement('div');
                                thumbnail.className = 'tds-thumbnail';
                                const image = document.createElement('img');
                                image.src = item.thumbnail;
                                image.alt = '';
                                image.loading = 'eager';
                                thumbnail.appendChild(image);

                                if (item.duration) {
                                    const duration = document.createElement('span');
                                    duration.className = 'tds-duration';
                                    duration.textContent = item.duration;
                                    thumbnail.appendChild(duration);
                                }

                                if (Number(item.progress || 0) > 0) {
                                    const resume = document.createElement('span');
                                    resume.className = 'tds-resume-label';
                                    resume.textContent = 'RESUME';
                                    thumbnail.appendChild(resume);

                                    const track = document.createElement('div');
                                    track.className = 'tds-progress-track';
                                    const fill = document.createElement('div');
                                    fill.className = 'tds-progress-fill';
                                    fill.style.width = Math.min(99, Number(item.progress)) + '%';
                                    track.appendChild(fill);
                                    thumbnail.appendChild(track);
                                }

                                const copy = document.createElement('div');
                                copy.className = 'tds-card-copy';
                                const title = document.createElement('p');
                                title.className = 'tds-card-title';
                                title.textContent = item.title;
                                const metadata = document.createElement('p');
                                metadata.className = 'tds-card-meta';
                                metadata.textContent = [item.channel, item.details].filter(Boolean).join(' • ');
                                copy.append(title, metadata);
                                card.append(thumbnail, copy);
                                return card;
                            }

                            function render() {
                                if (!window.tdsYoutubePickerEnabled || !isBrowsePage()) {
                                    document.getElementById(pickerId)?.setAttribute('hidden', '');
                                    return;
                                }

                                installStyle();
                                let picker = document.getElementById(pickerId);
                                if (!picker) {
                                    picker = document.createElement('main');
                                    picker.id = pickerId;

                                    // YouTube enforces Trusted Types, so construct this
                                    // view with DOM APIs instead of assigning innerHTML.
                                    const grid = document.createElement('section');
                                    grid.className = 'tds-picker-grid';
                                    grid.setAttribute('aria-live', 'polite');
                                    picker.appendChild(grid);
                                    (document.body || document.documentElement).appendChild(picker);
                                }

                                picker.removeAttribute('hidden');
                                const recommendations = collectRecommendations();
                                const signature = recommendations.map(item =>
                                    item.id + ':' + Math.round(Number(item.progress || 0))
                                ).join(',');
                                reportPickerStatus(
                                    recommendations.length ? 'ready' : 'waiting',
                                    recommendations.length,
                                    recommendations.length ?
                                        'recommendations rendered source=' +
                                            (Number(window.tdsYouTubePickerSourceCounts?.api || 0) > 0 ?
                                                'api' :
                                                Number(window.tdsYouTubePickerSourceCounts?.page || 0) > 0 ?
                                                    'page-data' :
                                                    Number(window.tdsYouTubePickerSourceCounts?.dom || 0) > 0 ?
                                                        'dom' :
                                                        'resume-only') +
                                        ' api=' + Number(window.tdsYouTubePickerSourceCounts?.api || 0) +
                                        ' page=' + Number(window.tdsYouTubePickerSourceCounts?.page || 0) +
                                        ' dom=' + Number(window.tdsYouTubePickerSourceCounts?.dom || 0) +
                                        ' recent=' + Number(window.tdsYouTubePickerSourceCounts?.recent || 0) :
                                        'data=' + (window.ytInitialData ? 'yes' : 'no') +
                                        ' renderers=' + document.querySelectorAll(
                                            'ytd-rich-item-renderer, ytd-video-renderer, yt-lockup-view-model'
                                        ).length +
                                        ' watchLinks=' + document.querySelectorAll('a[href*="/watch"]').length
                                );
                                if (picker.dataset.signature === signature) { return; }
                                picker.dataset.signature = signature;
                                if (recommendations.length) {
                                    reportPickerStatus(
                                        'items',
                                        recommendations.length,
                                        recommendations.slice(0, 12).map((item, index) =>
                                            (index + 1) + '. ' + item.title +
                                            (item.channel ? ' — ' + item.channel : '')
                                        ).join(' | ')
                                    );
                                }

                                const grid = picker.querySelector('.tds-picker-grid');
                                grid.replaceChildren();
                                if (!recommendations.length) {
                                    const empty = document.createElement('div');
                                    empty.className = 'tds-picker-empty';
                                    empty.textContent = 'Loading recommendations from your YouTube account…';
                                    grid.appendChild(empty);
                                    return;
                                }
                                recommendations.forEach(item => grid.appendChild(cardFor(item)));
                                if (window.tdsCarPlayYouTubeSelectedVideo) {
                                    const selectedCard = Array.from(
                                        grid.querySelectorAll('a.tds-video-card')
                                    ).find(card => {
                                        try {
                                            const url = new URL(card.href, window.location.href);
                                            return url.pathname + '?v=' + url.searchParams.get('v') ===
                                                window.tdsCarPlayYouTubeSelectedVideo;
                                        } catch (_) {
                                            return false;
                                        }
                                    });
                                    selectedCard?.setAttribute(
                                        'data-tds-carplay-selected-video',
                                        'true'
                                    );
                                }
                            }
                            window.tdsRenderYouTubePicker = render;

                            function rememberCurrentVideo() {
                                if (window.location.pathname !== '/watch') { return; }
                                const video = document.querySelector('video');
                                const id = new URL(window.location.href).searchParams.get('v');
                                const title = normaliseText(
                                    document.querySelector('h1.ytd-watch-metadata yt-formatted-string, h1 yt-formatted-string')?.textContent ||
                                    document.querySelector('meta[name="title"]')?.content ||
                                    document.title.replace(/\\s*-\\s*YouTube\\s*$/, '')
                                );
                                if (!video || !id || !title || !Number.isFinite(video.duration) || video.duration <= 0) { return; }

                                const progress = Math.min(99, Math.max(0, (video.currentTime / video.duration) * 100));
                                if (progress < 1) { return; }
                                const channel = normaliseText(
                                    document.querySelector('#owner #channel-name, ytd-video-owner-renderer #channel-name')?.textContent
                                );
                                localStorage.setItem(recentKey, JSON.stringify({
                                    id,
                                    url: '/watch?v=' + encodeURIComponent(id) + '&t=' + Math.floor(video.currentTime) + 's',
                                    title,
                                    channel,
                                    details: 'Continue watching',
                                    duration: '',
                                    thumbnail: 'https://i.ytimg.com/vi/' + id + '/hqdefault.jpg',
                                    progress,
                                    savedAt: Date.now()
                                }));
                            }

                            if (!window.tdsYouTubePickerInstalled) {
                                let renderTimer = null;
                                const scheduleRender = () => {
                                    // YouTube mutates its page continuously. A debounce
                                    // can therefore be postponed forever; a throttle
                                    // guarantees a render even while mutations continue.
                                    if (renderTimer !== null) { return; }
                                    renderTimer = setTimeout(() => {
                                        renderTimer = null;
                                        try {
                                            render();
                                        } catch (error) {
                                            reportPickerStatus(
                                                'error',
                                                0,
                                                (error?.name || 'Error') + ': ' + (error?.message || String(error))
                                            );
                                        }
                                    }, 250);
                                };

                                // WKUserScript runs at document start. On a cold load,
                                // YouTube can execute this before <html> exists. Do not
                                // mark the picker installed until its observer has a root;
                                // otherwise the first observer.observe(null) exception
                                // permanently skips setup until the user refreshes.
                                const startPicker = () => {
                                    const root = document.documentElement;
                                    if (!root) {
                                        window.setTimeout(startPicker, 25);
                                        return;
                                    }
                                    if (window.tdsYouTubePickerInstalled) {
                                        scheduleRender();
                                        return;
                                    }

                                    window.tdsYouTubePickerInstalled = true;
                                    const observer = new MutationObserver(scheduleRender);
                                    observer.observe(root, { childList: true, subtree: true });
                                    const handlePageUpdate = () => {
                                        scheduleRender();
                                        fetchYouTubeRecommendations(0);
                                    };
                                    ['DOMContentLoaded', 'load', 'yt-navigate-finish', 'yt-page-data-updated'].forEach(eventName => {
                                        window.addEventListener(eventName, handlePageUpdate, true);
                                        document.addEventListener(eventName, handlePageUpdate, true);
                                    });
                                    window.setInterval(rememberCurrentVideo, 5000);
                                    handlePageUpdate();
                                };
                                startPicker();
                            } else {
                                render();
                                fetchYouTubeRecommendations(0);
                            }
                        };
                        window.tdsInstallYouTubePicker();
                        window.tdsApplyYouTubePickerPreference = function(enabled) {
                            window.tdsYoutubePickerEnabled = Boolean(enabled);
                            const picker = document.getElementById('tds-youtube-picker');
                            if (!window.tdsYoutubePickerEnabled) {
                                picker?.setAttribute('hidden', '');
                                return 'normal YouTube homepage enabled';
                            }
                            window.tdsInstallYouTubePicker();
                            return 'custom YouTube homepage enabled';
                        };
                        window.tdsApplyYouTubePickerSearchPreference = function(enabled) {
                            window.tdsYoutubePickerSearchEnabled = Boolean(enabled);
                            const picker = document.getElementById('tds-youtube-picker');
                            if (picker && typeof window.tdsRenderYouTubePicker === 'function') {
                                window.tdsRenderYouTubePicker();
                            }
                            return window.tdsYoutubePickerSearchEnabled ?
                                'YouTube picker search enabled' :
                                'YouTube picker search disabled';
                        };

                        window.tdsDispatchFullscreenChange = function() {
                            document.dispatchEvent(new Event('fullscreenchange'));
                            document.dispatchEvent(new Event('webkitfullscreenchange'));
                        };

                        window.tdsInstallFullscreenStyles = function() {
                            if (document.getElementById('tds-carplay-fullscreen-style')) {
                                return;
                            }

                            const style = document.createElement('style');
                            style.id = 'tds-carplay-fullscreen-style';
                            style.textContent = `
                                html.tds-carplay-video-fit,
                                html.tds-carplay-video-fit body {
                                    width: 100vw !important;
                                    height: 100vh !important;
                                    margin: 0 !important;
                                    padding: 0 !important;
                                    overflow: hidden !important;
                                    background: #000 !important;
                                }

                                .tds-carplay-video-target {
                                    position: fixed !important;
                                    inset: 0 !important;
                                    width: 100vw !important;
                                    height: 100vh !important;
                                    min-width: 100vw !important;
                                    min-height: 100vh !important;
                                    max-width: 100vw !important;
                                    max-height: 100vh !important;
                                    margin: 0 !important;
                                    padding: 0 !important;
                                    z-index: 2147483647 !important;
                                    background: #000 !important;
                                    transform: none !important;
                                    translate: none !important;
                                    object-fit: contain !important;
                                    overflow: hidden !important;
                                }

                                .tds-carplay-video-target video,
                                .tds-carplay-video-target .html5-main-video,
                                .tds-carplay-video-target .html5-video-container,
                                .tds-carplay-video-target .html5-video-player,
                                .tds-carplay-video-target .ytp-player-content,
                                .tds-carplay-video-target .ytp-player-content video {
                                    position: absolute !important;
                                    inset: 0 !important;
                                    width: 100% !important;
                                    height: 100% !important;
                                    max-width: 100% !important;
                                    max-height: 100% !important;
                                    margin: auto !important;
                                    object-fit: contain !important;
                                    transform-origin: center center !important;
                                }

                                .ytp-popup.ytp-contextmenu,
                                .ytp-contextmenu,
                                .tds-carplay-video-target .ytp-chrome-bottom,
                                .tds-carplay-video-target .ytp-chrome-top,
                                .tds-carplay-video-target .ytp-gradient-bottom,
                                .tds-carplay-video-target .ytp-gradient-top,
                                .tds-carplay-video-target .ytp-pause-overlay,
                                .tds-carplay-video-target .ytp-large-play-button,
                                .tds-carplay-video-target .ytp-bezel,
                                .tds-carplay-video-target .ytp-spinner,
                                .tds-carplay-video-target .ytp-scroll-min,
                                .tds-carplay-video-target .ytp-popup.ytp-contextmenu,
                                .tds-carplay-video-target .ytp-contextmenu,
                                .tds-carplay-video-target yt-player-overlay-video-details-renderer,
                                .tds-carplay-video-target .ytPlayerOverlayVideoDetailsRendererHost,
                                .tds-carplay-video-target .video-custom-annotations,
                                .tds-carplay-video-target .video-annotations,
                                .tds-carplay-video-target .ytp-iv-video-content {
                                    display: none !important;
                                    visibility: hidden !important;
                                    opacity: 0 !important;
                                    pointer-events: none !important;
                                }

                                .tds-carplay-video-target .ytp-caption-window-container,
                                .tds-carplay-video-target .caption-window,
                                .tds-carplay-video-target .ytp-caption-segment,
                                .tds-carplay-video-target .captions-text,
                                .tds-carplay-video-target .ytp-subtitles-button {
                                    display: none !important;
                                    visibility: hidden !important;
                                    opacity: 0 !important;
                                }

                                html.tds-carplay-video-fit ytd-thumbnail.player-container-background-image,
                                html.tds-carplay-video-fit .player-container-background-image,
                                html.tds-carplay-video-fit .player-container-background,
                                html.tds-carplay-video-fit #cinematics,
                                html.tds-carplay-video-fit #cinematics-container {
                                    display: none !important;
                                    visibility: hidden !important;
                                    opacity: 0 !important;
                                    filter: none !important;
                                    backdrop-filter: none !important;
                                    -webkit-backdrop-filter: none !important;
                                    pointer-events: none !important;
                                }
                            `;
                            document.documentElement.appendChild(style);

                            if (!window.tdsYouTubeContextMenuSuppressionInstalled) {
                                window.tdsYouTubeContextMenuSuppressionInstalled = true;
                                document.addEventListener('contextmenu', event => {
                                    if (!window.tdsIsYouTube?.()) { return; }
                                    const eventTarget = event.target instanceof Element ?
                                        event.target :
                                        null;
                                    if (!eventTarget?.closest(
                                        '#movie_player, .html5-video-player, video'
                                    )) {
                                        return;
                                    }
                                    event.preventDefault();
                                    event.stopImmediatePropagation();
                                    document.querySelectorAll(
                                        '.ytp-popup.ytp-contextmenu, .ytp-contextmenu'
                                    ).forEach(menu => menu.setAttribute('hidden', ''));
                                }, true);
                            }
                        };

                        window.tdsFindYouTubePlayer = function(element) {
                            return document.querySelector('#movie_player') ||
                                element.closest('#movie_player, .html5-video-player, ytd-player') ||
                                element;
                        };

                        window.tdsFindGenericVideoFullscreenTarget = function(element) {
                            const video = element instanceof HTMLVideoElement ?
                                element :
                                (element.querySelector && element.querySelector('video')) ||
                                document.querySelector('video');

                            if (!video) {
                                return element;
                            }

                            return video.closest('[data-player], [class*="player"], [class*="Player"], [class*="video"], [class*="Video"], figure, article, section, div') || video;
                        };

                        window.tdsPostFullscreenRequest = function(element, target) {
                            try {
                                const now = Date.now();
                                if (window.tdsLastFullscreenBridgePost && now - window.tdsLastFullscreenBridgePost < 1000) {
                                    return;
                                }
                                window.tdsLastFullscreenBridgePost = now;

                                const video = element instanceof HTMLVideoElement ?
                                    element :
                                    (element && element.querySelector && element.querySelector('video')) ||
                                    (target && target.querySelector && target.querySelector('video')) ||
                                    document.querySelector('video');

                                window.webkit?.messageHandlers?.tdsFullscreenRequested?.postMessage({
                                    href: window.location.href,
                                    hostname: window.location.hostname,
                                    isYouTube: window.tdsIsYouTube(),
                                    tagName: element?.tagName || null,
                                    targetTagName: target?.tagName || null,
                                    videoSrc: video?.currentSrc || video?.src || null
                                });
                            } catch (error) {
                                console.log('TDS fullscreen request post failed', error);
                            }
                        };

                        window.tdsFitCurrentYouTubeVideo = function() {
                            const video = document.querySelector('video');
                            if (!video || !window.tdsYoutubeFullscreenEnabled) {
                                return false;
                            }

                            return window.tdsEnterCssFullscreen(video);
                        };

                        window.tdsVideoIsReadyForFit = function(video) {
                            return !!video && video.videoWidth > 0 && video.videoHeight > 0;
                        };

                        window.tdsAutoFitYouTubeWhenReady = function(video) {
                            if (!video || !window.tdsIsYouTube() || !window.tdsIsYouTubePlaybackPage() || !window.tdsYoutubeFullscreenEnabled || !window.tdsYoutubeAutoFitEnabled) {
                                return;
                            }

                            window.tdsScheduleAutoFitNow();
                        };

                        window.tdsScheduleAutoFitNow = function() {
                            if (!window.tdsIsYouTube() || !window.tdsIsYouTubePlaybackPage() || !window.tdsYoutubeFullscreenEnabled || !window.tdsYoutubeAutoFitEnabled) {
                                return false;
                            }

                            const tryFit = function() {
                                if (!window.tdsIsYouTubePlaybackPage()) { return; }
                                const video = document.querySelector('video');
                                if (!video) { return; }

                                if (window.tdsVideoIsReadyForFit(video)) {
                                    window.tdsFitCurrentYouTubeVideo();
                                }
                            };

                            window.clearTimeout(window.tdsAutoFitTimer);
                            window.tdsAutoFitTimer = setTimeout(tryFit, window.tdsYoutubeAutoFitDelay * 1000);
                            return true;
                        };

                        window.tdsInstallYouTubeAutoFitHooks = function() {
                            if (window.tdsAutoFitHooksInstalled) { return; }
                            window.tdsAutoFitHooksInstalled = true;

                            const scheduleForCurrentVideo = function() {
                                if (!window.tdsIsYouTube() || !window.tdsYoutubeAutoFitEnabled) { return; }
                                const video = document.querySelector('video');
                                if (video) {
                                    window.tdsAutoFitYouTubeWhenReady(video);
                                }
                            };

                            ['yt-navigate-finish', 'yt-page-data-updated', 'DOMContentLoaded', 'load'].forEach(eventName => {
                                window.addEventListener(eventName, scheduleForCurrentVideo, true);
                                document.addEventListener(eventName, scheduleForCurrentVideo, true);
                            });

                            const originalPushState = history.pushState;
                            history.pushState = function() {
                                const result = originalPushState.apply(this, arguments);
                                setTimeout(scheduleForCurrentVideo, 250);
                                return result;
                            };

                            const originalReplaceState = history.replaceState;
                            history.replaceState = function() {
                                const result = originalReplaceState.apply(this, arguments);
                                setTimeout(scheduleForCurrentVideo, 250);
                                return result;
                            };

                            window.addEventListener('popstate', () => setTimeout(scheduleForCurrentVideo, 250), true);
                            setTimeout(scheduleForCurrentVideo, 500);
                            setTimeout(scheduleForCurrentVideo, 1500);
                        };

                        window.tdsScheduleFitPasses = function() {
                            [0, 100, 250, 500, 1000, 1800, 3000].forEach(delay => {
                                setTimeout(() => {
                                    if (window.tdsCssFullscreenElement) {
                                        window.tdsApplyCssFullscreenLayout(window.tdsCssFullscreenElement);
                                        window.tdsDisableYouTubeCaptions();
                                    }
                                }, delay);
                            });
                        };

                        window.tdsApplyCssFullscreenLayout = function(target) {
                            if (!target) { return; }

                            window.tdsInstallFullscreenStyles();
                            document.documentElement.classList.add('tds-carplay-video-fit');
                            document.body.classList.add('tds-carplay-video-fit');
                            target.classList.add('tds-carplay-video-target');

                            target.style.position = 'fixed';
                            target.style.left = '0';
                            target.style.top = '0';
                            target.style.right = '0';
                            target.style.bottom = '0';
                            target.style.width = '100vw';
                            target.style.height = '100vh';
                            target.style.minWidth = '100vw';
                            target.style.minHeight = '100vh';
                            target.style.maxWidth = '100vw';
                            target.style.maxHeight = '100vh';
                            target.style.margin = '0';
                            target.style.padding = '0';
                            target.style.zIndex = '2147483647';
                            target.style.background = 'black';
                            target.style.transform = 'none';
                            target.style.overflow = 'hidden';

                            target.querySelectorAll('.html5-video-container, .ytp-player-content, [data-testid*="player" i], [data-testid*="media" i], [class*="player" i], [class*="media" i], [class*="playback" i], [class*="video" i]').forEach(container => {
                                if (!('tdsOriginalFitStyle' in container.dataset)) {
                                    container.dataset.tdsOriginalFitStyle = container.getAttribute('style') || '';
                                }
                                container.style.position = 'absolute';
                                container.style.left = '0';
                                container.style.top = '0';
                                container.style.right = '0';
                                container.style.bottom = '0';
                                container.style.width = '100%';
                                container.style.height = '100%';
                                container.style.minWidth = '100%';
                                container.style.minHeight = '100%';
                                container.style.maxWidth = '100%';
                                container.style.maxHeight = '100%';
                                container.style.transform = 'none';
                                container.style.overflow = 'hidden';
                            });

                            target.querySelectorAll('video, .html5-main-video').forEach(video => {
                                window.tdsFitVideoElement(video);
                            });
                            if (document.activeElement && document.activeElement.blur) {
                                document.activeElement.blur();
                            }
                            window.tdsDisableYouTubeCaptions();
                        };

                        window.tdsFitVideoElement = function(video) {
                            if (!video) { return; }

                            if (!('tdsOriginalFitStyle' in video.dataset)) {
                                video.dataset.tdsOriginalFitStyle = video.getAttribute('style') || '';
                            }
                            const scale = Math.min(Math.max(Number(window.tdsYoutubeFitScale) || 1, 1), 1.35);
                            video.style.setProperty('position', 'absolute', 'important');
                            video.style.setProperty('left', '0', 'important');
                            video.style.setProperty('top', '0', 'important');
                            video.style.setProperty('right', '0', 'important');
                            video.style.setProperty('bottom', '0', 'important');
                            video.style.setProperty('width', '100%', 'important');
                            video.style.setProperty('height', '100%', 'important');
                            video.style.setProperty('min-width', '100%', 'important');
                            video.style.setProperty('min-height', '100%', 'important');
                            video.style.setProperty('max-width', '100%', 'important');
                            video.style.setProperty('max-height', '100%', 'important');
                            video.style.setProperty('object-fit', 'contain', 'important');
                            video.style.setProperty('object-position', 'center center', 'important');
                            video.style.setProperty('transform', 'scale(' + scale + ')', 'important');
                            video.style.setProperty('transform-origin', 'center center', 'important');
                        };

                        window.tdsDisableYouTubeCaptions = function() {
                            document.querySelectorAll('.ytp-caption-window-container, .caption-window, .ytp-caption-segment, .captions-text').forEach(element => {
                                element.style.display = 'none';
                                element.style.visibility = 'hidden';
                                element.style.opacity = '0';
                            });

                            const captionsButton = document.querySelector('.ytp-subtitles-button[aria-pressed="true"], .ytp-subtitles-button.ytp-button[aria-pressed="true"]');
                            if (captionsButton) {
                                captionsButton.click();
                            }
                        };

                        window.tdsEnterCssFullscreen = function(element) {
                            if (!element) { return false; }

                            const target = window.tdsIsYouTube() ?
                                window.tdsFindYouTubePlayer(element) :
                                window.tdsFindGenericVideoFullscreenTarget(element);
                            if (!('tdsOriginalStyle' in target.dataset)) {
                                target.dataset.tdsOriginalStyle = target.getAttribute('style') || '';
                            }

                            window.tdsPostFullscreenRequest(element, target);
                            target.dataset.tdsCssFullscreen = 'true';
                            window.tdsCssFullscreenElement = target;
                            window.tdsApplyCssFullscreenLayout(target);
                            window.tdsDisableYouTubeCaptions();
                            window.scrollTo(0, 0);
                            window.tdsScheduleFitPasses();
                            window.tdsDispatchFullscreenChange();
                            return true;
                        };

                        window.tdsExitCssFullscreen = function() {
                            const targets = Array.from(document.querySelectorAll(
                                '[data-tds-css-fullscreen="true"], .tds-carplay-video-target'
                            ));
                            if (window.tdsCssFullscreenElement && !targets.includes(window.tdsCssFullscreenElement)) {
                                targets.push(window.tdsCssFullscreenElement);
                            }

                            targets.forEach(target => {
                                target.classList.remove('tds-carplay-video-target');
                                target.setAttribute('style', target.dataset.tdsOriginalStyle || '');
                                delete target.dataset.tdsCssFullscreen;
                                delete target.dataset.tdsOriginalStyle;
                            });

                            document.querySelectorAll('[data-tds-original-fit-style]').forEach(element => {
                                element.setAttribute('style', element.dataset.tdsOriginalFitStyle || '');
                                delete element.dataset.tdsOriginalFitStyle;
                            });

                            document.documentElement.classList.remove('tds-carplay-video-fit');
                            document.body.classList.remove('tds-carplay-video-fit');
                            window.tdsCssFullscreenElement = null;
                            window.tdsDispatchFullscreenChange();
                        };

                        const tdsNativeExitFullscreen = document.exitFullscreen;
                        document.exitFullscreen = function() {
                            if (window.tdsCssFullscreenElement) {
                                window.tdsExitCssFullscreen();
                                return Promise.resolve();
                            }

                            return tdsNativeExitFullscreen ? tdsNativeExitFullscreen.call(document) : Promise.resolve();
                        };

                        window.tdsRequestVideoFullscreen = function(video) {
                            if (!video) {
                                return;
                            }

                            try {
                                window.tdsEnterCssFullscreen(video);
                            } catch (error) {
                                console.log("TDS fullscreen request failed", error);
                                window.tdsEnterCssFullscreen(video);
                            }
                        };

                        window.tdsClickCurrentPlayerFullscreenButton = function() {
                            function isUsable(element) {
                                if (!element) { return false; }
                                const rect = element.getBoundingClientRect();
                                const style = window.getComputedStyle(element);
                                return rect.width > 0 &&
                                    rect.height > 0 &&
                                    style.display !== 'none' &&
                                    style.visibility !== 'hidden' &&
                                    Number(style.opacity || '1') > 0.05 &&
                                    !element.disabled &&
                                    element.getAttribute('aria-disabled') !== 'true';
                            }

                            function clickElement(element) {
                                if (!element) { return false; }
                                const rect = element.getBoundingClientRect();
                                const x = rect.left + rect.width / 2;
                                const y = rect.top + rect.height / 2;
                                ['pointerdown', 'mousedown', 'pointerup', 'mouseup'].forEach(type => {
                                    element.dispatchEvent(new MouseEvent(type, {
                                        bubbles: true,
                                        cancelable: true,
                                        view: window,
                                        clientX: x,
                                        clientY: y
                                    }));
                                });
                                element.click();
                                return true;
                            }

                            function revealControls(element) {
                                if (!element) { return; }
                                const rect = element.getBoundingClientRect();
                                const x = rect.left + rect.width / 2;
                                const y = rect.top + rect.height / 2;
                                ['mousemove', 'mouseover', 'pointermove', 'touchstart'].forEach(type => {
                                    try {
                                        if (type === 'touchstart') {
                                            element.dispatchEvent(new TouchEvent(type, { bubbles: true, cancelable: true }));
                                        } else {
                                            element.dispatchEvent(new MouseEvent(type, {
                                                bubbles: true,
                                                cancelable: true,
                                                view: window,
                                                clientX: x,
                                                clientY: y
                                            }));
                                        }
                                    } catch (_) {
                                        element.dispatchEvent(new MouseEvent('mousemove', {
                                            bubbles: true,
                                            cancelable: true,
                                            view: window,
                                            clientX: x,
                                            clientY: y
                                        }));
                                    }
                                });
                            }

                            const video = document.querySelector('video');
                            const firstRoot = video?.closest('[data-player], [class*="player"], [class*="Player"], [class*="media"], [class*="Media"], [class*="playback"], [class*="Playback"], [class*="video"], [class*="Video"], figure, article, section, div') || document;
                            revealControls(video || firstRoot);
                            const selectors = [
                                'button[aria-label*="full screen" i]',
                                'button[aria-label*="fullscreen" i]',
                                'button[aria-label*="full-screen" i]',
                                'button[aria-label*="expand" i]',
                                'button[title*="full screen" i]',
                                'button[title*="fullscreen" i]',
                                'button[title*="full-screen" i]',
                                'button[title*="expand" i]',
                                '[role="button"][aria-label*="full screen" i]',
                                '[role="button"][aria-label*="fullscreen" i]',
                                '[role="button"][aria-label*="expand" i]',
                                '[data-testid*="fullscreen" i]',
                                '[data-testid*="full-screen" i]',
                                '[data-testid*="expand" i]',
                                '[class*="fullscreen" i]',
                                '[class*="full-screen" i]',
                                '[class*="fullScreen" i]',
                                '[class*="expand" i]',
                                '.ytp-fullscreen-button'
                            ];

                            const roots = [];
                            let root = firstRoot;
                            while (root && root !== document.documentElement && root !== document.body) {
                                roots.push(root);
                                root = root.parentElement;
                            }
                            roots.push(document);

                            for (const searchRoot of roots) {
                                revealControls(searchRoot);
                                const button = selectors
                                    .flatMap(selector => Array.from(searchRoot.querySelectorAll ? searchRoot.querySelectorAll(selector) : []))
                                    .filter(isUsable)
                                    .find(element => {
                                        const label = [
                                            element.className,
                                            element.getAttribute('aria-label'),
                                            element.getAttribute('title'),
                                            element.innerText,
                                            element.textContent
                                        ].join(' ').toLowerCase();
                                        return label.includes('full') || label.includes('screen') || label.includes('expand');
                                    });

                                if (button && clickElement(button)) {
                                    return true;
                                }
                            }

                            return false;
                        };

                        window.tdsForceLargestPlayerFullscreen = function() {
                            const selectors = [
                                'video',
                                '[data-player]',
                                '[data-testid*="player" i]',
                                '[data-testid*="media" i]',
                                '[class*="player" i]',
                                '[class*="media" i]',
                                '[class*="playback" i]',
                                '[class*="video" i]',
                                '[id*="player" i]',
                                '[id*="media" i]'
                            ];

                            const candidates = selectors
                                .flatMap(selector => Array.from(document.querySelectorAll(selector)))
                                .filter(element => {
                                    const rect = element.getBoundingClientRect();
                                    const style = window.getComputedStyle(element);
                                    const tag = element.tagName.toLowerCase();
                                    return rect.width > 200 &&
                                        rect.height > 100 &&
                                        rect.right > 0 &&
                                        rect.bottom > 0 &&
                                        rect.left < window.innerWidth &&
                                        rect.top < window.innerHeight &&
                                        style.display !== 'none' &&
                                        style.visibility !== 'hidden' &&
                                        tag !== 'header' &&
                                        tag !== 'nav';
                                })
                                .sort((a, b) => {
                                    const ar = a.getBoundingClientRect();
                                    const br = b.getBoundingClientRect();
                                    return (br.width * br.height) - (ar.width * ar.height);
                                });

                            const video = document.querySelector('video');
                            const target = video?.closest('[data-player], [data-testid*="player" i], [class*="player" i], [class*="media" i], [class*="playback" i], [class*="video" i], section, article, div') ||
                                candidates[0] ||
                                video;

                            if (!target) {
                                return false;
                            }

                            if (!target.dataset.tdsOriginalStyle) {
                                target.dataset.tdsOriginalStyle = target.getAttribute('style') || '';
                            }
                            target.dataset.tdsCssFullscreen = 'true';
                            window.tdsCssFullscreenElement = target;
                            window.tdsApplyCssFullscreenLayout(target);
                            window.scrollTo(0, 0);
                            window.tdsScheduleFitPasses();
                            window.tdsDispatchFullscreenChange();
                            return true;
                        };

                        window.tdsPreventFullscreen = function(event) {
                            if (window.tdsIsYouTube() && window.tdsYoutubeFullscreenEnabled) {
                                return;
                            }

                            if (event && event.stopPropagation) {
                                event.stopPropagation();
                            }
                            console.log("Attempted to enter fullscreen, but blocked.");
                        };

                        window.tdsConfigureVideoElement = function(video) {
                            if (!video || video.dataset.tdsConfigured === "true") {
                                return;
                            }

                            video.dataset.tdsConfigured = "true";
                            video.addEventListener('click', function() {
                                window.tdsRequestVideoFullscreen(video);
                            }, true);

                            window.tdsApplyVideoFullscreenMode(video);
                            window.tdsDisableYouTubeCaptions();
                        };

                        window.tdsApplyVideoFullscreenMode = function(video) {
                            if (!video) { return; }

                            if (window.tdsIsYouTube() && window.tdsYoutubeFullscreenEnabled) {
                                video.setAttribute('playsinline', 'true');
                                video.setAttribute('webkit-playsinline', 'true');
                                video.setAttribute('x5-playsinline', 'true');
                                video.setAttribute('x-webkit-airplay', 'allow');
                                video.removeAttribute('fullscreen');
                                video.removeAttribute('allowfullscreen');
                                document.querySelectorAll('iframe').forEach(iframe => {
                                    iframe.removeAttribute('allowfullscreen');
                                    const allow = iframe.getAttribute('allow') || '';
                                    const filteredAllow = allow
                                        .split(';')
                                        .map(value => value.trim())
                                        .filter(value => value && value !== 'fullscreen')
                                        .join('; ');
                                    iframe.setAttribute('allow', filteredAllow);
                                });
                                return;
                            }

                            window.tdsExitCssFullscreen();
                            video.setAttribute('playsinline', 'true');
                            video.setAttribute('webkit-playsinline', 'true');
                            video.setAttribute('x5-playsinline', 'true');
                            video.setAttribute('x-webkit-airplay', 'allow');
                            video.removeAttribute('fullscreen');
                            video.removeAttribute('allowfullscreen');
                        };

                        window.tdsApplyFullscreenPreference = function(enabled) {
                            window.tdsYoutubeFullscreenEnabled = enabled;
                            document.querySelectorAll('video').forEach(video => {
                                window.tdsApplyVideoFullscreenMode(video);
                            });
                            window.tdsDisableYouTubeCaptions();
                        };

                        window.tdsApplyAutoFitPreference = function(enabled) {
                            window.tdsYoutubeAutoFitEnabled = enabled;
                            if (enabled) {
                                window.tdsScheduleAutoFitNow();
                            } else {
                                window.clearTimeout(window.tdsAutoFitTimer);
                            }
                        };

                        window.tdsApplyFitScale = function(scale) {
                            window.tdsYoutubeFitScale = Math.min(Math.max(Number(scale) || 1, 1), 1.35);
                            if (window.tdsCssFullscreenElement) {
                                window.tdsApplyCssFullscreenLayout(window.tdsCssFullscreenElement);
                            }
                        };

                        window.tdsApplyAutoFitDelay = function(delay) {
                            window.tdsYoutubeAutoFitDelay = delay;
                        };

                        document.querySelectorAll('video').forEach(video => {
                            window.tdsConfigureVideoElement(video);
                            ['loadedmetadata', 'loadeddata', 'canplay', 'play', 'playing'].forEach(eventName => {
                                video.addEventListener(eventName, () => window.tdsAutoFitYouTubeWhenReady(video), { passive: true });
                            });
                            window.tdsAutoFitYouTubeWhenReady(video);
                        });

                        // Watch for new video elements being added to the DOM
                        let observer = new MutationObserver(mutations => {
                            mutations.forEach(mutation => {
                                mutation.addedNodes.forEach(node => {
                                    if (node.tagName === "VIDEO") {
                                        window.tdsConfigureVideoElement(node);
                                        ['loadedmetadata', 'loadeddata', 'canplay', 'play', 'playing'].forEach(eventName => {
                                            node.addEventListener(eventName, () => window.tdsAutoFitYouTubeWhenReady(node), { passive: true });
                                        });
                                        window.tdsAutoFitYouTubeWhenReady(node);
                                    } else if (node.querySelectorAll) {
                                        node.querySelectorAll('video').forEach(video => {
                                            window.tdsConfigureVideoElement(video);
                                            ['loadedmetadata', 'loadeddata', 'canplay', 'play', 'playing'].forEach(eventName => {
                                                video.addEventListener(eventName, () => window.tdsAutoFitYouTubeWhenReady(video), { passive: true });
                                            });
                                            window.tdsAutoFitYouTubeWhenReady(video);
                                        });
                                    }
                                });
                            });
                        });

                        observer.observe(document, { childList: true, subtree: true });
                        window.tdsInstallYouTubeAutoFitHooks();
                    })();


                (function() {
                        function isYouTube() {
                            return window.location.hostname.includes('youtube.com');
                        }

                        function hideElementsById(ids) {
                            ids.forEach(id => {
                                let element = document.getElementById(id);
                                if (element) {
                                    element.style.display = 'none';
                                    console.log('Hid element:', id);
                                }
                            });
                        }

                        function init() {
                            if (isYouTube()) {
                                document.querySelectorAll('video').forEach(video => {
                                    window.tdsConfigureVideoElement(video);
                                });

                                console.log('YouTube detected, ready to hide elements');

                                // Example: Add IDs here that you want to hide
                                let idsToHide = [
                                    'masthead-container', // Top navigation bar
                                    'secondary', // Sidebar
                                    'survey', // Comments section
                                    'below', // Related videos
                                    'chat', // Live chat on streams
                                    'masthead-ad' // YouTube ads
                                ];

                                hideElementsById(idsToHide);

                                // Observe for new elements being added
                                let observer = new MutationObserver(() => {
                                    hideElementsById(idsToHide);
                                });

                                observer.observe(document, { childList: true, subtree: true });
                            }
                        }

                                    init();
                    })();




        """

        let userScript = WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        let contentController = WKUserContentController()
        contentController.addUserScript(userScript)
        contentController.add(self, name: "tdsFullscreenRequested")
        contentController.add(self, name: "tdsYouTubeNavigation")
        contentController.add(self, name: "tdsYouTubePickerStatus")
        config.userContentController = contentController



        webView = WKWebView(frame: containerView!.bounds, configuration: config)
//        webView!.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        webView!.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Safari/605.1.15"
#if DEBUG
        webView!.isInspectable = true
#endif

        webView!.scrollView.showsHorizontalScrollIndicator = false
        webView!.scrollView.showsVerticalScrollIndicator = false
        webView!.navigationDelegate = self
        webView!.uiDelegate = self
        webView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView!.addSubview(webView!)

        // Initialize and configure the cursor image view
        let cursorImage = UIImage(named: "Cursor") // Replace with your cursor image name
        cursorImageView = UIImageView(image: cursorImage)
        cursorImageView!.frame = CGRect(x: 100, y: 100, width: 30, height: 30) // Set initial position and size
        self.view.addSubview(cursorImageView!)
    }




    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !IsIncar {
            applyIOSLayoutForBrowser()
        }
    }

    func CarViewDidLoad(_ window: UIWindow?) {
        CPwindow = window
        applyCurrentOffsetForBrowser()
        if let currentURL = CustomWebViewController.shared.webView?.url?.absoluteString,
           let domain = extractDomain(from: currentURL) {

            CustomWebViewController.shared.cursorImageView?.isHidden = true
            print("Current URL: \(currentURL)")

            if applySavedSettings(forDomain: domain) {
                print("Applied settings for \(domain): \(containerView?.frame.debugDescription ?? "none")")
            } else {
                print("No saved settings found for \(domain)")
            }
        }
    }

    override func loadViewIncar(_ window: UIWindow?) -> CarPlayViewControllerProtocol {
        for subview in window!.subviews {
            subview.removeFromSuperview()
            print(subview)
        }

         window?.isUserInteractionEnabled = true
         window?.rootViewController = UIViewController()
         window?.rootViewController?.view.isUserInteractionEnabled = true

         // Use the shared instance of CustomWebViewController
         let webViewController = self
//         guard let webViewController = self.webViewController else { return }

         // Properly add the CustomWebViewController's view to the window
         if let rootViewController = window?.rootViewController {
             CustomWebViewController.shared.IsIncar = true
             rootViewController.addChild(webViewController)
             rootViewController.view.addSubview(webViewController.view)
             webViewController.view.frame = rootViewController.view.bounds
             webViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
             webViewController.didMove(toParent: rootViewController)
             webViewController.CarViewDidLoad(window)
             webViewController.installCarPlayGestureLogging(rootView: rootViewController.view)
             webViewController.updateCarPlayBrowserStandby(in: rootViewController.view)
//             webViewController.view.isUserInteractionEnabled = true
         }
        return webViewController
    }

    private func installCarPlayGestureLogging(rootView: UIView) {
        loadViewIfNeeded()

        let targets: [(String, UIView?)] = [
            ("root", rootView),
            ("controller", view),
            ("container", containerView),
            ("webView", webView),
            ("webScroll", webView?.scrollView)
        ]

        targets.forEach { label, view in
            guard let view else { return }
            view.isUserInteractionEnabled = true
            removeCarPlayGestureLoggers(from: view)

            let tap = UITapGestureRecognizer(target: self, action: #selector(logCarPlayTap(_:)))
            configureCarPlayGestureLogger(tap, label: label, kind: "tap")
            view.addGestureRecognizer(tap)

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(logCarPlayTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            configureCarPlayGestureLogger(doubleTap, label: label, kind: "doubleTap")
            view.addGestureRecognizer(doubleTap)
            tap.require(toFail: doubleTap)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(logCarPlayPan(_:)))
            configureCarPlayGestureLogger(pan, label: label, kind: "pan")
            view.addGestureRecognizer(pan)
        }

        print("TDS CarPlay gesture logging installed")
    }

    private func configureCarPlayGestureLogger(_ gesture: UIGestureRecognizer, label: String, kind: String) {
        gesture.name = "\(carPlayGestureLoggerPrefix).\(label).\(kind)"
        gesture.cancelsTouchesInView = false
        gesture.delaysTouchesBegan = false
        gesture.delaysTouchesEnded = false
        gesture.delegate = self
    }

    private func removeCarPlayGestureLoggers(from view: UIView) {
        view.gestureRecognizers?
            .filter { $0.name?.hasPrefix(carPlayGestureLoggerPrefix) == true }
            .forEach { view.removeGestureRecognizer($0) }
    }

    @objc private func logCarPlayTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended, let view = gesture.view else { return }
        let point = gesture.location(in: view)
        let windowPoint = gesture.location(in: CPwindow)
        print("TDS CarPlay gesture tap name=\(gesture.name ?? "unknown") taps=\(gesture.numberOfTapsRequired) point=\(point) windowPoint=\(windowPoint)")
    }

    @objc private func logCarPlayPan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let point = gesture.location(in: view)
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let state: String

        switch gesture.state {
        case .began:
            state = "began"
        case .changed:
            state = "changed"
        case .ended:
            state = "ended"
        case .cancelled:
            state = "cancelled"
        case .failed:
            state = "failed"
        case .possible:
            state = "possible"
        @unknown default:
            state = "unknown"
        }

        print("TDS CarPlay gesture pan name=\(gesture.name ?? "unknown") state=\(state) point=\(point) translation=\(translation) velocity=\(velocity)")
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.name?.hasPrefix(carPlayGestureLoggerPrefix) == true {
            return true
        }
        if otherGestureRecognizer.name?.hasPrefix(carPlayGestureLoggerPrefix) == true {
            return true
        }
        return false
    }


    func loadURL(_ url: URL) {
        loadViewIfNeeded()
        browserStandbyView?.isHidden = true
        applyYouTubePageZoom(for: url)
        let request = URLRequest(url: url)
        webView?.load(request)
    }

    func searchYouTube(
        for query: String,
        completion: @escaping (Result<[TDSYouTubeSearchResult], Error>) -> Void
    ) {
        loadViewIfNeeded()
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty,
              UserDefaults.standard.bool(forKey: Self.youtubePickerSearchEnabledKey),
              UserDefaults.standard.object(forKey: Self.youtubeCustomPickerEnabledKey) as? Bool ?? true,
              isYouTubeURL(webView?.url),
              let webView else {
            completion(.success([]))
            return
        }

        Task { @MainActor in
            do {
                let value = try await webView.callAsyncJavaScript(
                    """
                    if (typeof window.tdsSearchYouTubeForCarPlay !== 'function') {
                        throw new Error('YouTube search is not ready');
                    }
                    return await window.tdsSearchYouTubeForCarPlay(query);
                    """,
                    arguments: ["query": trimmedQuery],
                    in: nil,
                    contentWorld: .page
                )
                let rows = value as? [[String: Any]] ?? []
                let items = rows.compactMap { row -> TDSYouTubeSearchResult? in
                    guard let id = row["id"] as? String,
                          let title = row["title"] as? String,
                          let urlString = row["url"] as? String,
                          let videoURL = URL(string: urlString, relativeTo: Self.youtubeURL)?.absoluteURL else {
                        return nil
                    }
                    let thumbnailString = row["thumbnail"] as? String
                    return TDSYouTubeSearchResult(
                        id: id,
                        title: title,
                        channel: row["channel"] as? String ?? "",
                        details: row["details"] as? String ?? "",
                        thumbnailURL: thumbnailString.flatMap(URL.init(string:)),
                        videoURL: videoURL
                    )
                }
                completion(.success(items))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func loadYouTubeRecommendations(
        completion: @escaping (Result<[TDSYouTubeSearchResult], Error>) -> Void
    ) {
        loadViewIfNeeded()
        guard UserDefaults.standard.object(forKey: Self.youtubeCustomPickerEnabledKey) as? Bool ?? true,
              UserDefaults.standard.bool(forKey: Self.youtubeNativeRecommendationsEnabledKey),
              isYouTubeURL(webView?.url),
              let webView else {
            completion(.success([]))
            return
        }

        Task { @MainActor in
            do {
                let value = try await webView.callAsyncJavaScript(
                    """
                    if (typeof window.tdsYouTubeRecommendationsForCarPlay !== 'function') {
                        throw new Error('YouTube recommendations are not ready');
                    }
                    return await window.tdsYouTubeRecommendationsForCarPlay();
                    """,
                    arguments: [:],
                    in: nil,
                    contentWorld: .page
                )
                completion(.success(Self.youtubeVideoItems(from: value)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func youtubeVideoItems(from value: Any?) -> [TDSYouTubeSearchResult] {
        let rows = value as? [[String: Any]] ?? []
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let title = row["title"] as? String,
                  let urlString = row["url"] as? String,
                  let videoURL = URL(string: urlString, relativeTo: youtubeURL)?.absoluteURL else {
                return nil
            }
            let thumbnailString = row["thumbnail"] as? String
            return TDSYouTubeSearchResult(
                id: id,
                title: title,
                channel: row["channel"] as? String ?? "",
                details: row["details"] as? String ?? "",
                thumbnailURL: thumbnailString.flatMap(URL.init(string:)),
                videoURL: videoURL
            )
        }
    }

    private func updateCarPlayBrowserStandby(in rootView: UIView) {
        browserStandbyView?.removeFromSuperview()
        guard webView?.url == nil else { return }

        let standby = TDSBrowserStandbyView()
        standby.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(standby)
        NSLayoutConstraint.activate([
            standby.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            standby.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            standby.topAnchor.constraint(equalTo: rootView.topAnchor),
            standby.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
        ])
        browserStandbyView = standby
    }

    // Function to move the cursor up
    func moveCursorUp(by amount: CGFloat) {
        guard let cursorImageView = self.cursorImageView else { return }
        let newCenter = CGPoint(x: cursorImageView.center.x, y: cursorImageView.center.y - amount)
        UIView.animate(withDuration: 0.3) {
            cursorImageView.center = newCenter
        }
    }

    // Function to move the cursor down
    func moveCursorDown(by amount: CGFloat) {
        guard let cursorImageView = self.cursorImageView else { return }
        let newCenter = CGPoint(x: cursorImageView.center.x, y: cursorImageView.center.y + amount)
        UIView.animate(withDuration: 0.3) {
            cursorImageView.center = newCenter
        }
    }

    // Function to move the cursor left
    func moveCursorLeft(by amount: CGFloat) {
        guard let cursorImageView = self.cursorImageView else { return }
        let newCenter = CGPoint(x: cursorImageView.center.x - amount, y: cursorImageView.center.y)
        UIView.animate(withDuration: 0.3) {
            cursorImageView.center = newCenter
        }
    }

    // Function to move the cursor right
    func moveCursorRight(by amount: CGFloat) {
        guard let cursorImageView = self.cursorImageView else { return }
        let newCenter = CGPoint(x: cursorImageView.center.x + amount, y: cursorImageView.center.y)
        UIView.animate(withDuration: 0.3) {
            cursorImageView.center = newCenter
        }
    }

    // Function to select (click) the element at the cursor position
    func select() {
        guard let cursorImageView = self.cursorImageView else { return }
        guard let webView = self.webView else { return }

        // Convert cursor position to webView's coordinate system
        let cursorPointInView = cursorImageView.center
        let cursorPointInWebView = webView.convert(cursorPointInView, from: self.view)

        let js = """
        (function() {
            const x = \(Int(cursorPointInWebView.x));
            const y = \(Int(cursorPointInWebView.y));
            const element = document.elementFromPoint(x, y);
            if (!element) { return 'No element at ' + x + ',' + y; }
            ['mouseover', 'mousedown', 'mouseup', 'click'].forEach(function(type) {
                element.dispatchEvent(new MouseEvent(type, {
                    bubbles: true,
                    cancelable: true,
                    view: window,
                    clientX: x,
                    clientY: y
                }));
            });
            if (element.focus) { element.focus(); }
            return 'Clicked ' + element.tagName + (element.id ? '#' + element.id : '') + (element.className ? '.' + String(element.className).replace(/\\s+/g, '.') : '');
        })();
        """
        webView.evaluateJavaScript(js) { result, error in
            if let error {
                print("TDS CarPlay cursor click failed: \(error.localizedDescription)")
            } else {
                print("TDS CarPlay cursor click result: \(String(describing: result))")
            }
        }
    }

    // Function to scroll the web view
    func scrollBy(x: CGFloat, y: CGFloat) {
        let js = """
        (function() {
            const deltaX = \(x);
            const deltaY = \(y);
            const centerX = Math.max(0, Math.floor(window.innerWidth / 2));
            const centerY = Math.max(0, Math.floor(window.innerHeight / 2));
            const startElement = document.elementFromPoint(centerX, centerY) || document.activeElement || document.scrollingElement || document.body;

            if (startElement) {
                startElement.dispatchEvent(new WheelEvent('wheel', {
                    bubbles: true,
                    cancelable: true,
                    deltaX: deltaX,
                    deltaY: deltaY,
                    clientX: centerX,
                    clientY: centerY
                }));
            }

            let element = startElement;
            while (element && element !== document.body && element !== document.documentElement) {
                const canScrollX = element.scrollWidth > element.clientWidth;
                const canScrollY = element.scrollHeight > element.clientHeight;
                if (canScrollX || canScrollY) {
                    element.scrollBy(deltaX, deltaY);
                    return 'element ' + element.tagName + ' x=' + element.scrollLeft + ' y=' + element.scrollTop;
                }
                element = element.parentElement;
            }

            const scrollingElement = document.scrollingElement || document.documentElement || document.body;
            scrollingElement.scrollBy(deltaX, deltaY);
            window.scrollBy(deltaX, deltaY);
            return 'window x=' + window.scrollX + ' y=' + window.scrollY;
        })();
        """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("TDS CarPlay web scroll failed: \(error.localizedDescription)")
            } else {
                print("TDS CarPlay web scroll dx=\(x) dy=\(y) result=\(String(describing: result))")
            }
        }
    }

    func resizeContent(by scale: CGFloat) {
        zoomScale *= scale
        applyContentZoom()
    }

    // Function to resize the container view
    func resize(by scale: CGFloat) {
        // Ensure scale is positive
        guard scale > 0 else { return }

        guard let containerView = containerView else { return }
        // Get the current frame of the container view
        var currentFrame = containerView.frame

        // Calculate the new width and height
        let newWidth = currentFrame.width * scale
        let newHeight = currentFrame.height * scale

        // Optionally, maintain the center of the container view
        let currentCenter = containerView.center

        // Set the new frame size
        currentFrame.size = CGSize(width: newWidth, height: newHeight)
        containerView.frame = currentFrame

        // Optionally, set the center back to the original
        containerView.center = currentCenter
        webView?.frame = containerView.bounds
    }

    // Function to reset the zoom level to 1
    func resetZoom() {
        zoomScale = 1.0
        applyContentZoom()
        applyCurrentOffsetForBrowser()
    }

    func reloadPage() {
        zoomScale = 1.0
        let js = "document.location.reload();"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    // Toggle hidden cursor
    func toggleCursor() {
        guard let cursorImageView = self.cursorImageView else { return }
        if cursorImageView.isHidden {
            UIView.animate(withDuration: 0.3) {
                cursorImageView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                cursorImageView.isHidden = true
            }
        }
    }

    // WKUIDelegate method to prevent full-screen video playback
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return nil
    }

    // WKUIDelegate method to handle JavaScript alerts
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func moveHorizontally(by offset: CGFloat) {
        guard let containerView = containerView else { return }
        var currentFrame = containerView.frame
        currentFrame.origin.x += offset
        containerView.frame = currentFrame
        webView?.frame = containerView.bounds
        print(containerView.frame)
    }

    func moveVertically(by offset: CGFloat) {
        guard let containerView = containerView else { return }
        var currentFrame = containerView.frame
        currentFrame.origin.y += offset
        containerView.frame = currentFrame
        webView?.frame = containerView.bounds
        print(containerView.frame)
    }

    private func applyContentZoom() {
        // YouTube browse and playback zoom are managed separately. A saved
        // page-wide body zoom otherwise compounds with the browse grid scale.
        let effectiveZoom = isYouTubeURL(webView?.url) ? 1.0 : zoomScale
        let js = "document.body.style.zoom = '\(effectiveZoom)'"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func applyCurrentOffsetForBrowser() {
        let bounds = CPwindow?.bounds ?? view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        view.frame = bounds
        containerView?.frame = frame(for: bounds, offset: ScreenCaptureManager.shared.Screenoffset)
        webView?.frame = containerView?.bounds ?? bounds
        cursorImageView?.isHidden = false
    }

    func applyIOSLayoutForBrowser() {
        CPwindow = nil
        IsIncar = false

        let bounds = view.bounds
        guard bounds.width > 0, bounds.height > 0 else { return }

        view.frame = bounds
        containerView?.frame = bounds
        webView?.frame = containerView?.bounds ?? bounds
        cursorImageView?.isHidden = true
        print("Applied iOS browser layout: \(bounds)")
    }

    private func frame(for bounds: CGRect, offset: SingleEdgeOffset) -> CGRect {
        offset.insetRect(in: bounds)
    }

    // Prevent YouTube app from opening
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let urlString = url.absoluteString
            print("Attempting to load: \(urlString)")

            if navigationAction.targetFrame?.isMainFrame != false {
                applyYouTubePageZoom(for: url)
            }

            if IsIncar, isDirectPlayableMediaURL(url) {
                TDSVideoShared.shared.CarPlayComp?(.init(type: .video, URL: url))
                decisionHandler(.cancel)
                return
            }

            if navigationAction.navigationType == .linkActivated {
                // If the URL is a YouTube link, ensure it loads in the web view
                if urlString.contains("youtube.com") || urlString.contains("youtu.be") {
                    decisionHandler(.cancel)
                    webView.load(navigationAction.request)
                    return
                }
            }

            // Prevent external apps from opening
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
    // Print URL when it changes
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                browserStandbyView?.isHidden = true
                if let currentURL = webView.url?.absoluteString {
                    print("Page Loaded: \(currentURL)")
                    if let domain = extractDomain(from: currentURL) {
                        _ = applySavedSettings(forDomain: domain)
                    }
                    applyYouTubePageZoom(for: webView.url)
                    if isYouTubeURL(webView.url) {
                        webView.evaluateJavaScript("""
                            (function() {
                                try {
                                    if (typeof window.tdsInstallYouTubePicker !== 'function') {
                                        return 'picker script unavailable';
                                    }
                                    window.tdsInstallYouTubePicker();
                                    return window.tdsYouTubePickerInstalled ?
                                        'picker installed' :
                                        'picker waiting for document';
                                } catch (error) {
                                    return 'picker exception: ' +
                                        (error?.name || 'Error') + ': ' +
                                        (error?.message || String(error)) +
                                        (error?.stack ? '\\n' + error.stack : '');
                                }
                            })();
                            """) { result, error in
                                if let error {
                                    print("TDS YouTube picker bootstrap failed: \(error.localizedDescription)")
                                } else {
                                    print("TDS YouTube picker bootstrap: \(String(describing: result))")
                                }
                            }
                        scheduleYouTubeAutoFitNow()
                    }
                }
            }





    func saveZoomSettings(_ settings: ZoomSettings, forDomain domain: String) {
        var allSettings = loadAllZoomSettings()
        allSettings[domain] = settings

        if let data = try? JSONEncoder().encode(allSettings) {
            UserDefaults.standard.set(data, forKey: "DomainZoomSettings")
        }
    }

    func loadZoomSettings(forDomain domain: String) -> ZoomSettings? {
        let allSettings = loadAllZoomSettings()
        return allSettings[domain]
    }

    func loadAllZoomSettings() -> [String: ZoomSettings] {
        if let data = UserDefaults.standard.data(forKey: "DomainZoomSettings"),
           let settings = try? JSONDecoder().decode([String: ZoomSettings].self, from: data) {
            return settings
        }
        return [:]
    }
    func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return url.host
    }


    func saveViewSettings() {
        guard let url = webView?.url, let domain = extractDomain(from: url.absoluteString),
              let containerView = containerView else { return }

        let frame = containerView.frame
        let referenceBounds = CPwindow?.bounds ?? view.bounds
        guard referenceBounds.width > 0, referenceBounds.height > 0 else { return }

        let settings = ZoomSettings(
            widthMultiplier: frame.width / referenceBounds.width,
            heightMultiplier: frame.height / referenceBounds.height,
            originX: frame.origin.x,
            originY: frame.origin.y,
            originXMultiplier: frame.origin.x / referenceBounds.width,
            originYMultiplier: frame.origin.y / referenceBounds.height,
            contentZoom: zoomScale,
            offsetRawValue: ScreenCaptureManager.shared.Screenoffset.rawValue
        )
        saveZoomSettings(settings, forDomain: domain)
        print("Settings saved for \(domain)")
    }

    @discardableResult
    func applySavedSettingsForCurrentDomain() -> Bool {
        guard let url = webView?.url, let domain = extractDomain(from: url.absoluteString) else {
            applyCurrentOffsetForBrowser()
            return false
        }

        return applySavedSettings(forDomain: domain)
    }

    func deleteSettingsForCurrentDomain() {
        guard let url = webView?.url, let domain = extractDomain(from: url.absoluteString) else { return }
        var allSettings = loadAllZoomSettings()
        allSettings.removeValue(forKey: domain)

        if let data = try? JSONEncoder().encode(allSettings) {
            UserDefaults.standard.set(data, forKey: "DomainZoomSettings")
        }

        applyCurrentOffsetForBrowser()
    }

    private func applySavedSettings(forDomain domain: String) -> Bool {
        guard let settings = loadZoomSettings(forDomain: domain),
              let containerView = containerView else { return false }

        let currentOffsetRawValue = ScreenCaptureManager.shared.Screenoffset.rawValue
        if let savedOffsetRawValue = settings.offsetRawValue,
           savedOffsetRawValue != currentOffsetRawValue {
            print("Skipped saved settings for \(domain): saved offset \(savedOffsetRawValue) does not match current offset \(currentOffsetRawValue)")
            applyCurrentOffsetForBrowser()
            return false
        }

        let referenceBounds = CPwindow?.bounds ?? view.bounds
        guard referenceBounds.width > 0, referenceBounds.height > 0 else { return false }

        containerView.frame = CGRect(
            x: referenceBounds.width * (settings.originXMultiplier ?? (settings.originX / referenceBounds.width)),
            y: referenceBounds.height * (settings.originYMultiplier ?? (settings.originY / referenceBounds.height)),
            width: max(1, referenceBounds.width * settings.widthMultiplier),
            height: max(1, referenceBounds.height * settings.heightMultiplier)
        )
        webView?.frame = containerView.bounds
        zoomScale = settings.contentZoom ?? 1.0
        applyContentZoom()
        return true
    }

    func saveCurrentURLAsQuickSelect() {
        guard let url = webView?.url else { return }
        addQuickSelect(title: titleForQuickSelect(url), url: url)
    }

    func addQuickSelect(title: String, url: URL) {
        var quickSelects = loadQuickSelects()
        let cleanURLString = url.absoluteString
        quickSelects.removeAll { $0.urlString == cleanURLString }
        quickSelects.insert(WebQuickSelect(id: UUID(), title: title, urlString: cleanURLString), at: 0)

        if quickSelects.count > 20 {
            quickSelects = Array(quickSelects.prefix(20))
        }

        saveQuickSelects(quickSelects)
    }

    func loadQuickSelects() -> [WebQuickSelect] {
        guard let data = UserDefaults.standard.data(forKey: quickSelectsKey),
              let quickSelects = try? JSONDecoder().decode([WebQuickSelect].self, from: data) else {
            return [
                WebQuickSelect(id: UUID(), title: "YouTube", urlString: Self.youtubeURL.absoluteString),
                WebQuickSelect(id: UUID(), title: "Google", urlString: "https://google.com")
            ]
        }

        return quickSelects
    }

    func deleteQuickSelect(_ quickSelect: WebQuickSelect) {
        var quickSelects = loadQuickSelects()
        quickSelects.removeAll { $0.id == quickSelect.id || $0.urlString == quickSelect.urlString }
        saveQuickSelects(quickSelects)
    }

    private func saveQuickSelects(_ quickSelects: [WebQuickSelect]) {
        if let data = try? JSONEncoder().encode(quickSelects) {
            UserDefaults.standard.set(data, forKey: quickSelectsKey)
        }
    }

    private func titleForQuickSelect(_ url: URL) -> String {
        if let host = url.host, !host.isEmpty {
            return host.replacingOccurrences(of: "www.", with: "")
        }

        return url.absoluteString
    }

    func playCurrentPageVideoInCustomPlayer() {
        let js = """
        (function() {
            const video = document.querySelector('video');
            if (!video) { return null; }
            return video.currentSrc || video.src || null;
        })();
        """

        webView?.evaluateJavaScript(js) { result, error in
            guard
                error == nil,
                let urlString = result as? String,
                !urlString.isEmpty,
                !urlString.hasPrefix("blob:"),
                let url = URL(string: urlString)
            else {
                print("No reusable page video URL found for custom player")
                return
            }

            TDSVideoShared.shared.CarPlayComp?(.init(type: .video, URL: url))
        }
    }

    func playYouTubeVideoWhenReady() {
        let delays: [TimeInterval] = [0.6, 1.2, 2.0, 3.5, 5.0]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self, self.isYouTubeURL(self.webView?.url) else { return }
                let js = """
                (function() {
                    const video = document.querySelector('video');
                    const moviePlayer = document.querySelector('#movie_player');
                    if (!video && !moviePlayer) { return 'waiting for player'; }
                    if (moviePlayer && typeof moviePlayer.playVideo === 'function') {
                        moviePlayer.playVideo();
                    } else if (video) {
                        const result = video.play();
                        if (result && typeof result.catch === 'function') {
                            result.catch(error => console.log('TDS native selection play failed', error));
                        }
                    }
                    if (window.tdsFitCurrentYouTubeVideo) {
                        window.tdsFitCurrentYouTubeVideo();
                    }
                    return 'play requested';
                })();
                """
                self.webView?.evaluateJavaScript(js) { result, error in
                    if let error {
                        print("TDS selected YouTube video play failed: \(error.localizedDescription)")
                    } else {
                        print("TDS selected YouTube video play result: \(String(describing: result))")
                    }
                }
            }
        }
    }

    func toggleCurrentPageVideoPlayback() {
        let js = """
        (function() {
            function isVisible(element) {
                if (!element) { return false; }
                const rect = element.getBoundingClientRect();
                const style = window.getComputedStyle(element);
                return rect.width > 0 &&
                    rect.height > 0 &&
                    rect.bottom > 0 &&
                    rect.right > 0 &&
                    rect.top < window.innerHeight &&
                    rect.left < window.innerWidth &&
                    style.display !== 'none' &&
                    style.visibility !== 'hidden' &&
                    Number(style.opacity || '1') > 0.05;
            }

            function clickElement(element, restoreScrollAfterClick) {
                if (!element) { return false; }
                const scrollingElement = document.scrollingElement || document.documentElement || document.body;
                const originalScroll = {
                    windowX: window.scrollX,
                    windowY: window.scrollY,
                    elementX: scrollingElement ? scrollingElement.scrollLeft : 0,
                    elementY: scrollingElement ? scrollingElement.scrollTop : 0
                };
                const hadToScroll = !isVisible(element);

                if (hadToScroll) {
                    element.scrollIntoView({ block: 'center', inline: 'center', behavior: 'instant' });
                }

                const rect = element.getBoundingClientRect();
                const x = rect.left + rect.width / 2;
                const y = rect.top + rect.height / 2;
                ['pointerdown', 'mousedown', 'pointerup', 'mouseup'].forEach(type => {
                    element.dispatchEvent(new MouseEvent(type, {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        clientX: x,
                        clientY: y
                    }));
                });
                element.click();

                if (restoreScrollAfterClick && hadToScroll) {
                    setTimeout(() => {
                        if (scrollingElement) {
                            scrollingElement.scrollLeft = originalScroll.elementX;
                            scrollingElement.scrollTop = originalScroll.elementY;
                        }
                        window.scrollTo(originalScroll.windowX, originalScroll.windowY);
                    }, 250);
                }

                return true;
            }

            function isUsable(element) {
                if (!element) { return false; }
                const rect = element.getBoundingClientRect();
                const style = window.getComputedStyle(element);
                return rect.width > 0 &&
                    rect.height > 0 &&
                    style.display !== 'none' &&
                    style.visibility !== 'hidden' &&
                    Number(style.opacity || '1') > 0.05 &&
                    !element.disabled &&
                    element.getAttribute('aria-disabled') !== 'true';
            }

            function findPageStartButton(root) {
                const startSelectors = [
                    '.play-cta__inner--button',
                    '.play-cta__inner',
                    'button.play-cta__inner',
                    'button[aria-label^="Play " i]',
                    'button[aria-label*="play" i]',
                    '[role="button"][aria-label*="play" i]',
                    '[data-testid*="play" i]',
                    '[class*="play-cta" i]',
                    '[class*="play-button" i]',
                    '[class*="play_button" i]',
                    'button[class*="play" i]'
                ];

                const candidates = startSelectors
                    .flatMap(selector => Array.from((root || document).querySelectorAll ? (root || document).querySelectorAll(selector) : []))
                    .filter(isUsable);

                return candidates.find(isVisible) || candidates[0];
            }

            function describeElement(element) {
                if (!element) { return 'nil'; }
                const rect = element.getBoundingClientRect();
                const text = (element.innerText || element.textContent || '')
                    .trim()
                    .replace(/\\s+/g, ' ')
                    .slice(0, 80);
                return [
                    element.tagName.toLowerCase(),
                    element.id ? '#' + element.id : '',
                    element.className ? '.' + String(element.className).trim().replace(/\\s+/g, '.') : '',
                    element.getAttribute('role') ? ' role=' + element.getAttribute('role') : '',
                    element.getAttribute('aria-label') ? ' aria=' + element.getAttribute('aria-label') : '',
                    text ? ' text=' + text : '',
                    ' rect=' + Math.round(rect.left) + ',' + Math.round(rect.top) + ',' + Math.round(rect.width) + 'x' + Math.round(rect.height)
                ].join('');
            }

            function playbackDiagnostics() {
                const visibleButtons = Array.from(document.querySelectorAll('button, [role="button"], a'))
                    .filter(isVisible)
                    .slice(0, 30)
                    .map(describeElement);
                const playCandidates = Array.from(document.querySelectorAll('button, [role="button"], a, [class*="play" i], [aria-label*="play" i]'))
                    .filter(isUsable)
                    .filter(element => {
                        const label = [
                            element.className,
                            element.getAttribute('aria-label'),
                            element.getAttribute('title'),
                            element.innerText,
                            element.textContent
                        ].join(' ').toLowerCase();
                        return label.includes('play') || label.includes('watch') || label.includes('episode');
                    })
                    .slice(0, 30)
                    .map(describeElement);
                const iframes = Array.from(document.querySelectorAll('iframe'))
                    .map(frame => {
                        const rect = frame.getBoundingClientRect();
                        return (frame.src || 'iframe-without-src') + ' rect=' + Math.round(rect.left) + ',' + Math.round(rect.top) + ',' + Math.round(rect.width) + 'x' + Math.round(rect.height);
                    })
                    .slice(0, 10);
                return {
                    href: window.location.href,
                    hostname: window.location.hostname,
                    videos: document.querySelectorAll('video').length,
                    visibleButtons: visibleButtons,
                    playCandidates: playCandidates,
                    iframes: iframes
                };
            }

            function schedulePostStartVideoFit() {
                [700, 1500, 2800, 4500].forEach(delay => {
                    setTimeout(() => {
                        const startedVideo = document.querySelector('video');
                        if (!startedVideo) { return; }

                        if (window.tdsClickCurrentPlayerFullscreenButton && window.tdsClickCurrentPlayerFullscreenButton()) {
                            return;
                        }

                        if (window.tdsForceLargestPlayerFullscreen && window.tdsForceLargestPlayerFullscreen()) {
                            return;
                        }

                        if (window.tdsRequestVideoFullscreen) {
                            window.tdsRequestVideoFullscreen(startedVideo);
                        } else if (window.tdsApplyVideoFullscreenMode) {
                            window.tdsApplyVideoFullscreenMode(startedVideo);
                        }
                    }, delay);
                });
            }

            const videos = Array.from(document.querySelectorAll('video'))
                .filter(video => {
                    const rect = video.getBoundingClientRect();
                    return rect.width > 20 &&
                        rect.height > 20 &&
                        rect.bottom > 0 &&
                        rect.right > 0 &&
                        rect.top < window.innerHeight &&
                        rect.left < window.innerWidth;
                });
            const video = videos.find(candidate => !candidate.paused) || videos[0];
            if (!video) {
                const startButton = findPageStartButton(document);
                if (startButton && clickElement(startButton, true)) {
                    schedulePostStartVideoFit();
                    return 'Clicked page start button: ' + describeElement(startButton);
                }

                return 'No video found diagnostics=' + JSON.stringify(playbackDiagnostics());
            }
            let wasPaused = video.paused;
            const player = video.closest('#movie_player, [data-player], [class*="player"], [class*="Player"], [class*="video"], [class*="Video"], figure, article, section, div') || document;

            function refreshVideoLayout() {
                if (window.tdsDisableYouTubeCaptions) {
                    window.tdsDisableYouTubeCaptions();
                }

                if (window.tdsCssFullscreenElement && window.tdsApplyCssFullscreenLayout) {
                    window.tdsApplyCssFullscreenLayout(window.tdsCssFullscreenElement);
                } else if (window.tdsFitCurrentYouTubeVideo) {
                    window.tdsFitCurrentYouTubeVideo();
                }

                if (window.tdsScheduleFitPasses) {
                    window.tdsScheduleFitPasses();
                }
            }

            if (window.tdsIsYouTube && window.tdsIsYouTube()) {
                const moviePlayer = document.querySelector('#movie_player');
                if (moviePlayer && typeof moviePlayer.getPlayerState === 'function') {
                    const playerState = moviePlayer.getPlayerState();
                    if (playerState === 1 || playerState === 3) {
                        wasPaused = false;
                    } else if (playerState === 2 || playerState === 5 || playerState === 0 || playerState === -1) {
                        wasPaused = true;
                    }
                }

                const desiredPaused = !wasPaused;
                const token = Date.now();
                window.__tdsLastYouTubePlaybackRequest = {
                    token: token,
                    desiredPaused: desiredPaused
                };

                function enforceYouTubeState() {
                    const request = window.__tdsLastYouTubePlaybackRequest;
                    if (!request || request.token !== token) { return; }

                    if (request.desiredPaused) {
                        if (moviePlayer && typeof moviePlayer.pauseVideo === 'function') {
                            moviePlayer.pauseVideo();
                        }
                        video.pause();
                    } else if (moviePlayer && typeof moviePlayer.playVideo === 'function') {
                        moviePlayer.playVideo();
                    } else {
                        const playResult = video.play();
                        if (playResult && typeof playResult.catch === 'function') {
                            playResult.catch(error => console.log('TDS YouTube play failed', error));
                        }
                    }
                }

                if (moviePlayer) {
                    if (!desiredPaused && typeof moviePlayer.playVideo === 'function') {
                        enforceYouTubeState();
                        return 'YouTube playVideo state=' + (typeof moviePlayer.getPlayerState === 'function' ? moviePlayer.getPlayerState() : 'unknown');
                    }

                    if (desiredPaused && typeof moviePlayer.pauseVideo === 'function') {
                        enforceYouTubeState();
                        [120, 350, 800].forEach(delay => setTimeout(enforceYouTubeState, delay));
                        return 'YouTube pauseVideo state=' + (typeof moviePlayer.getPlayerState === 'function' ? moviePlayer.getPlayerState() : 'unknown');
                    }
                }

                if (!desiredPaused) {
                    enforceYouTubeState();
                    return 'YouTube video.play';
                }

                enforceYouTubeState();
                [120, 350, 800].forEach(delay => setTimeout(enforceYouTubeState, delay));
                return 'YouTube video.pause';
            }

            const buttonSelectors = wasPaused ? [
                '.ytp-play-button',
                '.play-cta__inner--button',
                '.play-cta__inner',
                'button[aria-label^="Play " i]',
                '[data-testid*="play" i]',
                '[aria-label*="play" i]',
                '[title*="play" i]',
                '[class*="play-cta" i]',
                'button[class*="play" i]'
            ] : [
                '.ytp-play-button',
                '[data-testid*="pause" i]',
                '[aria-label*="pause" i]',
                '[title*="pause" i]',
                'button[class*="pause" i]'
            ];

            const button = buttonSelectors
                .flatMap(selector => Array.from(player.querySelectorAll ? player.querySelectorAll(selector) : []))
                .find(isVisible);

            if (button && clickElement(button, false)) {
                if (!window.tdsIsYouTube || !window.tdsIsYouTube()) {
                    refreshVideoLayout();
                    [100, 300, 700, 1200].forEach(delay => setTimeout(refreshVideoLayout, delay));
                }
                return wasPaused ? 'Clicked page play button' : 'Clicked page pause button';
            }

            if (wasPaused) {
                if (window.tdsApplyVideoFullscreenMode) {
                    window.tdsApplyVideoFullscreenMode(video);
                }
                const playResult = video.play();
                if (playResult && typeof playResult.catch === 'function') {
                    playResult.catch(error => console.log('TDS play failed', error));
                }
                refreshVideoLayout();
                [100, 300, 700, 1200].forEach(delay => setTimeout(refreshVideoLayout, delay));
                return 'Play';
            }

            video.pause();
            refreshVideoLayout();
            return 'Pause';
        })();
        """

        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("TDS CarPlay play/pause failed: \(error.localizedDescription)")
            } else {
                print("TDS CarPlay play/pause result: \(String(describing: result))")
            }
        }
    }

    func focusPreviousYouTubeItem() {
        runYouTubeItemSelection(action: "previous")
    }

    func focusNextYouTubeItem() {
        runYouTubeItemSelection(action: "next")
    }

    func selectFocusedYouTubeItem() {
        runYouTubeItemSelection(action: "select")
    }

    private func runYouTubeItemSelection(action: String) {
        let js = """
        (function() {
            const action = '\(action)';
            const marker = 'data-tds-carplay-selected-video';
            const styleId = 'tds-carplay-youtube-selection-style';

            if (!document.getElementById(styleId)) {
                const style = document.createElement('style');
                style.id = styleId;
                style.textContent = `
                    [data-tds-carplay-selected-video="true"] {
                        outline: 6px solid #00e5ff !important;
                        outline-offset: 4px !important;
                        box-shadow: 0 0 0 8px rgba(0, 229, 255, 0.35) !important;
                        border-radius: 8px !important;
                    }
                `;
                document.documentElement.appendChild(style);
            }

            function normaliseUrl(url) {
                try {
                    const parsed = new URL(url, window.location.href);
                    if (parsed.pathname === '/watch') {
                        return parsed.pathname + '?v=' + parsed.searchParams.get('v');
                    }
                    return parsed.pathname;
                } catch (_) {
                    return url;
                }
            }

            function isVisible(element) {
                const rect = element.getBoundingClientRect();
                const style = window.getComputedStyle(element);
                return rect.width > 40 &&
                    rect.height > 30 &&
                    rect.bottom > 0 &&
                    rect.right > 0 &&
                    rect.top < window.innerHeight &&
                    rect.left < window.innerWidth &&
                    style.visibility !== 'hidden' &&
                    style.display !== 'none' &&
                    Number(style.opacity || '1') > 0.05;
            }

            const picker = document.getElementById('tds-youtube-picker');
            const pickerIsVisible = picker && !picker.hasAttribute('hidden');
            const candidates = pickerIsVisible ?
                picker.querySelectorAll('a.tds-video-card') :
                document.querySelectorAll('a[href*="/watch"], a[href*="/shorts/"]');

            const seen = new Set();
            let anchors = Array.from(candidates)
                .filter(anchor => {
                    if (!anchor.href || !anchor.isConnected) { return false; }
                    if (!pickerIsVisible && !isVisible(anchor)) { return false; }
                    const key = normaliseUrl(anchor.href);
                    if (seen.has(key)) { return false; }
                    seen.add(key);
                    return true;
                });

            // Custom cards are already in API/grid order: six across, then the
            // next row. Native YouTube links still need visual-position sorting.
            if (!pickerIsVisible) {
                anchors = anchors.sort((a, b) => {
                    const ar = a.getBoundingClientRect();
                    const br = b.getBoundingClientRect();
                    return (ar.top - br.top) || (ar.left - br.left);
                });
            }

            if (!anchors.length) {
                return pickerIsVisible ?
                    'The custom YouTube view is still loading recommendations' :
                    'No visible YouTube video links found';
            }

            let index = anchors.findIndex(anchor =>
                normaliseUrl(anchor.href) === window.tdsCarPlayYouTubeSelectedVideo
            );
            if (index < 0) {
                index = Number(window.tdsCarPlayYouTubeItemIndex);
            }
            if (!Number.isInteger(index) || index < 0 || index >= anchors.length) {
                index = action === 'previous' ? 0 : -1;
            }

            if (action === 'next') {
                index = (index + 1) % anchors.length;
            } else if (action === 'previous') {
                index = (index - 1 + anchors.length) % anchors.length;
            } else if (action === 'select') {
                index = Math.min(anchors.length - 1, Math.max(0, index));
            }

            window.tdsCarPlayYouTubeItemIndex = index;

            document.querySelectorAll('[' + marker + '="true"]').forEach(element => {
                element.removeAttribute(marker);
            });

            const target = anchors[index];
            target.setAttribute(marker, 'true');
            window.tdsCarPlayYouTubeSelectedVideo = normaliseUrl(target.href);
            target.focus({ preventScroll: true });
            target.scrollIntoView({ block: 'nearest', inline: 'nearest', behavior: 'auto' });

            const title =
                target.getAttribute('aria-label') ||
                target.title ||
                target.textContent.trim().replace(/\\s+/g, ' ').slice(0, 80) ||
                target.href;
            const gridPosition = pickerIsVisible ?
                ' row=' + (Math.floor(index / 6) + 1) + ' column=' + ((index % 6) + 1) :
                '';

            if (action === 'select') {
                ['mouseover', 'mousedown', 'mouseup', 'click'].forEach(type => {
                    target.dispatchEvent(new MouseEvent(type, {
                        bubbles: true,
                        cancelable: true,
                        view: window
                    }));
                });
                target.click();
                return 'Selected ' + (index + 1) + '/' + anchors.length +
                    gridPosition + ': ' + title;
            }

            return 'Focused ' + (index + 1) + '/' + anchors.length +
                gridPosition + ': ' + title;
        })();
        """

        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("TDS CarPlay YouTube \(action) failed: \(error.localizedDescription)")
            } else {
                print("TDS CarPlay YouTube \(action) result: \(String(describing: result))")
            }
        }
    }

    func setYouTubeFullscreenEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.youtubeFullscreenEnabledKey)
        let js = "window.tdsApplyFullscreenPreference && window.tdsApplyFullscreenPreference(\(enabled ? "true" : "false"));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func setYouTubeAutoFitEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.youtubeAutoFitEnabledKey)
        let js = "window.tdsApplyAutoFitPreference && window.tdsApplyAutoFitPreference(\(enabled ? "true" : "false"));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func setYouTubeCustomPickerEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.youtubeCustomPickerEnabledKey)
        NotificationCenter.default.post(name: Self.youtubePickerSearchPreferenceDidChange, object: nil)
        let js = """
            window.tdsApplyYouTubePickerPreference ?
                window.tdsApplyYouTubePickerPreference(\(enabled ? "true" : "false")) :
                'YouTube picker script unavailable';
            """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("TDS YouTube picker preference failed: \(error.localizedDescription)")
            } else {
                print("TDS YouTube picker preference: \(String(describing: result))")
            }
        }
        applyYouTubePageZoom(for: webView?.url)
    }

    func setYouTubePickerSearchEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.youtubePickerSearchEnabledKey)
        NotificationCenter.default.post(name: Self.youtubePickerSearchPreferenceDidChange, object: nil)
        let js = """
            window.tdsApplyYouTubePickerSearchPreference ?
                window.tdsApplyYouTubePickerSearchPreference(\(enabled ? "true" : "false")) :
                'YouTube picker search script unavailable';
            """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("TDS YouTube picker search preference failed: \(error.localizedDescription)")
            } else {
                print("TDS YouTube picker search preference: \(String(describing: result))")
            }
        }
    }

    func setYouTubeNativeRecommendationsEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Self.youtubeNativeRecommendationsEnabledKey)
        NotificationCenter.default.post(name: Self.youtubePickerSearchPreferenceDidChange, object: nil)
    }

    func setYouTubeFitScale(_ scale: Double) {
        let clampedScale = min(max(scale, Self.youtubeFitScaleRange.lowerBound), Self.youtubeFitScaleRange.upperBound)
        UserDefaults.standard.set(clampedScale, forKey: Self.youtubeFitScaleKey)
        let js = "window.tdsApplyFitScale && window.tdsApplyFitScale(\(clampedScale));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func adjustYouTubeFitScale(by amount: Double) {
        let currentScale = UserDefaults.standard.object(forKey: Self.youtubeFitScaleKey) as? Double ?? Self.youtubeFitScaleDefault
        setYouTubeFitScale(currentScale + amount)
    }

    func setYouTubeAutoFitDelay(_ delay: Double) {
        UserDefaults.standard.set(delay, forKey: Self.youtubeAutoFitDelayKey)
        let js = "window.tdsApplyAutoFitDelay && window.tdsApplyAutoFitDelay(\(delay));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func scheduleYouTubeAutoFitNow() {
        let enabled = UserDefaults.standard.object(forKey: Self.youtubeAutoFitEnabledKey) as? Bool ?? true
        let fullscreenEnabled = UserDefaults.standard.object(forKey: Self.youtubeFullscreenEnabledKey) as? Bool ?? true
        let scale = UserDefaults.standard.object(forKey: Self.youtubeFitScaleKey) as? Double ?? Self.youtubeFitScaleDefault
        let delay = UserDefaults.standard.object(forKey: Self.youtubeAutoFitDelayKey) as? Double ?? 3.0
        let js = """
        (function() {
            if (window.tdsApplyFullscreenPreference) { window.tdsApplyFullscreenPreference(\(fullscreenEnabled ? "true" : "false")); }
            if (window.tdsApplyAutoFitPreference) { window.tdsApplyAutoFitPreference(\(enabled ? "true" : "false")); }
            if (window.tdsApplyFitScale) { window.tdsApplyFitScale(\(scale)); }
            if (window.tdsApplyAutoFitDelay) { window.tdsApplyAutoFitDelay(\(delay)); }
            if (window.tdsScheduleAutoFitNow) { return window.tdsScheduleAutoFitNow(); }
            return false;
        })();
        """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("YouTube delayed fit schedule failed: \(error.localizedDescription)")
            } else {
                print("YouTube delayed fit scheduled: \(String(describing: result))")
            }
        }
    }

    func requestYouTubeFullscreenNow() {
        let js = """
        (function() {
            const video = document.querySelector('video');
            if (!video) { return false; }
            window.tdsRequestVideoFullscreen(video);
            return true;
        })();
        """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("YouTube fullscreen request failed: \(error.localizedDescription)")
            } else {
                print("YouTube fullscreen requested: \(String(describing: result))")
            }
        }
    }

    func inspectCurrentVideoOverlays(completion: @escaping (String) -> Void) {
        let js = """
        (function() {
            try {
            const inspectorVersion = 2;
            document.querySelectorAll('[data-tds-overlay-inspection]').forEach(element => {
                element.style.removeProperty('outline');
                element.style.removeProperty('outline-offset');
                delete element.dataset.tdsOverlayInspection;
            });

            const video = document.querySelector('video');
            if (!video) { return 'No video element found'; }

            const rect = video.getBoundingClientRect();
            if (rect.width <= 0 || rect.height <= 0) { return 'Video has no visible bounds'; }

            const points = [];
            [0.1, 0.25, 0.5, 0.75, 0.9].forEach(xFraction => {
                [0.1, 0.25, 0.5, 0.75, 0.9].forEach(yFraction => {
                    points.push([
                        rect.left + rect.width * xFraction,
                        rect.top + rect.height * yFraction
                    ]);
                });
            });

            const elements = [];
            const seen = new Set();
            points.forEach(point => {
                document.elementsFromPoint(point[0], point[1]).forEach(element => {
                    if (!seen.has(element)) {
                        seen.add(element);
                        elements.push(element);
                    }
                });
            });

            function selectorFor(element) {
                const id = element.id ? '#' + element.id : '';
                const classes = Array.from(element.classList || []).slice(0, 4).map(value => '.' + value).join('');
                return element.tagName.toLowerCase() + id + classes;
            }

            const candidates = elements
                .filter(element => element !== video && element.tagName !== 'HTML' && element.tagName !== 'BODY')
                .map((element, stackIndex) => {
                    const style = getComputedStyle(element);
                    const elementRect = element.getBoundingClientRect();
                    return {
                        element,
                        stackIndex,
                        selector: selectorFor(element),
                        position: style.position,
                        display: style.display,
                        visibility: style.visibility,
                        zIndex: style.zIndex,
                        background: style.backgroundColor,
                        opacity: style.opacity,
                        filter: style.filter,
                        backdropFilter: style.backdropFilter || style.webkitBackdropFilter || 'none',
                        size: Math.round(elementRect.width) + 'x' + Math.round(elementRect.height)
                    };
                })
                .filter(item => {
                    const hasBlur = item.filter !== 'none' || item.backdropFilter !== 'none';
                    const positionedOverlay = ['fixed', 'sticky', 'absolute'].includes(item.position);
                    const hasBackground = item.background !== 'rgba(0, 0, 0, 0)' && item.background !== 'transparent';
                    return hasBlur || positionedOverlay || hasBackground || item.stackIndex < 4;
                })
                .slice(0, 15);

            candidates.forEach(item => {
                item.element.dataset.tdsOverlayInspection = 'true';
                item.element.style.setProperty('outline', '3px solid #ff2d55', 'important');
                item.element.style.setProperty('outline-offset', '-3px', 'important');
            });

            const report = candidates.map((item, index) =>
                (index + 1) + '. ' + item.selector +
                ' position=' + item.position +
                ' display=' + item.display +
                ' visibility=' + item.visibility +
                ' z=' + item.zIndex +
                ' size=' + item.size +
                ' background=' + item.background +
                ' opacity=' + item.opacity +
                ' filter=' + item.filter +
                ' backdrop=' + item.backdropFilter
            );
            console.table(candidates.map(item => ({
                selector: item.selector,
                position: item.position,
                display: item.display,
                visibility: item.visibility,
                zIndex: item.zIndex,
                size: item.size,
                background: item.background,
                opacity: item.opacity,
                filter: item.filter,
                backdropFilter: item.backdropFilter
            })));
            return report.length ? 'TDS overlay inspector v' + inspectorVersion + '\\n' + report.join('\\n') :
                'TDS overlay inspector v' + inspectorVersion + ': No overlay candidates found above the video';
            } catch (error) {
                return 'Inspector JavaScript error: ' + (error?.message || String(error)) +
                    (error?.stack ? '\\n' + error.stack : '');
            }
        })();
        """

        webView?.evaluateJavaScript(js) { result, error in
            let report: String
            if let error {
                let details = (error as NSError).userInfo
                report = "Overlay inspection failed: \(error.localizedDescription) details=\(details)"
            } else {
                report = result as? String ?? "Overlay inspection returned no report"
            }
            print("TDS video overlay inspection:\n\(report)")
            DispatchQueue.main.async {
                completion(report)
            }
        }
    }

    func clearVideoOverlayInspection() {
        let js = """
        document.querySelectorAll('[data-tds-overlay-inspection]').forEach(element => {
            element.style.removeProperty('outline');
            element.style.removeProperty('outline-offset');
            delete element.dataset.tdsOverlayInspection;
        });
        """
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func fitCurrentPageVideoToCurrentView() {
        let scale = UserDefaults.standard.object(forKey: Self.youtubeFitScaleKey) as? Double ?? Self.youtubeFitScaleDefault
        let js = """
        (function() {
            if (window.tdsApplyFitScale) { window.tdsApplyFitScale(\(scale)); }
            const video = document.querySelector('video');
            if (video && window.tdsClickCurrentPlayerFullscreenButton && window.tdsClickCurrentPlayerFullscreenButton()) {
                return 'clicked-player-fullscreen-button';
            }
            if (window.tdsForceLargestPlayerFullscreen && window.tdsForceLargestPlayerFullscreen()) {
                return 'forced-largest-player-fullscreen';
            }
            if (video && window.tdsRequestVideoFullscreen) {
                window.tdsRequestVideoFullscreen(video);
                return 'requested-css-fullscreen';
            }
            return 'no-video';
        })();
        """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("Generic video fit request failed: \(error.localizedDescription)")
            } else {
                print("Generic video fit requested: \(String(describing: result))")
            }
        }
    }

    func fitYouTubeVideoToCurrentView() {
        let scale = UserDefaults.standard.object(forKey: Self.youtubeFitScaleKey) as? Double ?? Self.youtubeFitScaleDefault
        let js = """
        (function() {
            if (window.tdsApplyFullscreenPreference) { window.tdsApplyFullscreenPreference(\("true")); }
            if (window.tdsApplyFitScale) { window.tdsApplyFitScale(\(scale)); }
            if (window.tdsFitCurrentYouTubeVideo) {
                return window.tdsFitCurrentYouTubeVideo();
            }
            return false;
        })();
        """
        webView?.evaluateJavaScript(js) { result, error in
            if let error {
                print("YouTube fit request failed: \(error.localizedDescription)")
            } else {
                print("YouTube fit requested: \(String(describing: result))")
            }
        }
    }

    private func isDirectPlayableMediaURL(_ url: URL) -> Bool {
        let playableExtensions = ["mp4", "mov", "m4v", "m3u8", "mp3", "aac"]
        let pathExtension = url.pathExtension.lowercased()
        return playableExtensions.contains(pathExtension)
    }

    private func isYouTubeURL(_ url: URL?) -> Bool {
        guard let host = url?.host?.lowercased() else { return false }
        return host.contains("youtube.com") || host.contains("youtu.be")
    }

    private func applyYouTubePageZoom(for url: URL?) {
        guard let webView else { return }
        guard isYouTubeURL(url) else {
            webView.pageZoom = 1.0
            return
        }

        let path = url?.path.lowercased() ?? "/"
        let playbackPaths = ["/watch", "/shorts", "/embed", "/live"]
        let isPlaybackPage = playbackPaths.contains { path == $0 || path.hasPrefix($0 + "/") }
        let customPickerPaths = ["/", "/feed/subscriptions"]
        let customPickerEnabled = UserDefaults.standard.object(
            forKey: Self.youtubeCustomPickerEnabledKey
        ) as? Bool ?? true
        let usesCustomPicker = customPickerEnabled && customPickerPaths.contains(path)

        if !isPlaybackPage {
            webView.evaluateJavaScript(
                """
                window.clearTimeout(window.tdsAutoFitTimer);
                if (window.tdsExitCssFullscreen) {
                    window.tdsExitCssFullscreen();
                }
                """
            ) { _, error in
                if let error {
                    print("TDS YouTube fullscreen cleanup failed: \(error.localizedDescription)")
                }
            }
        }

        webView.pageZoom = (isPlaybackPage || usesCustomPicker) ? 1.0 : Self.youtubeBrowseZoom
        applyContentZoom()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "tdsYouTubePickerStatus" {
            if let status = message.body as? [String: Any] {
                let state = status["state"] as? String ?? "unknown"
                let count = status["count"] as? Int ?? 0
                let detail = status["detail"] as? String ?? ""
                let path = status["path"] as? String ?? ""
                print("TDS YouTube picker status state=\(state) cards=\(count) path=\(path) detail=\(detail)")
            } else {
                print("TDS YouTube picker status: \(message.body)")
            }
            return
        }

        if message.name == "tdsYouTubeNavigation" {
            guard let urlString = message.body as? String,
                  let url = URL(string: urlString) else { return }
            applyYouTubePageZoom(for: url)
            return
        }

        guard message.name == "tdsFullscreenRequested" else { return }

        let currentURL = webView?.url
        print("TDS fullscreen requested: \(message.body)")

        if let currentURL {
            TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: currentURL, reloadWeb: false))
        } else {
            TDSVideoShared.shared.CarPlayComp?(.init(type: .web, URL: nil, reloadWeb: false))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.fitCurrentPageVideoToCurrentView()
        }
    }

}
