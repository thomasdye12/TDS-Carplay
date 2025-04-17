//
//  AVPlayerViewController+ButtonInteractionSwizzling.m
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

#import "AVPlayerViewController+ButtonInteractionSwizzling.h"
#import <objc/runtime.h>

@implementation AVPlayerViewController (ButtonInteractionSwizzling)

// Example custom method that you may need to implement based on your investigation
- (void)my_custom_registerWithArbiterSkippingEvaluationAndObservation {
    // Custom implementation to bypass the assertion
    @try {
        [self my_custom_registerWithArbiterSkippingEvaluationAndObservation]; // Call the original method
    } @catch (NSException *exception) {
        NSLog(@"Caught exception: %@", exception);
        // Handle the exception or perform necessary cleanup
    }
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
        Class class = NSClassFromString(@"_UIPhysicalButtonInteraction");
        if (class) {
            SEL originalSelector = NSSelectorFromString(@"_registerWithArbiterSkippingEvaluationAndObservation");
            SEL swizzledSelector = @selector(my_custom_registerWithArbiterSkippingEvaluationAndObservation);
            [self swizzleMethod:class originalSelector:originalSelector swizzledSelector:swizzledSelector];
        }
    });
}

@end

