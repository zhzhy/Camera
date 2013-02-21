//
//  ImageResize.h
//  Video Collage
//
//  Created by zcy on 12-12-13.
//  Copyright (c) 2012年 zcy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageResize : NSObject
//+ (UIImage *)imageFromBytes:(UInt8 *)pict width:(int)width height:(int)height bytePerPixel:(int)num;
+ (UIImage *)imageFromBytes:(UInt8 *)pict width:(int)width height:(int)height bytePerPixel:(int)num imageOrientation:(UIImageOrientation)orientaion;
+ (UIImage*) scaleImage:(CGImageRef) sourceImage targetWidth:(int)targetWidth tragetHeight:(int)tragetHeight antialiasing:(BOOL)antialiasing;
+ (UIImage*) resizeImage:(UIImage *)sourceImage targetWidth:(int)targetWidth tragetHeight:(int)tragetHeight antialiasing:(BOOL)antialiasing;
+ (UIImage *)rotateImage:(UIImage *)image;
@end
