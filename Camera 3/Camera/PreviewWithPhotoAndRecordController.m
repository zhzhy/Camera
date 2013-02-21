//
//  PreviewWithPhotoAndRecordController.m
//  Camera
//
//  Created by zcy on 13-1-21.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import "PreviewWithPhotoAndRecordController.h"

@interface PreviewWithPhotoAndRecordController ()

@end

@implementation PreviewWithPhotoAndRecordController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    videoProcessor = [[Camera alloc] init];
    videoProcessor.currentOutputOrientation = self.interfaceOrientation;
    videoProcessor.delegate = self;
    [videoProcessor setupImageWithMovieOutputAndPreview:self.view.layer];
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
