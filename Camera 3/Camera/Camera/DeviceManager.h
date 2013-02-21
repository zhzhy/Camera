//
//  DeviceManager.h
//  RosyWriter
//
//  Created by zcy on 12-12-24.
//
//

#import <Foundation/Foundation.h>

typedef enum CaptureSessioPreset
{
    PHOTOPRESET,
    HIGHTPRESET,
    MIDMIUMPRESET,
    LOWPRESET,
    _640_480PRESET,
    _1280_720PRESET,
    _352_288PRESET,
    _1920_1080PRESET,
    IFRAME_960_540PRESET,
    IFRAM_1920_1080PRESET
}CaptureSessioPreset;

@interface DeviceManager : NSObject

+ (AVCaptureDevice *)microphone;
+ (AVCaptureDevice *)backCamera;
+ (AVCaptureDevice *)frontCamera;

+ (CaptureSessioPreset)randomSessionPreset;
+ (BOOL)canApplyPreset:(CaptureSessioPreset)preset toCamera:(AVCaptureDevice *)device;
+ (NSString *)videoCaptureSessionPreset:(CaptureSessioPreset) indexedPreset;

+ (BOOL)setCameraFocusMode:(AVCaptureDevice *)camera  focusMode:(AVCaptureFocusMode)focusMode;
+ (BOOL)setCameraFocusInterestOfFocusPoint:(AVCaptureDevice *)camera interestOfPoint:(CGPoint)point;
+ (BOOL)setCameraFlashMode:(AVCaptureDevice *)camera flashMode:(AVCaptureFlashMode)flashMode;
+ (BOOL)setCameraExposeMode:(AVCaptureDevice *)camera exposeMode:(AVCaptureExposureMode)exposeMode;
+ (BOOL)setCameraExposeInterestOfExposePoint:(AVCaptureDevice *)camera interestOfPoint:(CGPoint)point;
+ (BOOL)setCameraWhiteBalanceMode:(AVCaptureDevice *)camera whiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode;
+ (BOOL)setCameraTorchMode:(AVCaptureDevice *)camera torchMode:(AVCaptureTorchMode)torchMode;
+ (BOOL)isDeviceHasFlash:(AVCaptureDevice *)device;
+ (BOOL)isDeviceHasTorch:(AVCaptureDevice *)device;
@end