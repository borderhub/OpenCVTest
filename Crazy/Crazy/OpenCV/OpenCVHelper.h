//
//  OpenCVHelper.h
//  Crazy
//
//  Created by 調 原作 on 2018/05/07.
//  Copyright © 2018年 Monogs. All rights reserved.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <UIKit/UIKit.h>

@interface OpenCVHelper : NSObject

+ (cv::Mat) cvMatFromUIImage:(UIImage *) image;

+ (UIImage *) UIImageFromCVMat:(cv::Mat) cvMat;

@end
