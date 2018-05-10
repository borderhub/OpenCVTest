//
//  OpenCVWrapper.h
//  Crazy
//
//  Created by 調 原作 on 2018/05/07.
//  Copyright © 2018年 Monogs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

// funciton to get opencv version
+ (NSString * )openCVVersionString;

// function to convert image to grayscale
+ (UIImage * )makeGrayFromImage:(UIImage * )image;

// function to match
+ (UIImage *)match :(UIImage *)srcImage templateImage:(UIImage *)templateImage;

// function do detect feature points
+ (UIImage *)detectKeypoints:(UIImage *)srcImage;

typedef void(^ReturnKeyPointsBlock)(BOOL success, NSDictionary* options);
+ (void)keyPointsInt:(UIImage *) srcImage success:(ReturnKeyPointsBlock)success;

+ (void)resetKeyPoints;

@end
