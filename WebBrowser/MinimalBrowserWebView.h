#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MinimalBrowserWebViewDelegate <NSObject>

@optional
- (BOOL)webView:(id)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType;
- (void)webViewDidStartLoad:(id)webView;
- (void)webViewDidFinishLoad:(id)webView;
- (void)webView:(id)webView didFailLoadWithError:(NSError *)error;

@end

@interface MinimalBrowserWebView : UIView

@property (nullable, nonatomic, weak) id<MinimalBrowserWebViewDelegate> delegate;
@property (nullable, nonatomic, readonly, strong) NSURLRequest *request;
@property (nullable, nonatomic, readonly, strong) UIScrollView *scrollView;
@property (nullable, nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, getter=canGoBack) BOOL canGoBack;
@property (nonatomic, readonly, getter=canGoForward) BOOL canGoForward;
@property (nonatomic, readonly, getter=isLoading) BOOL loading;

- (instancetype)initWithUserAgent:(nullable NSString *)userAgent
      allowsInlineMediaPlayback:(BOOL)allowsInlineMediaPlayback NS_DESIGNATED_INITIALIZER;

- (void)loadRequest:(NSURLRequest *)request;
- (void)reload;
- (void)goBack;
- (void)goForward;
- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script;
- (void)setUserAgent:(nullable NSString *)userAgent;

@end

NS_ASSUME_NONNULL_END
