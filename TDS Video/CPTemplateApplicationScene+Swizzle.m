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
    static dispatch_once_t onceToken1;
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
    dispatch_once(&onceToken1, ^{
        Class class = [self class];

        SEL originalSelector = NSSelectorFromString(@"__supportsCarFullScreen");
        SEL swizzledSelector = @selector(xyz__supportsCarFullScreen);

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
- (BOOL)xyz__supportsCarFullScreen {
    // Custom logic or call the original implementation if needed
    return YES;
}

- (BOOL)public_supportsCarFullScreen {
    return [self xyz__supportsCarFullScreen];
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





#import "CPTemplateApplicationScene.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void TDSSwizzleInstanceMethod(Class cls, SEL originalSEL, SEL replacementSEL) {
    Method original = class_getInstanceMethod(cls, originalSEL);
    Method replacement = class_getInstanceMethod(cls, replacementSEL);

    if (!original || !replacement) {
        NSLog(@"[CarPlayTrace] Missing method for swizzle: %@ / %@ on %@",
              NSStringFromSelector(originalSEL),
              NSStringFromSelector(replacementSEL),
              NSStringFromClass(cls));
        return;
    }

    method_exchangeImplementations(original, replacement);
}

@implementation CPTemplateApplicationScene (Trace)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = self;

        TDSSwizzleInstanceMethod(cls,
                                 NSSelectorFromString(@"_shouldCreateCarWindow"),
                                 @selector(tds_trace_shouldCreateCarWindow));

        TDSSwizzleInstanceMethod(cls,
                                 NSSelectorFromString(@"_attachWindow:"),
                                 @selector(tds_trace_attachWindow:));

        TDSSwizzleInstanceMethod(cls,
                                 NSSelectorFromString(@"setCarWindow:"),
                                 @selector(tds_trace_setCarWindow:));

        TDSSwizzleInstanceMethod(cls,
                                 NSSelectorFromString(@"_deliverInterfaceControllerToDelegate"),
                                 @selector(tds_trace_deliverInterfaceControllerToDelegate));
    });
}

- (BOOL)tds_trace_shouldCreateCarWindow {
    NSLog(@"[CarPlayTrace] ENTER _shouldCreateCarWindow scene=%@", self);

    BOOL result = [self tds_trace_shouldCreateCarWindow];

    NSLog(@"[CarPlayTrace] EXIT _shouldCreateCarWindow result=%@ scene=%@",
          result ? @"YES" : @"NO",
          self);

    return result;
}

- (void)tds_trace_attachWindow:(id)window {
    NSLog(@"[CarPlayTrace] ENTER _attachWindow: scene=%@ window=%@", self, window);
    NSLog(@"[CarPlayTrace] Stack:\n%@",
          [[NSThread callStackSymbols] componentsJoinedByString:@"\n"]);

    [self tds_trace_attachWindow:window];

    NSLog(@"[CarPlayTrace] EXIT _attachWindow: scene=%@ window=%@", self, window);
}

- (void)tds_trace_setCarWindow:(id)window {
    NSLog(@"[CarPlayTrace] setCarWindow: scene=%@ window=%@", self, window);

    [self tds_trace_setCarWindow:window];
}

- (void)tds_trace_deliverInterfaceControllerToDelegate {
    NSLog(@"[CarPlayTrace] ENTER _deliverInterfaceControllerToDelegate scene=%@", self);

    [self tds_trace_deliverInterfaceControllerToDelegate];

    NSLog(@"[CarPlayTrace] EXIT _deliverInterfaceControllerToDelegate scene=%@", self);
}

@end


@implementation CPWindow (Trace)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        TDSSwizzleInstanceMethod(self,
                                 NSSelectorFromString(@"initWithFrame:templateScene:"),
                                 @selector(tds_trace_initWithFrame:templateScene:));
    });
}

- (instancetype)tds_trace_initWithFrame:(CGRect)frame templateScene:(id)scene {
    NSLog(@"[CarPlayTrace] ENTER CPWindow initWithFrame:%@ templateScene=%@",
          NSStringFromCGRect(frame),
          scene);

    id window = [self tds_trace_initWithFrame:frame templateScene:scene];

    NSLog(@"[CarPlayTrace] EXIT CPWindow init result=%@", window);

    return window;
}

@end



