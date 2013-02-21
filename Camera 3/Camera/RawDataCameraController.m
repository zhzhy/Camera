#import <QuartzCore/QuartzCore.h>
#import "RawDataCameraController.h"
#import "DeviceManager.h"
#import "VideoDisplay.h"
#import "ImageResize.h"
#import "lm_yuv2rgb.h"

@interface RawDataCameraController()
{
    BOOL YUV420BP;
}
@property (nonatomic,retain) VideoDisplay *videodisplay;
@end

@implementation RawDataCameraController

- (void)dealloc
{
    self.videodisplay = nil;
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.YUVDataSource.alpha = 1.0f;
    
    // Initialize the class responsible for managing AV capture session and asset writer
    videoProcessor = [[Camera alloc] init];
	videoProcessor.delegate = self;
    videoProcessor.currentOutputOrientation = self.interfaceOrientation;
    // Setup and start the capture session
    if (![videoProcessor setupVideoData]) {
        NSLog(@"failure!");
    }
    
    //set opengl es view as subview of self.view
    VideoDisplay *tmpDisplay= [[VideoDisplay alloc] initWithFrame:CGRectZero];
    tmpDisplay.autoresizesSubviews = YES;
    [self.view addSubview:tmpDisplay];
    self.videodisplay = tmpDisplay;
    [self setVideoDisplayOrientation:self.interfaceOrientation];
    [tmpDisplay release];
    
    [videoProcessor resumeCaptureSession];
    videoProcessor.pixelBufferReadyForOutput = YES;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && !self.view.window) {
        self.videodisplay = nil;
        self.view = nil;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [videoProcessor setCurrentOutputOrientation:toInterfaceOrientation];
    
    [self setVideoDisplayOrientation:toInterfaceOrientation];
}


- (void)setVideoDisplayOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    [self.videodisplay setTransform:[videoProcessor transformFromVideoDataOrientation:toInterfaceOrientation]];
    if ([[videoProcessor activeCamera] isEqual:[DeviceManager frontCamera]]) {
        self.videodisplay.transform = CGAffineTransformScale(self.videodisplay.transform, -1.0f, 1.0f);
    }
    
    self.videodisplay.bounds = CGRectMake(0.0f, 0.0f, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        self.videodisplay.center = CGPointMake([[UIScreen mainScreen] bounds].size.width / 2, [[UIScreen mainScreen] bounds].size.height / 2);
    }else{
        self.videodisplay.center = CGPointMake([[UIScreen mainScreen] bounds].size.height / 2, [[UIScreen mainScreen] bounds].size.width / 2);
    }
}

- (void)pixelBufferReadyForDisplay:(CMSampleBufferRef)sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!YUV420BP) {
        size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
        size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
        size_t halfHeight = height / 2;
        size_t halfWidth = width / 2;
        size_t size = height * width;
        size_t quarterSize = size / 4;
        unsigned char *triPlaneYUV = malloc(size * 3 / 2);
        
        CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        unsigned char * yPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        unsigned char *uvPlane = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
        memcpy(triPlaneYUV, yPlane, size);
        for (int yIndex = 0; yIndex < halfHeight; yIndex++) {
            for (int xIndex = 0; xIndex < halfWidth; xIndex++) {
                triPlaneYUV[size + yIndex * halfWidth + xIndex] = uvPlane[yIndex * width + xIndex * 2];
                triPlaneYUV[size + quarterSize + yIndex * halfWidth + xIndex] = uvPlane[yIndex * width + xIndex * 2 + 1];
            }
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        
        /*UInt8 *rgb = malloc(width * height * 3);
        yuv2rgb_convert(triPlaneYUV, triPlaneYUV + size, triPlaneYUV + size + quarterSize, rgb, width, height);
        UIInterfaceOrientation orientation = [videoProcessor imageOrientaionFromInterfaceOrientation:self.interfaceOrientation];
        UIImage *image = [ImageResize imageFromBytes:rgb width:width height:height bytePerPixel:3 imageOrientation:orientation];
        UIImage *rotatedImage = [ImageResize rotateImage:image];
        NSData *imageData = UIImageJPEGRepresentation(rotatedImage, 1.0f);
        [imageData writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.jpg"] atomically:YES];
        free(rgb);*/
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.videodisplay displayPixelBuffer:triPlaneYUV width:width height:height];
            free(triPlaneYUV);
        });
    }else{
        CFRetain(imageBuffer);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.videodisplay displayImageBuffer:imageBuffer];
            CFRelease(imageBuffer);
        });
    }
}

- (IBAction)cameraSelect:(UIButton *)sender
{
    [videoProcessor changeActiveCamera];
    [self setVideoDisplayOrientation:self.interfaceOrientation];
}

- (IBAction)changeYUVDataSource:(UIButton *)sender
{
    YUV420BP = !YUV420BP;
}
@end
