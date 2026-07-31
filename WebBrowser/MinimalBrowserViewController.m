#import "MinimalBrowserViewController.h"

@interface MinimalBrowserViewController ()

@property (nullable, nonatomic, copy) NSString *initialURLString;
@property (nonatomic, readwrite) MinimalBrowserWebView *browserView;

@end

@implementation MinimalBrowserViewController

- (instancetype)init {
    return [self initWithURLString:nil];
}

- (instancetype)initWithURLString:(NSString *)URLString {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _initialURLString = [URLString copy];
        _allowsInlineMediaPlayback = YES;
        self.view.backgroundColor = UIColor.blackColor;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.browserView = [[MinimalBrowserWebView alloc] initWithUserAgent:self.userAgent
                                            allowsInlineMediaPlayback:self.allowsInlineMediaPlayback];
    self.browserView.delegate = self;
    self.browserView.frame = self.view.bounds;
    self.browserView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.browserView];

    if (self.initialURLString.length > 0) {
        [self loadURLString:self.initialURLString];
    }
}

- (void)setUserAgent:(NSString *)userAgent {
    _userAgent = [userAgent copy];
    [self.browserView setUserAgent:_userAgent];
}

- (void)loadURLString:(NSString *)URLString {
    NSURLRequest *request = [self requestForUserSuppliedURLString:URLString];
    if (request != nil) {
        [self loadRequest:request];
    }
}

- (void)loadURL:(NSURL *)URL {
    if (URL == nil) {
        return;
    }
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.browserView loadRequest:request];
}

- (void)reload {
    [self.browserView reload];
}

- (void)goBack {
    [self.browserView goBack];
}

- (void)goForward {
    [self.browserView goForward];
}

- (NSString *)evaluateJavaScript:(NSString *)script {
    return [self.browserView stringByEvaluatingJavaScriptFromString:script];
}

- (NSURLRequest *)requestForUserSuppliedURLString:(NSString *)URLString {
    NSString *trimmed = [URLString stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }

    NSString *candidate = trimmed;
    if ([candidate rangeOfString:@"://"].location == NSNotFound) {
        candidate = [@"https://" stringByAppendingString:candidate];
    }

    NSURL *URL = [NSURL URLWithString:candidate];
    if (URL == nil) {
        return nil;
    }

    return [NSURLRequest requestWithURL:URL];
}

#pragma mark - MinimalBrowserWebViewDelegate

- (BOOL)webView:(id)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType {
    (void)webView;
    (void)request;
    (void)navigationType;
    return YES;
}

- (void)webViewDidStartLoad:(id)webView {
    (void)webView;
    if ([self.delegate respondsToSelector:@selector(browserViewControllerDidStartLoading:)]) {
        [self.delegate browserViewControllerDidStartLoading:self];
    }
}

- (void)webViewDidFinishLoad:(id)webView {
    (void)webView;
    self.title = self.browserView.title;
    if ([self.delegate respondsToSelector:@selector(browserViewControllerDidFinishLoading:)]) {
        [self.delegate browserViewControllerDidFinishLoading:self];
    }
}

- (void)webView:(id)webView didFailLoadWithError:(NSError *)error {
    (void)webView;
    if ([self.delegate respondsToSelector:@selector(browserViewController:didFailWithError:)]) {
        [self.delegate browserViewController:self didFailWithError:error];
    }
}

@end