#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void TDSWrapBoolNoArg(Class cls, SEL sel) {
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) {
        NSLog(@"[CarPlayTrace] missing %@ on %@", NSStringFromSelector(sel), cls);
        return;
    }

    IMP originalIMP = method_getImplementation(method);

    IMP newIMP = imp_implementationWithBlock(^BOOL(id self) {
        BOOL (*orig)(id, SEL) = (BOOL (*)(id, SEL))originalIMP;

        NSLog(@"[CarPlayTrace] ENTER -[%@ %@] self=%@",
              NSStringFromClass([self class]),
              NSStringFromSelector(sel),
              self);

        BOOL result = orig(self, sel);

        NSLog(@"[CarPlayTrace] EXIT  -[%@ %@] result=%@ self=%@",
              NSStringFromClass([self class]),
              NSStringFromSelector(sel),
              result ? @"YES" : @"NO",
              self);

        return result;
    });

    method_setImplementation(method, newIMP);
}

static void TDSWrapObjectNoArg(Class cls, SEL sel) {
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) {
        NSLog(@"[CarPlayTrace] missing %@ on %@", NSStringFromSelector(sel), cls);
        return;
    }

    IMP originalIMP = method_getImplementation(method);

    IMP newIMP = imp_implementationWithBlock(^id(id self) {
        id (*orig)(id, SEL) = (id (*)(id, SEL))originalIMP;

        NSLog(@"[CarPlayTrace] ENTER -[%@ %@] self=%@",
              NSStringFromClass([self class]),
              NSStringFromSelector(sel),
              self);

        id result = orig(self, sel);

        NSLog(@"[CarPlayTrace] EXIT  -[%@ %@] result=%@ self=%@",
              NSStringFromClass([self class]),
              NSStringFromSelector(sel),
              result,
              self);

        return result;
    });

    method_setImplementation(method, newIMP);
}

static void TDSWrapVoidOneObjectArg(Class cls, SEL sel) {
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) {
        NSLog(@"[CarPlayTrace] missing %@ on %@", NSStringFromSelector(sel), cls);
        return;
    }

    IMP originalIMP = method_getImplementation(method);

    IMP newIMP = imp_implementationWithBlock(^void(id self, id arg) {
        void (*orig)(id, SEL, id) = (void (*)(id, SEL, id))originalIMP;

        NSLog(@"[CarPlayTrace] ENTER -[%@ %@] self=%@ arg=%@",
              NSStringFromClass([self class]),
              NSStringFromSelector(sel),
              self,
              arg);

        orig(self, sel, arg);

        NSLog(@"[CarPlayTrace] EXIT  -[%@ %@] self=%@ arg=%@",
              NSStringFromClass([self class]),
              NSStringFromSelector(sel),
              self,
              arg);
    });

    method_setImplementation(method, newIMP);
}

__attribute__((constructor))
static void TDSInstallCarPlayTrace(void) {
    Class env = NSClassFromString(@"CPSTemplateEnvironment");
    if (env) {
        TDSWrapBoolNoArg(env, NSSelectorFromString(@"hasAnyTemplateEntitlement"));
        TDSWrapBoolNoArg(env, NSSelectorFromString(@"hasNavigationEntitlement"));
        TDSWrapBoolNoArg(env, NSSelectorFromString(@"hasCommunicationEntitlement"));
        TDSWrapBoolNoArg(env, NSSelectorFromString(@"hasAudioEntitlement"));
        TDSWrapBoolNoArg(env, NSSelectorFromString(@"isUserApplication"));
        TDSWrapObjectNoArg(env, NSSelectorFromString(@"allowedTemplateClasses"));
    } else {
        NSLog(@"[CarPlayTrace] CPSTemplateEnvironment not loaded");
    }

    Class instance = NSClassFromString(@"CPSTemplateInstance");
    if (instance) {
        TDSWrapBoolNoArg(instance, NSSelectorFromString(@"clientApplicationSceneIsConnected"));
        TDSWrapBoolNoArg(instance, NSSelectorFromString(@"requiresApplicationScenePresenter"));
        TDSWrapVoidOneObjectArg(instance, NSSelectorFromString(@"setWindowSceneForTemplateApplicationScene:"));
    } else {
        NSLog(@"[CarPlayTrace] CPSTemplateInstance not loaded");
    }

    NSLog(@"[CarPlayTrace] installed app-process CarPlay tracing");
}

