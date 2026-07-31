#import "MinimalBrowserWebView.h"

#import <dlfcn.h>
#import <objc/message.h>

static NSString * const kMinimalBrowserWKWebViewClassName = @"WKWebView";
static NSString * const kMinimalBrowserWKWebViewConfigurationClassName = @"WKWebViewConfiguration";
static NSInteger const kMinimalBrowserNavigationPolicyCancel = 0;
static NSInteger const kMinimalBrowserNavigationPolicyAllow = 1;

static void MinimalBrowserEnsureWebKitRuntimeLoaded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (NSClassFromString(kMinimalBrowserWKWebViewClassName) != Nil) {
            return;
        }

        NSArray<NSString *> *candidatePaths = @[
            @"/System/Library/Frameworks/WebKit.framework/WebKit",
            @"/System/Library/PrivateFrameworks/WebKit.framework/WebKit",
            @"/System/Library/StagedFrameworks/Safari/WebKit.framework/WebKit",
        ];

        for (NSString *candidatePath in candidatePaths) {
            if (dlopen(candidatePath.UTF8String, RTLD_NOW | RTLD_GLOBAL) != NULL &&
                NSClassFromString(kMinimalBrowserWKWebViewClassName) != Nil) {
                break;
            }
        }
    });
}

static void MinimalBrowserPumpRunLoopUntil(BOOL *finished) {
    while (!*finished) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                     beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
}

static NSString *MinimalBrowserStringFromJavaScriptResult(id result) {
    if (result == nil || result == [NSNull null]) {
        return nil;
    }
    if ([result isKindOfClass:[NSString class]]) {
        return result;
    }
    if ([result respondsToSelector:@selector(stringValue)]) {
        return [result stringValue];
    }
    return [result description];
}

@interface MinimalBrowserWebView ()

@property (nullable, nonatomic, strong) id runtimeWebView;
@property (nullable, nonatomic, strong) NSURLRequest *lastRequest;
@property (nullable, nonatomic, copy) NSString *lastTitle;
@property (nullable, nonatomic, copy) NSString *userAgent;
@property (nonatomic) BOOL loading;

@end

@implementation MinimalBrowserWebView

- (id)runtimeConfiguration {
    SEL selector = NSSelectorFromString(@"configuration");
    if (self.runtimeWebView == nil || ![self.runtimeWebView respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
}

- (id)runtimeCookieStore {
    id configuration = [self runtimeConfiguration];
    if (configuration == nil) {
        return nil;
    }

    SEL websiteDataStoreSelector = NSSelectorFromString(@"websiteDataStore");
    if (![configuration respondsToSelector:websiteDataStoreSelector]) {
        return nil;
    }

    id websiteDataStore = ((id (*)(id, SEL))objc_msgSend)(configuration, websiteDataStoreSelector);
    if (websiteDataStore == nil) {
        return nil;
    }

    SEL cookieStoreSelector = NSSelectorFromString(@"httpCookieStore");
    if (![websiteDataStore respondsToSelector:cookieStoreSelector]) {
        return nil;
    }

    return ((id (*)(id, SEL))objc_msgSend)(websiteDataStore, cookieStoreSelector);
}

- (NSArray<NSHTTPCookie *> *)cookiesForRequest:(NSURLRequest *)request {
    NSURL *requestURL = request.URL;
    if (requestURL == nil) {
        return @[];
    }

    NSMutableArray<NSHTTPCookie *> *cookies = [NSMutableArray array];
    NSArray<NSHTTPCookie *> *sharedCookies =
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:requestURL] ?: @[];
    [cookies addObjectsFromArray:sharedCookies];

    NSString *cookieHeader = [request valueForHTTPHeaderField:@"Cookie"];
    if (cookieHeader.length > 0) {
        NSDictionary<NSString *, NSString *> *header = @{ @"Set-Cookie": cookieHeader };
        NSArray<NSHTTPCookie *> *requestCookies =
        [NSHTTPCookie cookiesWithResponseHeaderFields:header forURL:requestURL];

        for (NSHTTPCookie *cookie in requestCookies) {
            NSUInteger existingIndex = [cookies indexOfObjectPassingTest:^BOOL(NSHTTPCookie *existingCookie, NSUInteger idx, BOOL *stop) {
                return [existingCookie.name isEqualToString:cookie.name] &&
                [existingCookie.domain isEqualToString:cookie.domain] &&
                [existingCookie.path isEqualToString:cookie.path];
            }];

            if (existingIndex != NSNotFound) {
                [cookies replaceObjectAtIndex:existingIndex withObject:cookie];
            } else {
                [cookies addObject:cookie];
            }
        }
    }

    return cookies;
}

- (void)synchronizeCookiesForRequest:(NSURLRequest *)request {
    id cookieStore = [self runtimeCookieStore];
    NSArray<NSHTTPCookie *> *cookies = [self cookiesForRequest:request];
    if (cookieStore == nil || cookies.count == 0) {
        return;
    }

    SEL setCookieSelector = NSSelectorFromString(@"setCookie:completionHandler:");
    if (![cookieStore respondsToSelector:setCookieSelector]) {
        return;
    }

    for (NSHTTPCookie *cookie in cookies) {
        __block BOOL finished = NO;
        ((void (*)(id, SEL, id, id))objc_msgSend)(cookieStore,
                                                  setCookieSelector,
                                                  cookie,
                                                  ^{
            finished = YES;
        });
        MinimalBrowserPumpRunLoopUntil(&finished);
    }
}

- (NSURLRequest *)requestByApplyingSharedCookiesToRequest:(NSURLRequest *)request {
    if (request == nil) {
        return nil;
    }

    NSArray<NSHTTPCookie *> *cookies = [self cookiesForRequest:request];
    if (cookies.count == 0) {
        return request;
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSDictionary<NSString *, NSString *> *cookieHeaders = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    NSString *cookieHeader = cookieHeaders[@"Cookie"];
    if (cookieHeader.length > 0) {
        [mutableRequest setValue:cookieHeader forHTTPHeaderField:@"Cookie"];
    }

    return [mutableRequest copy];
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithUserAgent:nil allowsInlineMediaPlayback:YES];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    (void)coder;
    return [self initWithUserAgent:nil allowsInlineMediaPlayback:YES];
}

- (instancetype)initWithUserAgent:(NSString *)userAgent
      allowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInitWithUserAgent:userAgent
           allowsInlineMediaPlayback:allowsInlineMediaPlayback];
    }
    return self;
}

