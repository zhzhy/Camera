//
//  CameraController.h
//  Camera
//
//  Created by zcy on 13-1-16.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camera.h"

typedef enum CameraMode {
    recorderMode,
    photoMode
} CameraMode;

@interface CameraController : UIViewController <VideoProcessorDelegate>
{
    Camera *videoProcessor;
    UIBackgroundTaskIdentifier backgroundRecordingID;
    CameraMode photoOrRecorder;
}
@property (retain, nonatomic) IBOutlet UIButton *recordButton;
@property (retain, nonatomic) IBOutlet UIButton *CameraSelectedButton;
@property (retain, nonatomic) IBOutlet UIButton *CameraMode;
@property (retain, nonatomic) IBOutlet UIButton *CameraPreset;
@property (retain, nonatomic) IBOutlet UIButton *YUVDataSource;
@end