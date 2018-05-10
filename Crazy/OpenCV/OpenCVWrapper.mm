//
//  OpenCVWrapper.m
//  Crazy
//
//  Created by 調 原作 on 2018/05/07.
//  Copyright © 2018年 Monogs. All rights reserved.
//

#import "OpenCVHelper.h"
#import "OpenCVWrapper.h"

@implementation OpenCVWrapper

NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
NSMutableArray *xArray = [NSMutableArray array];
NSMutableArray *yArray = [NSMutableArray array];
NSMutableArray *vArray = [NSMutableArray array];

+(NSString *) openCVVersionString
{
    return [NSString stringWithFormat: @"openCV Version %s", CV_VERSION];
}

+(UIImage * ) makeGrayFromImage:(UIImage *)image
{
    // transform UIImagge to cv::Mat
    cv::Mat imageMat;
    UIImageToMat(image, imageMat);
    
    // if the image already grayscale, return it
    if(imageMat.channels() == 1)return image;
    
    // transform the cv::Mat color image to gray
    cv::Mat grayMat;
    cv::cvtColor (imageMat, grayMat, CV_BGR2GRAY);
    
    return MatToUIImage(grayMat);
}

+ (UIImage *)match :(UIImage *)srcImage templateImage:(UIImage *)templateImage {
    
    cv::Mat srcMat = [OpenCVHelper cvMatFromUIImage:srcImage];
    cv::Mat tmpMat = [OpenCVHelper cvMatFromUIImage:templateImage];
    
    // 入力画像をコピー
    cv::Mat dst = srcMat.clone();
    
    // マッチング
    cv::matchTemplate(srcMat, tmpMat, dst, cv::TM_CCOEFF);
    
    double min_val, max_val;
    cv::Point min_loc, max_loc;
    cv::minMaxLoc(dst, &min_val, &max_val, &min_loc, &max_loc);
    
    // 結果の描画
    cv::rectangle(srcMat, max_loc, cv::Point(max_loc.x + tmpMat.cols, max_loc.y + tmpMat.rows), CV_RGB(0, 255, 0), 2);
    
    return [OpenCVHelper UIImageFromCVMat:srcMat];
}

+ (void)keyPoints:(UIImage *) srcImage success:(ReturnKeyPointsBlock)success
{
    cv::Mat srcMat = [OpenCVHelper cvMatFromUIImage:srcImage];
    
    // detector 生成
    cv::Ptr<cv::ORB> detector = cv::ORB::create();
    
    // 特徴点抽出
    std::vector<cv::KeyPoint> keypoints;
    detector->detect(srcMat, keypoints);
    
    // 特徴点を描画
    [mdic removeAllObjects];
    // 特徴点を描画
    cv::Mat dstMat;
    
    dstMat = srcMat.clone();
    for(int i = 0; i < keypoints.size(); i++) {
        if(i > 3) { break; }
        cv::KeyPoint *point = &(keypoints[i]);
        cv::Point center;
        int radius;
        center.x = cvRound(point->pt.x);
        center.y = cvRound(point->pt.y);
        radius = cvRound(point->size*0.45);
        cv::circle(dstMat, center, radius, cvScalar(255,255,0));
        [xArray addObject:[NSString stringWithFormat:@"%u", center.x]];
        [yArray addObject:[NSString stringWithFormat:@"%u", center.y]];
        [vArray addObject:[NSString stringWithFormat:@"%u", radius]];
    }
    [mdic setObject:xArray forKey:@"x"];
    [mdic setObject:yArray forKey:@"y"];
    [mdic setObject:vArray forKey:@"v"];
    [mdic setObject:[OpenCVHelper UIImageFromCVMat:dstMat] forKey:@"image"];

    success(true,mdic);
}

+ (void)resetKeyPoints
{
    [mdic removeAllObjects];
    [xArray removeAllObjects];
    [yArray removeAllObjects];
    [vArray removeAllObjects];
}

@end
