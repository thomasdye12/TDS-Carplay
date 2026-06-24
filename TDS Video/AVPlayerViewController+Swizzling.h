//
//  AVPlayerViewController+Swizzling.h
//  TDS Video
//
//  Created by Thomas Dye on 06/08/2024.
//

#ifndef AVPlayerViewController_Swizzling_h
#define AVPlayerViewController_Swizzling_h

#import <AVKit/AVKit.h>

@interface AVPlayerViewController (Swizzling)

- (void)my_custom_viewDidAppear:(BOOL)animated;

@end

#endif /* AVPlayerViewController_Swizzling_h */