- (void)commonInitWithUserAgent:(NSString *)userAgent
     allowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback {
    MinimalBrowserEnsureWebKitRuntimeLoaded();

    self.backgroundColor = UIColor.blackColor;

    Class configurationClass = NSClassFromString(kMinimalBrowserWKWebViewConfigurationClassName);
    Class webViewClass = NSClassFromString(kMinimalBrowserWKWebViewClassName);
    if (configurationClass == Nil || webViewClass == Nil) {
        return;
    }

    id configuration = ((id (*)(id, SEL))objc_msgSend)((id)configurationClass, @selector(new));
    SEL allowsInlineMediaPlaybackSelector = NSSelectorFromString(@"setAllowsInlineMediaPlayback:");
    if ([configuration respondsToSelector:allowsInlineMediaPlaybackSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(configuration,
                                                allowsInlineMediaPlaybackSelector,
                                                allowsInlineMediaPlayback);
    }

    id webViewObject = ((id (*)(id, SEL))objc_msgSend)((id)webViewClass, @selector(alloc));
    SEL initializer = NSSelectorFromString(@"initWithFrame:configuration:");
    webViewObject = ((id (*)(id, SEL, CGRect, id))objc_msgSend)(webViewObject,
                                                                 initializer,
                                                                 self.bounds,
                                                                 configuration);
    if (webViewObject == nil) {
        return;
    }

    self.runtimeWebView = webViewObject;

    UIView *runtimeView = (UIView *)webViewObject;
    runtimeView.frame = self.bounds;
    runtimeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    runtimeView.backgroundColor = UIColor.blackColor;

    SEL navigationDelegateSelector = NSSelectorFromString(@"setNavigationDelegate:");
    if ([webViewObject respondsToSelector:navigationDelegateSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(webViewObject, navigationDelegateSelector, self);
    }

    SEL UIDelegateSelector = NSSelectorFromString(@"setUIDelegate:");
    if ([webViewObject respondsToSelector:UIDelegateSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(webViewObject, UIDelegateSelector, self);
    }

    [self addSubview:runtimeView];
    [self setUserAgent:userAgent];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    ((UIView *)self.runtimeWebView).frame = self.bounds;
}

- (UIScrollView *)scrollView {
    SEL selector = NSSelectorFromString(@"scrollView");
    if (self.runtimeWebView == nil || ![self.runtimeWebView respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
}

- (NSURL *)currentURL {
    SEL selector = NSSelectorFromString(@"URL");
    if (self.runtimeWebView == nil || ![self.runtimeWebView respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
}

- (NSURLRequest *)request {
    NSURL *currentURL = [self currentURL];
    if (currentURL != nil) {
        return [NSURLRequest requestWithURL:currentURL];
    }
    return self.lastRequest;
}

- (NSString *)title {
    SEL selector = NSSelectorFromString(@"title");
    if (self.runtimeWebView == nil || ![self.runtimeWebView respondsToSelector:selector]) {
        return self.lastTitle;
    }
    NSString *title = ((id (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
    return title ?: self.lastTitle;
}

- (BOOL)canGoBack {
    SEL selector = NSSelectorFromString(@"canGoBack");
    if (self.runtimeWebView == nil || ![self.runtimeWebView respondsToSelector:selector]) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
}

- (BOOL)canGoForward {
    SEL selector = NSSelectorFromString(@"canGoForward");
    if (self.runtimeWebView == nil || ![self.runtimeWebView respondsToSelector:selector]) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
}

- (void)loadRequest:(NSURLRequest *)request {
    if (request == nil || self.runtimeWebView == nil) {
        return;
    }

    NSURLRequest *requestWithCookies = [self requestByApplyingSharedCookiesToRequest:request];
    [self synchronizeCookiesForRequest:requestWithCookies];
    self.lastRequest = requestWithCookies;

    SEL selector = NSSelectorFromString(@"loadRequest:");
    if ([self.runtimeWebView respondsToSelector:selector]) {
        ((id (*)(id, SEL, id))objc_msgSend)(self.runtimeWebView, selector, requestWithCookies);
    }
}

- (void)reload {
    SEL selector = NSSelectorFromString(@"reload");
    if (self.runtimeWebView != nil && [self.runtimeWebView respondsToSelector:selector]) {
        ((void (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
    }
}

- (void)goBack {
    SEL selector = NSSelectorFromString(@"goBack");
    if (self.runtimeWebView != nil && [self.runtimeWebView respondsToSelector:selector]) {
        ((id (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
    }
}

- (void)goForward {
    SEL selector = NSSelectorFromString(@"goForward");
    if (self.runtimeWebView != nil && [self.runtimeWebView respondsToSelector:selector]) {
        ((id (*)(id, SEL))objc_msgSend)(self.runtimeWebView, selector);
    }
}

- (NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    if (script.length == 0 || self.runtimeWebView == nil) {
        return nil;
    }

    SEL selector = NSSelectorFromString(@"evaluateJavaScript:completionHandler:");
    if (![self.runtimeWebView respondsToSelector:selector]) {
        return nil;
    }

    __block id evaluationResult = nil;
    __block NSError *evaluationError = nil;
    __block BOOL finished = NO;
    ((void (*)(id, SEL, id, id))objc_msgSend)(self.runtimeWebView,
                                               selector,
                                               script,
                                               ^(id result, NSError *error) {
        evaluationResult = result;
        evaluationError = error;
        finished = YES;
    });
    MinimalBrowserPumpRunLoopUntil(&finished);

    if (evaluationError != nil) {
        return nil;
    }
    return MinimalBrowserStringFromJavaScriptResult(evaluationResult);
}

- (void)setUserAgent:(NSString *)userAgent {
    _userAgent = [userAgent copy];
    SEL selector = NSSelectorFromString(@"setCustomUserAgent:");
    if (self.runtimeWebView != nil && [self.runtimeWebView respondsToSelector:selector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(self.runtimeWebView, selector, _userAgent);
    }
}

- (NSURLRequest *)requestFromNavigationAction:(id)navigationAction {
    if (navigationAction == nil) {
        return nil;
    }
    SEL selector = NSSelectorFromString(@"request");
    if (![navigationAction respondsToSelector:selector]) {
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(navigationAction, selector);
}

- (NSInteger)navigationTypeFromNavigationAction:(id)navigationAction {
    if (navigationAction == nil) {
        return 0;
    }
    SEL selector = NSSelectorFromString(@"navigationType");
    if (![navigationAction respondsToSelector:selector]) {
        return 0;
    }
    return ((NSInteger (*)(id, SEL))objc_msgSend)(navigationAction, selector);
}

- (void)webView:(id)webView didStartProvisionalNavigation:(id)navigation {
    (void)webView;
    (void)navigation;
    self.loading = YES;
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:self];
    }
}

- (void)webView:(id)webView didFinishNavigation:(id)navigation {
    (void)webView;
    (void)navigation;
    self.loading = NO;
    self.lastTitle = [self title];
    self.lastRequest = [self request];
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinishLoad:self];
    }
}

- (void)webView:(id)webView didFailNavigation:(id)navigation withError:(NSError *)error {
    (void)webView;
    (void)navigation;
    self.loading = NO;
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

- (void)webView:(id)webView didFailProvisionalNavigation:(id)navigation withError:(NSError *)error {
    (void)webView;
    (void)navigation;
    self.loading = NO;
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:self didFailLoadWithError:error];
    }
}

- (void)webView:(id)webView
decidePolicyForNavigationAction:(id)navigationAction
decisionHandler:(void (^)(NSInteger policy))decisionHandler {
    (void)webView;
    NSURLRequest *request = [self requestFromNavigationAction:navigationAction];
    NSInteger navigationType = [self navigationTypeFromNavigationAction:navigationAction];

    BOOL shouldAllow = YES;
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        shouldAllow = [self.delegate webView:self
                  shouldStartLoadWithRequest:request
                               navigationType:navigationType];
    }

    if (shouldAllow && request != nil) {
        self.lastRequest = request;
    }

    if (decisionHandler != nil) {
        decisionHandler(shouldAllow ? kMinimalBrowserNavigationPolicyAllow
                                    : kMinimalBrowserNavigationPolicyCancel);
    }
}

- (id)webView:(id)webView
createWebViewWithConfiguration:(id)configuration
forNavigationAction:(id)navigationAction
windowFeatures:(id)windowFeatures {
    (void)webView;
    (void)configuration;
    (void)windowFeatures;

    NSURLRequest *request = [self requestFromNavigationAction:navigationAction];
    if (request != nil) {
        [self loadRequest:request];
    }
    return nil;
}

@end
