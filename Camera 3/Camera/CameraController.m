//
//  CameraController.m
//  Camera
//
//  Created by zcy on 13-1-16.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import "CameraController.h"
#import "DeviceManager.h"

@implementation CameraController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self wantsFullScreenLayout];
        photoOrRecorder = recorderMode;
    }
    return self;
}

- (void)dealloc{
    [self cleanup];
    
    [_CameraSelectedButton release];
    [_CameraMode release];
    [_CameraPreset release];
    [_YUVDataSource release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self addNotificationAboutAppStateChange];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view bringSubviewToFront:self.recordButton];
    [self.view bringSubviewToFront:self.CameraMode];
    [self.view bringSubviewToFront:self.CameraSelectedButton];
    [self.view bringSubviewToFront:self.CameraPreset];
    [self.view bringSubviewToFront:self.YUVDataSource];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [videoProcessor resumeCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [videoProcessor pauseCaptureSession];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    if ([self isViewLoaded] && !self.view.window) {
        self.recordButton = nil;
        [self setCameraSelectedButton:nil];
        [self setCameraMode:nil];
        [self setCameraPreset:nil];
        [self setYUVDataSource:nil];
        [self cleanup];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    videoProcessor.currentOutputOrientation = toInterfaceOrientation;
}

- (void)cleanup
{
    [self removeNotificationAboutAppStateChange];
    
	videoProcessor.delegate = nil;
    [videoProcessor release];
    [_recordButton release];
}

#pragma  action to invoke when app state changed

- (void)applicationDidBecomeActive:(NSNotification *)notifcation
{
	[videoProcessor resumeCaptureSession];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [videoProcessor pauseCaptureSession];
}

#pragma add and remove notification about app running state

- (void)addNotificationAboutAppStateChange
{
    //moniter the change of orientation of device
    NSNotificationCenter *defaultNotification = [NSNotificationCenter defaultCenter];
	[defaultNotification addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    [defaultNotification addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
}

- (void)removeNotificationAboutAppStateChange
{
    NSNotificationCenter *defaultNotification = [NSNotificationCenter defaultCenter];
    [defaultNotification removeObserver:self name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    [defaultNotification removeObserver:self name:UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
}

#pragma mark RosyWriterVideoProcessorDelegate

- (void)recordingWillStart
{
	dispatch_async(dispatch_get_main_queue(), ^{
        NSString *buttonTitle = nil;
        buttonTitle = @"Recording";
        [self.recordButton setTitle:buttonTitle forState:UIControlStateNormal];
        [self.recordButton setTitle:buttonTitle forState:UIControlStateHighlighted];
        
		// Disable the idle timer while we are recording
		[UIApplication sharedApplication].idleTimerDisabled = YES;
        
		// Make sure we have time to finish saving the movie if the app is backgrounded during recording
		if ([[UIDevice currentDevice] isMultitaskingSupported])
			backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}];
	});
}

- (void)recordingWillStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
		// Disable until saving to the camera roll is complete
        NSString *buttonTitle = nil;
        if (videoProcessor.movieSavedToCameraRollAuto) {
            buttonTitle = @"SavingToCameraRoll";
        }else{
            buttonTitle = @"Saving";
        }
		[self.recordButton setTitle:buttonTitle forState:UIControlStateNormal];
        [self.recordButton setTitle:buttonTitle forState:UIControlStateHighlighted];
		// Pause the capture session so that saving will be as fast as possible.
		// We resume the sesssion in recordingDidStop:
		[videoProcessor pauseCaptureSession];
	});
}

- (void)recordingDidStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
        NSString *buttonTitle = nil;
        buttonTitle = @"Record";
		[UIApplication sharedApplication].idleTimerDisabled = NO;
        [self.recordButton setTitle:buttonTitle forState:UIControlStateNormal];
        [self.recordButton setTitle:buttonTitle forState:UIControlStateHighlighted];
        
		[videoProcessor resumeCaptureSession];
        
		if ([[UIDevice currentDevice] isMultitaskingSupported]) {
			[[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];
			backgroundRecordingID = UIBackgroundTaskInvalid;
		}
	});
}

#pragma action of record video

- (IBAction)startRecord:(UIButton *)sender
{
    if (photoOrRecorder == recorderMode) {
        //save video into camera roll auto
        videoProcessor.movieSavedToCameraRollAuto = YES;
        if ([videoProcessor isRecording]) {
            [videoProcessor stopRecording];
        }else{
            [videoProcessor startRecording];
        }
    }else if (photoOrRecorder == photoMode){
        [videoProcessor takePicture];
    }
}

- (IBAction)cameraSelect:(UIButton *)sender
{
    [videoProcessor changeActiveCamera];
}

- (IBAction)cameraMode:(UIButton *)sender
{
    NSString *title = nil;
    if (photoOrRecorder == recorderMode) {
        photoOrRecorder = photoMode;
        title = @"Photo";
    }else if (photoOrRecorder == photoMode){
        photoOrRecorder = recorderMode;
        title = @"Record";
    }
    
    [self.recordButton setTitle:title forState:UIControlStateNormal];
    [self.recordButton setTitle:title forState:UIControlStateHighlighted];
}

- (IBAction)cameraPresetSetting:(UIButton *)sender
{
    CaptureSessioPreset preset = [DeviceManager randomSessionPreset];
    if ([DeviceManager canApplyPreset:preset toCamera:[videoProcessor activeCamera]]) {
        NSString *sessionPreset = [DeviceManager videoCaptureSessionPreset:preset];
        videoProcessor.customPresest = sessionPreset;
    }
}

- (IBAction)changeYUVDataSource:(UIButton *)sender
{
    
}

@end
