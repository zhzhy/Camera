//
//  PreviewAndRecordController.m
//  Camera
//
//  Created by zcy on 13-1-18.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import "PreviewAndRecordController.h"

@interface PreviewAndRecordController ()

@end

@implementation PreviewAndRecordController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.CameraMode removeFromSuperview];
    self.CameraMode = nil;
    
    videoProcessor = [[Camera alloc] init];
    videoProcessor.delegate = self;
    videoProcessor.currentOutputOrientation = self.interfaceOrientation;
    [videoProcessor setupMovieOutputAndPreview:self.view.layer];
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
@end
