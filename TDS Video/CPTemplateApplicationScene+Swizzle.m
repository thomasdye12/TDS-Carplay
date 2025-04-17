//
//  CPTemplateApplicationScene+Swizzle.m
//  TDS Video
//
//  Created by Thomas Dye on 05/08/2024.
//

#import "CPTemplateApplicationScene.h"
#import <objc/runtime.h>

@implementation CPTemplateApplicationScene (Swizzle)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = NSSelectorFromString(@"_shouldCreateCarWindow");
        SEL swizzledSelector = @selector(xyz_shouldCreateCarWindow);

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
        
    });
}

- (BOOL)xyz_shouldCreateCarWindow {
    // Custom logic or call the original implementation if needed
    return YES;
}

- (BOOL)publicShouldCreateCarWindow {
    return [self xyz_shouldCreateCarWindow];
}

@end


#import <objc/runtime.h>


@implementation CPInterfaceController (Bypass)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(clientPushedIllegalTemplateOfClass:));
    Method swizzled = class_getInstanceMethod(self, @selector(bypass_clientPushedIllegalTemplateOfClass:));

    method_exchangeImplementations(original, swizzled);

}

- (void)bypass_clientPushedIllegalTemplateOfClass:(Class)cls {
    NSLog(@"Bypassing illegal template restriction for class:");
    // Do nothing - just bypass the check
}


@end


@implementation CPWindow (Bypass)

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (!view) {
        NSLog(@"Touch ignored, forwarding to first responder...");
        return self.rootViewController.view;
    }
    return view;
}

@end

@implementation CPWindow (Fix)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canResignFirstResponder {
    return NO;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self becomeFirstResponder]; // Ensure it handles input
}

@end




