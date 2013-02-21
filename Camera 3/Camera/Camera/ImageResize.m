//
//  ImageResize.m
//  Video Collage
//
//  Created by zcy on 12-12-13.
//  Copyright (c) 2012年 zcy. All rights reserved.
//

#import "ImageResize.h"

@implementation ImageResize

+ (UIImage *)imageFromBytes:(UInt8 *)pict width:(int)width height:(int)height bytePerPixel:(int)num
{
    return [ImageResize imageFromBytes:pict width:width height:height bytePerPixel:num imageOrientation:UIInterfaceOrientationPortrait];
}

+ (UIImage *)imageFromBytes:(UInt8 *)pict width:(int)width height:(int)height bytePerPixel:(int)num imageOrientation:(UIImageOrientation)orientaion
{
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict, width * height * num,kCFAllocatorNull);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cgImage = CGImageCreate(width,
									   height,
									   8,
									   8 * num,
									   width * num,
									   colorSpace,
									   bitmapInfo,
									   provider,
									   NULL,
									   NO,
									   kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorSpace);
    UIImage *image = nil;
    image = [[UIImage alloc]initWithCGImage:cgImage scale:1.0f orientation:orientaion];
    CGImageRelease(cgImage);
	CGDataProviderRelease(provider);
	CFRelease(data);
	
	return [image autorelease];
}

+ (UIImage*)scaleImage:(CGImageRef) sourceImage targetWidth:(int)targetWidth tragetHeight:(int)tragetHeight antialiasing:(BOOL)antialiasing
{
    if(!sourceImage)
    {
        return nil;
    }
    
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(sourceImage);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(sourceImage);
    
    if (!colorSpaceInfo)
    {
        return nil;
    }
    
    if (bitmapInfo == kCGImageAlphaNone)
    {
        bitmapInfo = kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap = CGBitmapContextCreate(NULL,targetWidth,tragetHeight, CGImageGetBitsPerComponent(sourceImage), CGImageGetBytesPerRow(sourceImage), colorSpaceInfo, bitmapInfo);
    if (antialiasing == YES) {
        CGContextDrawImage(bitmap, CGRectMake(1, 1, targetWidth - 2, tragetHeight - 2), sourceImage);
    }else
    {
        CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, tragetHeight), sourceImage);
    }
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [[[UIImage alloc] initWithCGImage:scaledImage] autorelease];
    CGContextRelease(bitmap);
    CGImageRelease(scaledImage);
    return newImage;
}

+ (UIImage*)resizeImage:(UIImage *)sourceImage targetWidth:(int)targetWidth tragetHeight:(int)tragetHeight antialiasing:(BOOL)antialiasing
{
    if (!sourceImage) {
        return nil;
    }
    
    CGRect imageRect = CGRectMake(0, 0, targetWidth, tragetHeight);
    UIGraphicsBeginImageContext(imageRect.size);
    if (antialiasing) {
        [sourceImage drawInRect:CGRectMake(1,1,targetWidth - 2,tragetHeight - 2)];
    }else
    {
        [sourceImage drawInRect:imageRect];
    }
    
    sourceImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return sourceImage;
}

// rotate uiimage for correctly displayed on windows and website, because the EXIF information may not recognize by these systems.

+ (UIImage *)rotateImage:(UIImage *)image
{
    if (image.imageOrientation == UIImageOrientationUp)
        return image;

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [image drawInRect:(CGRect){0, 0, image.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}
@end
