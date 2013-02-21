//
//  PreviewCameraController.m
//  Camera
//
//  Created by zcy on 13-1-16.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import "PreviewCameraController.h"

@interface PreviewCameraController ()

@end

@implementation PreviewCameraController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.CameraMode removeFromSuperview];
    [self.recordButton removeFromSuperview];
    self.CameraMode = nil;
    self.recordButton = nil;
    
    videoProcessor = [[Camera alloc] init];
    videoProcessor.delegate = self;
    videoProcessor.currentOutputOrientation = self.interfaceOrientation;
    [videoProcessor setupPreview:self.view.layer];
    [videoProcessor resumeCaptureSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && self.view.window == nil) {
        self.view = nil;
    }
}

#pragma action of record video

- (IBAction)startRecord:(UIButton *)sender
{
    /*if ([videoProcessor isRecording]) {
     [videoProcessor stopRecording];
     }else{
     [videoProcessor startRecording];
     }*/
    
    //[videoProcessor changeActiveCamera];
    
    videoProcessor.customPresest = AVCaptureSessionPresetPhoto;
    
    //[videoProcessor takePicture];
}
@end
