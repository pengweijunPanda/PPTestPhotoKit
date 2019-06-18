//
//  UIView+Layout.h
//
//  Created by pengweijun on 2019/6/18.
//  Copyright © 2019年 彭伟军. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    TZOscillatoryAnimationToBigger,
    TZOscillatoryAnimationToSmaller,
} TZOscillatoryAnimationType;

@interface UIView (Layout)

@property (nonatomic) CGFloat hg_left;        ///< Shortcut for frame.origin.x.
@property (nonatomic) CGFloat hg_top;         ///< Shortcut for frame.origin.y
@property (nonatomic) CGFloat hg_right;       ///< Shortcut for frame.origin.x + frame.size.width
@property (nonatomic) CGFloat hg_bottom;      ///< Shortcut for frame.origin.y + frame.size.height
@property (nonatomic) CGFloat hg_width;       ///< Shortcut for frame.size.width.
@property (nonatomic) CGFloat hg_height;      ///< Shortcut for frame.size.height.
@property (nonatomic) CGFloat hg_centerX;     ///< Shortcut for center.x
@property (nonatomic) CGFloat hg_centerY;     ///< Shortcut for center.y
@property (nonatomic) CGPoint hg_origin;      ///< Shortcut for frame.origin.
@property (nonatomic) CGSize  hg_size;        ///< Shortcut for frame.size.

+ (void)showOscillatoryAnimationWithLayer:(CALayer *)layer type:(TZOscillatoryAnimationType)type;

@end
