//
//  CPTemplateApplicationScene.h
//  TDS Video
//
//  Created by Thomas Dye on 05/08/2024.
//



#ifndef CPTemplateApplicationScene_h
#define CPTemplateApplicationScene_h


@import CarPlay;
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPTemplateApplicationScene (Swizzle)
- (BOOL)_shouldCreateCarWindow;
@end

@interface CPInterfaceController (Swizzle)

// Public method to check if the car window should be created
@property (nonnull, nonatomic, strong, readonly) CPWindow *windowProvider;
// carWindow

- (void)_pushTemplate:(CPTemplate *_Nullable)template
    presentationStyle:(NSInteger)presentationStyle
             animated:(BOOL)animated
           completion:(void (^_Nullable)(BOOL success, NSError *_Nullable error))completion;

- (void)_pushMapTemplate:(CPTemplate *_Nullable)template
    presentationStyle:(NSInteger)presentationStyle
             animated:(BOOL)animated
           completion:(void (^_Nullable)(BOOL success, NSError *_Nullable error))completion;
- (void)_pushListTemplate:(CPTemplate *_Nullable)template
    presentationStyle:(NSInteger)presentationStyle
             animated:(BOOL)animated
           completion:(void (^_Nullable)(BOOL success, NSError *_Nullable error))completion;
@end

NS_ASSUME_NONNULL_END


#endif /* CPTemplateApplicationScene_h */
