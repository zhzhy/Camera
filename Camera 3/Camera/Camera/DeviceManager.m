//
//  DeviceManager.m
//  Camera
//
//  Created by zcy on 12-12-24.
//
//

#import <AVFoundation/AVFoundation.h>
#import "DeviceManager.h"

@implementation DeviceManager

+ (AVCaptureDevice *)videoCaputreDevice:(AVCaptureDevicePosition) position
{
    NSArray *cameraDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameraDevices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

+ (AVCaptureDevice *)microphone
{
    NSArray *mikeDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([mikeDevices count] > 0) {
        return [mikeDevices objectAtIndex:0];
    }
    return nil;
}

+ (AVCaptureDevice *)backCamera
{
    return [DeviceManager videoCaputreDevice:AVCaptureDevicePositionBack];
}

+ (AVCaptureDevice *)frontCamera
{
    return [DeviceManager videoCaputreDevice:AVCaptureDevicePositionFront];
}

+ (CaptureSessioPreset)randomSessionPreset
{
    return rand() % IFRAM_1920_1080PRESET;
}

+ (NSString *)videoCaptureSessionPreset:(CaptureSessioPreset) indexedPreset
{
    switch (indexedPreset) {
        case PHOTOPRESET:
            return AVCaptureSessionPresetPhoto;
            break;
        case HIGHTPRESET:
            return AVCaptureSessionPresetHigh;
            break;
        case MIDMIUMPRESET:
            return AVCaptureSessionPresetMedium;
            break;
        case LOWPRESET:
            return AVCaptureSessionPresetLow;
            break;
        case _640_480PRESET:
            return AVCaptureSessionPreset640x480;
            break;
        case _1280_720PRESET:
            return AVCaptureSessionPreset1280x720;
            break;
#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0)
        case _352_288PRESET:
            return AVCaptureSessionPreset352x288;
            break;
        case _1920_1080PRESET:
            return AVCaptureSessionPreset1920x1080;
            break;
        case IFRAME_960_540PRESET:
            return AVCaptureSessionPresetiFrame960x540;
            break;
        case IFRAM_1920_1080PRESET:
            return AVCaptureSessionPresetiFrame1280x720;
            break;
#endif
    }
    return nil;
}

+ (BOOL)canApplyPreset:(CaptureSessioPreset)preset toCamera:(AVCaptureDevice *)device
{
    if ([device supportsAVCaptureSessionPreset:[DeviceManager videoCaptureSessionPreset:preset]]) {
        return YES;
    }
    return NO;
}

+ (BOOL)setCameraFocusMode:(AVCaptureDevice *)camera  focusMode:(AVCaptureFocusMode)focusMode
{
    if ([camera isFocusModeSupported:focusMode]) {
        if ([camera lockForConfiguration:nil]) {
            [camera setFocusMode:focusMode];
            [camera unlockForConfiguration];
            return YES;
        }
    }
        return NO;
}

+ (BOOL)setCameraFocusInterestOfFocusPoint:(AVCaptureDevice *)camera interestOfPoint:(CGPoint)point
{
    if (camera.focusMode == AVCaptureFocusModeContinuousAutoFocus && [camera isFocusPointOfInterestSupported]) {
        if ([camera lockForConfiguration:nil]) {
            camera.focusPointOfInterest = point;
            [camera unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)setCameraFlashMode:(AVCaptureDevice *)camera flashMode:(AVCaptureFlashMode)flashMode
{
    if ([camera hasFlash] && [camera  isFlashAvailable]) {
        if ([camera isFlashModeSupported:flashMode]) {
            if ([camera lockForConfiguration:nil]) {
                [camera setFlashMode:flashMode];
                [camera unlockForConfiguration];
                return YES;
            }
        }
    }
    return NO;
}

+ (BOOL)setCameraExposeMode:(AVCaptureDevice *)camera exposeMode:(AVCaptureExposureMode)exposeMode
{
    if ([camera isExposureModeSupported:exposeMode]) {
        if ([camera lockForConfiguration:nil]) {
            [camera setExposureMode:exposeMode];
            [camera unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)setCameraExposeInterestOfExposePoint:(AVCaptureDevice *)camera interestOfPoint:(CGPoint)point
{
    if (camera.exposureMode == AVCaptureExposureModeContinuousAutoExposure && [camera isExposurePointOfInterestSupported]) {
        if ([camera lockForConfiguration:nil]) {
            camera.exposurePointOfInterest = point;
            [camera unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)setCameraWhiteBalanceMode:(AVCaptureDevice *)camera whiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode
{
    if ([camera isWhiteBalanceModeSupported:whiteBalanceMode]) {
        if ([camera lockForConfiguration:nil]) {
            camera.whiteBalanceMode = whiteBalanceMode;
            [camera unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)setCameraTorchMode:(AVCaptureDevice *)camera torchMode:(AVCaptureTorchMode)torchMode
{
    if ([camera hasTorch] && [camera isTorchAvailable] && [camera isTorchModeSupported:torchMode]){
        if ([camera lockForConfiguration:nil]){
            camera.torchMode = torchMode;
            [camera unlockForConfiguration];
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isDeviceHasTorch:(AVCaptureDevice *)device
{
    return [device hasTorch];
}

+ (BOOL)isDeviceHasFlash:(AVCaptureDevice *)device
{
    return [device hasFlash];
}

@end
