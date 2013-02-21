//
//  PreviewAndPhotoController.m
//  Camera
//
//  Created by zcy on 13-1-21.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import "PreviewAndPhotoController.h"

@interface PreviewAndPhotoController ()

@end

@implementation PreviewAndPhotoController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    videoProcessor = [[Camera alloc] init];
    videoProcessor.currentOutputOrientation = self.interfaceOrientation;
    videoProcessor.delegate = self;
    [videoProcessor setupImageOutputAndPreview:self.view.layer];
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
