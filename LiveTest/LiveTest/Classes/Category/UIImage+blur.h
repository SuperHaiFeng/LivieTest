//
//  UIImage+blur.h
//  LiveTest
//
//  Created by 志方 on 17/3/23.
//  Copyright © 2017年 志方. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (blur)

+(UIImage *)boxblurImage:(UIImage *)image withBlurNumber:(CGFloat)blur;

+(UIImage *)coreBlurImage:(UIImage *)image withBlurNumber:(CGFloat)blur;

@end
