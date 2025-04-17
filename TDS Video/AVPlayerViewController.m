//
//  AVPlayerViewController.m
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

#import "AVPlayerViewController+Swizzling.h"
#import <objc/runtime.h>

#import "AVPlayerViewController+Swizzling.h"
#import <objc/runtime.h>
//#import "TDS Video-Bridging-Header.h"

//@implementation AVPlayer (Swizzling)
//
//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        Class class = [self class];
//
//        // Swizzle the methods
//        [self swizzleMethod:class originalSelector:@selector(play) swizzledSelector:@selector(my_custom_play)];
//        [self swizzleMethod:class originalSelector:@selector(pause) swizzledSelector:@selector(my_custom_pause)];
//    });
//}
//
//+ (void)swizzleMethod:(Class)class originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector {
//    Method originalMethod = class_getInstanceMethod(class, originalSelector);
//    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
//
//    BOOL didAddMethod = class_addMethod(class,
//                                        originalSelector,
//                                        method_getImplementation(swizzledMethod),
//                                        method_getTypeEncoding(swizzledMethod));
//
//    if (didAddMethod) {
//        class_replaceMethod(class,
//                            swizzledSelector,
//                            method_getImplementation(originalMethod),
//                            method_getTypeEncoding(originalMethod));
//    } else {
//        method_exchangeImplementations(originalMethod, swizzledMethod);
//    }
//}
//
//// Custom play method
//- (void)my_custom_play {
//    // Your custom code here
//    NSLog(@"AVPlayer play method swizzled!");
//    
//    // Call the original play method (now swizzled)
//    [self my_custom_play];
//}
//
//// Custom pause method
//- (void)my_custom_pause {
//    // Your custom code here
//    NSLog(@"AVPlayer pause method swizzled!");
//    
//    // Call the original pause method (now swizzled)
//    [self my_custom_pause];
//}
//
//@end

@implementation AVPlayerViewController (Swizzling)

// Implement your custom methods
- (void)my_custom_viewDidLoad {

//    self._volumeController = self
    // Perform any custom logic with the AVPlayer
//    NSLog(@"AVPlayer extracted: %@", player);
    NSLog(@"AVPlayerViewController viewDidLoad swizzled!");

    // Call the original viewDidLoad method
//    [self my_custom_viewDidLoad];
}

- (void)my_custom_viewDidAppear:(BOOL)animated {
    // Your custom code here
    NSLog(@"AVPlayerViewController viewDidAppear swizzled!");

  

    // Call the original viewDidAppear method
    [self my_custom_viewDidAppear:animated];
    
//    AVPlayerViewController *player = self;
//    [[TDSVideoShared shared] setPlayer:player];

    // Run the player setup after a delay of 5 seconds
//    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
//    dispatch_after(delay, dispatch_get_main_queue(), ^{
//        AVPlayerViewController *player = self;
//        [[TDSVideoShared shared] setPlayer:player];
//    });
}


// Implement your custom init methods
- (instancetype)my_custom_init {
            [super init];
    if (self) {
        NSLog(@"AVPlayerViewController init swizzled!");
        // Any custom initialization code here
    }
    return self;
}

- (void)my_custom_didMoveToParentViewController:(UIViewController *)parent {
    // Your custom code here
    NSLog(@"AVPlayerViewController didMoveToParentViewController swizzled!");

    
    // Call the Swift method
//    self.player needs to be saved to     TDSvideo.shared.AV
    // Call the Swift method
    
    
    // Call the original didMoveToParentViewController method
   
}

// Implement the swizzling method
+ (void)swizzleMethod:(Class)class originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

// Perform the swizzling in +load to ensure it happens early
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

//        // Swizzle the methods
//        [self swizzleMethod:class originalSelector:@selector(viewDidLoad) swizzledSelector:@selector(my_custom_viewDidLoad)];
        [self swizzleMethod:class originalSelector:@selector(viewDidAppear:) swizzledSelector:@selector(my_custom_viewDidAppear:)];
//        [self swizzleMethod:class originalSelector:@selector(init) swizzledSelector:@selector(my_custom_init)];
//        [self swizzleMethod:class originalSelector:@selector(didMoveToParentViewController:) swizzledSelector:@selector(my_custom_didMoveToParentViewController:)];
    });
}

@end
