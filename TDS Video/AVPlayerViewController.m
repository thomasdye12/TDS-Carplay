//
//  AVPlayerViewController.m
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

#import "AVPlayerViewController+Swizzling.h"
#import <objc/runtime.h>

@implementation AVPlayerViewController (Swizzling)

- (void)my_custom_viewDidAppear:(BOOL)animated {
    NSLog(@"AVPlayerViewController viewDidAppear swizzled!");
    [self my_custom_viewDidAppear:animated];
}

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

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        [self swizzleMethod:class originalSelector:@selector(viewDidAppear:) swizzledSelector:@selector(my_custom_viewDidAppear:)];
    });
}

@end
