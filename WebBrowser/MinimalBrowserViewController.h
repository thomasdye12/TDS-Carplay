#import <UIKit/UIKit.h>

#import "MinimalBrowserWebView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MinimalBrowserViewControllerDelegate <NSObject>

@optional
- (void)browserViewControllerDidStartLoading:(UIViewController *)viewController;
- (void)browserViewControllerDidFinishLoading:(UIViewController *)viewController;
- (void)browserViewController:(UIViewController *)viewController didFailWithError:(NSError *)error;

@end

@interface MinimalBrowserViewController : UIViewController <MinimalBrowserWebViewDelegate>

@property (nullable, nonatomic, weak) id<MinimalBrowserViewControllerDelegate> delegate;
@property (nonatomic, readonly) MinimalBrowserWebView *browserView;
@property (nullable, nonatomic, copy) NSString *userAgent;
@property (nonatomic) BOOL allowsInlineMediaPlayback;

- (instancetype)initWithURLString:(nullable NSString *)URLString;
- (void)loadURLString:(NSString *)URLString;
- (void)loadURL:(NSURL *)URL;
- (void)loadRequest:(NSURLRequest *)request;
- (void)reload;
- (void)goBack;
- (void)goForward;
- (nullable NSString *)evaluateJavaScript:(NSString *)script;

@end

NS_ASSUME_NONNULL_END
