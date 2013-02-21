//
//  HomeViewController.m
//  Camera
//
//  Created by zcy on 13-2-20.
//  Copyright (c) 2013年 zcy. All rights reserved.
//

#import "HomeViewController.h"
#import "PreviewAndPhotoController.h"
#import "PreviewAndRecordController.h"
#import "PreviewCameraController.h"
#import "PreviewWithPhotoAndRecordController.h"
#import "RawDataCameraController.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:YES];
    self.navigationController.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && self.view.window == nil) {
        self.view = nil;
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

- (IBAction)previewAndRecord:(UIButton *)sender
{
    PreviewAndRecordController *previewAndRecordController = [[PreviewAndRecordController alloc] initWithNibName:@"CameraController" bundle:nil];
    [self.navigationController pushViewController:previewAndRecordController animated:YES];
    [previewAndRecordController release];
}


- (IBAction)previewAndPhoto:(UIButton *)sender
{
    PreviewAndPhotoController *previewAndPhoto = [[PreviewAndPhotoController alloc] initWithNibName:@"CameraController" bundle:nil];
    [self.navigationController pushViewController:previewAndPhoto animated:YES];
    [previewAndPhoto release];
}

- (IBAction)previewAndCamera:(UIButton *)sender
{
    PreviewCameraController *previewAndCamera = [[PreviewCameraController alloc] initWithNibName:@"CameraController" bundle:nil];
    [self.navigationController pushViewController:previewAndCamera animated:YES];
    [previewAndCamera release];
}

- (IBAction)rawData:(UIButton *)sender
{
    RawDataCameraController *rawData = [[RawDataCameraController alloc] initWithNibName:@"CameraController" bundle:nil];
    [self.navigationController pushViewController:rawData animated:YES];
    [rawData release];
}

- (IBAction)previewWithPhotoRecord:(UIButton *)sender
{
    PreviewWithPhotoAndRecordController *previewWithPhotoAndRecord = [[PreviewWithPhotoAndRecordController alloc] initWithNibName:@"CameraController" bundle:nil];
    [self.navigationController pushViewController:previewWithPhotoAndRecord animated:YES];
    [previewWithPhotoAndRecord release];
}
@end
