#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreMedia/CMBufferQueue.h>
#import "Camera.h"
#import "OrientationTest.h"
#import "DeviceManager.h"
#import "FoldManager.h"
#import "ImageResize.h"

@interface Camera ()
{
    AVCaptureSession *captureSession;
    AVCaptureConnection *audioConnection;
    AVCaptureAudioDataOutput *audioDataOutput;
    AVCaptureConnection *videoConnection;
    AVCaptureVideoDataOutput *videoDataOutput;
    
    CMBufferQueueRef previewBufferQueue;
    dispatch_queue_t videoDataHandleQueue;
    
    AVCaptureMovieFileOutput *movieOutput;
    AVCaptureConnection *videoConnectionOfMovieOutput;
    AVCaptureVideoPreviewLayer *videoPreview;
    AVCaptureStillImageOutput *imageOutput;
    
    AVAssetWriter *movieWriter;
    AVAssetWriterInput *videoWriterInput;
    AVAssetWriterInput *audioWriterInput;
    dispatch_queue_t movieWriterQueue;
    
    // Only accessed on movie writing queue
    BOOL readyToRecord;
    BOOL readyToRecordVideo;
    BOOL readyToRecordAudio;
    BOOL isFrontCamera;
}
@property(readwrite,getter = isRecording) BOOL recording;
@end

@implementation Camera

- (id) init
{
    if (self = [super init]) {        
        captureSession = nil;
        audioConnection = nil;
        videoConnection = nil;
        previewBufferQueue = nil;
        videoDataHandleQueue = nil;
        movieOutput = nil;
        videoPreview = nil;
        readyToRecord = NO;
        readyToRecordAudio = NO;
        readyToRecordVideo = NO;
        isFrontCamera = NO;
    }
    return self;
}

- (void)dealloc
{
    [captureSession stopRunning];
    [captureSession removeOutput:movieOutput];
    [captureSession release];
    captureSession = nil;
    [movieOutput release];
    [videoPreview release];
    [audioDataOutput release];
    [videoDataOutput release];
    if (previewBufferQueue) {
        CFRelease(previewBufferQueue);
    }
    self.customPresest = nil;
    [movieWriter release];
    [videoWriterInput release];
    [audioWriterInput release];
    if (movieWriterQueue) {
        dispatch_release(movieWriterQueue);
    }
    if (videoDataHandleQueue) {
        dispatch_release(videoDataHandleQueue);
    }
    [imageOutput release];
    
    [super dealloc];
}

- (void)setCurrentOutputOrientation:(AVCaptureVideoOrientation)currentOutputOrientation
{
    _currentOutputOrientation = currentOutputOrientation;
    //
    [self rotateVideoPreviewLayer];
}

- (void)setCustomPresest:(NSString *)customPresest
{
    [_customPresest release];
    _customPresest = [customPresest retain];
    
    if (captureSession) {
        if ([captureSession canSetSessionPreset:customPresest]) {
            [captureSession setSessionPreset:customPresest];
        }
    }
}

#pragma mark Capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (self.pixelBufferReadyForOutput) {
        if ( connection == videoConnection ) {
            // Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
            // we'll drop this frame for preview (this keeps preview latency low).
            OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
            if ( !err ) {
                dispatch_async(videoDataHandleQueue, ^{
                    CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
                    if (sbuf) {
                        [self.delegate pixelBufferReadyForDisplay:sbuf];
                        CFRelease(sbuf);
                    }
                });
            }
        }
    }
    
    // save video data by AVAssetWriter
    if (readyToRecord) {
        CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
        CFRetain(formatDescription);
        CFRetain(sampleBuffer);
        dispatch_async(movieWriterQueue, ^{
            if (readyToRecord) {
                if (connection == videoConnection) {
                    if (readyToRecordVideo && readyToRecordAudio){
                        [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                    }else if (!readyToRecordVideo){
                        readyToRecordVideo = [self setupAssetWriterVideoInput:formatDescription];
                    }
                }else if (connection == audioConnection) {
                    if (readyToRecordAudio && readyToRecordVideo){
                        [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
                    }else if (!readyToRecordAudio){
                        readyToRecordAudio = [self setupAssetWriterAudioInput:formatDescription];
                    }
                }
            }
            
            CFRelease(sampleBuffer);
            CFRelease(formatDescription);
        });
    }
}

#pragma setup input device and output device

- (BOOL) setupCaptureSession
{
    /*
     Overview: RosyWriter uses separate GCD queues for audio and video capture.  If a single GCD queue
     is used to deliver both audio and video buffers, and our video processing consistently takes
     too long, the delivery queue can back up, resulting in audio being dropped.
     */
    
    //Create capture session, will expand.
    if (!captureSession) {
        captureSession = [[AVCaptureSession alloc] init];
        if (!captureSession){
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)setupAudioInput
{
    BOOL success;
    AVCaptureDeviceInput *audioIn = [[AVCaptureDeviceInput alloc] initWithDevice:[DeviceManager microphone] error:nil];
    if ((success = [captureSession canAddInput:audioIn])){
        [captureSession addInput:audioIn];
    }
    [audioIn release];
    
    return success;
}

- (BOOL)setupVideoInput
{
    BOOL success;
    AVCaptureDevice *videoDevice = [DeviceManager backCamera];
    if ([videoDevice supportsAVCaptureSessionPreset:self.customPresest]) {
        captureSession.sessionPreset = self.customPresest;
    }else{
        captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    }
    
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ((success = [captureSession canAddInput:videoIn]))
    {
        [captureSession addInput:videoIn];
    }
    [videoIn release];
    
    videoDataHandleQueue = dispatch_queue_create("video data handle", DISPATCH_QUEUE_SERIAL);
    if (!videoDataHandleQueue) {
        return NO;
    }
    
    return success;
}

- (BOOL)setupInputDevices
{
    if (![self setupVideoInput] || ![self setupAudioInput]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupAudioDataOutput
{
    BOOL success = NO;;
    if (captureSession) {
        audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
        [audioDataOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
        dispatch_release(audioCaptureQueue);
        if ((success = [captureSession canAddOutput:audioDataOutput]))
        {
            [captureSession addOutput:audioDataOutput];
            audioConnection = [audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
        }        
    }
    
    return success;
}

- (BOOL)setupVideoDataOutput
{
    BOOL success = NO;
    if (captureSession){
        videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [videoDataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
        dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
        dispatch_release(videoCaptureQueue);
        if ((success = [captureSession canAddOutput:videoDataOutput]))
        {
            [captureSession addOutput:videoDataOutput];
        }
        
        for (AVCaptureConnection *tmpVideoConnection in videoDataOutput.connections) {
            if (tmpVideoConnection.output == videoDataOutput) {
                videoConnection = tmpVideoConnection;
            }
        }
    }
    
    return success;
}

- (BOOL)setupMovieOutput
{
    if (captureSession) {
        movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        //set limition of output file
        if (![captureSession canAddOutput:movieOutput]) {
            return NO;
        }
        [captureSession addOutput:movieOutput];
        for (AVCaptureConnection *connection in movieOutput.connections) {
            for (AVCaptureInputPort *inputPort in connection.inputPorts) {
                if (inputPort.mediaType == AVMediaTypeVideo) {
                    videoConnectionOfMovieOutput = connection;
                    break;
                }
            }
        }
        
        return YES;
    }
    return NO;
}

- (BOOL)setupStillImageOutput
{
    if (captureSession){
        imageOutput = [[AVCaptureStillImageOutput alloc] init];
        NSDictionary *imageSetting = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
        imageOutput.outputSettings = imageSetting;
        if ([captureSession canAddOutput:imageOutput]) {
            [captureSession addOutput:imageOutput];
            return YES;
        }
    }
    return NO;
}

- (BOOL)setupVideoPreviewWithLayer:(CALayer *)superLayer
{
    if (captureSession) {
        videoPreview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
        if (!videoPreview) {
            return NO;
        }
        videoPreview.backgroundColor = [[UIColor blackColor] CGColor];
        if (captureSession.sessionPreset != AVCaptureSessionPresetPhoto) {
            videoPreview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }else{
            videoPreview.videoGravity = AVLayerVideoGravityResizeAspect;
        }
        
        videoPreview.frame = superLayer.frame;
        [superLayer addSublayer:videoPreview];
        [self rotateVideoPreviewLayer];

        return YES;
    }
    return NO;
}

- (BOOL)setupPreview:(CALayer *)superLayer
{
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    //setup video input
    if (![self setupVideoInput]) {
        return NO;
    }
    
    // setup video preview
    if (![self setupVideoPreviewWithLayer:superLayer]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupImageOutputAndPreview:(CALayer *)superLayer
{
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    //setup video input
    if (![self setupVideoInput]) {
        return NO;
    }
    
    //setup video preview
    if (![self setupVideoPreviewWithLayer:superLayer]) {
        return NO;
    }
    
    //setup image output
    if (![self setupStillImageOutput]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupImageWithMovieOutputAndPreview:(CALayer *)superLayer
{
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    if (![self setupInputDevices]) {
        return NO;
    }
    
    if (![self setupVideoPreviewWithLayer:superLayer]) {
        return NO;
    }
    
    if (![self setupStillImageOutput]) {
        return NO;
    }
    
    if (![self setupMovieOutput]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupMovieOutputAndPreview:(CALayer *)superLayer
{
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    if (![self setupInputDevices]) {
        return NO;
    }
    
    // setup movie file output
    if (![self setupMovieOutput]) {
        return NO;
    }
    
    // setup video preview
    if (![self setupVideoPreviewWithLayer:superLayer]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupImageWithVideoDataAndPreview:(CALayer *)superLayer
{
    if (![self setupBufferQueue]) {
        return NO;
    }
    
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    if (![self setupVideoInput]) {
        return NO;
    }
    
    if (![self setupAudioDataOutput] && ![self setupVideoDataOutput]) {
        return NO;
    }
    
    if (![self setupStillImageOutput]) {
        return NO;
    }
    
    if (![self setupVideoPreviewWithLayer:superLayer]){
        return NO;
    }
    
    return YES;
}

- (BOOL)setupImageAndVideoData
{
    if (![self setupBufferQueue]) {
        return NO;
    }
    
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    if (![self setupInputDevices]) {
        return NO;
    }
    
    if (![self setupAudioDataOutput] && ![self setupVideoDataOutput]) {
        return NO;
    }
    
    if (![self setupStillImageOutput]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupVideoDataAndPreview:(CALayer *)superLayer
{
    if (![self setupBufferQueue]) {
        return NO;
    }
    
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    if (![self setupInputDevices]) {
        return NO;
    }
    
    // setup audio and video data output
    if (!([self setupAudioDataOutput] && [self setupVideoDataOutput])) {
        return NO;
    }
    
    // setup video preview
    if (![self setupVideoPreviewWithLayer:superLayer]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupVideoData
{
    if (![self setupBufferQueue]) {
        return NO;
    }
    
    if (![self setupCaptureSession]) {
        return NO;
    }
    
    if (![self setupInputDevices]) {
        return NO;
    }
    
    // setup audio and video data output
    if (!([self setupAudioDataOutput] && [self setupVideoDataOutput])) {
        return NO;
    }
    
    return YES;
}

- (BOOL)setupBufferQueue
{
    // Create a shallow queue for buffers going to the display for preview.
    OSStatus err = CMBufferQueueCreate(kCFAllocatorDefault, 1, CMBufferQueueGetCallbacksForUnsortedSampleBuffers(), &previewBufferQueue);
    if (err){
        NSLog(@"create buffer queue failure");
        return NO;
    }
    return YES;
}

#pragma mark Recording

- (void) startRecording
{
    NSString *movieFilePath = [FoldManager temporaryMovieFilePath];
    if ([FoldManager isDirectoryExists:movieFilePath]) {
        if (![FoldManager removeFileAtPath:movieFilePath]) {
            NSLog(@"delete file failure");
            return;
        }
    }
    if (movieOutput) {
        videoConnectionOfMovieOutput.videoOrientation = self.currentOutputOrientation;
        [movieOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:movieFilePath] recordingDelegate:self];
    }else{
        [movieWriter release];
        movieWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:movieFilePath] fileType:(NSString *)kUTTypeQuickTimeMovie error:nil];
        movieWriterQueue = dispatch_queue_create("write movie queue", DISPATCH_QUEUE_SERIAL);
        if (!movieWriterQueue || !movieWriter) {
            if (movieWriterQueue) {
                dispatch_release(movieWriterQueue);
            }
            [movieWriter release];
            NSLog(@"create writer failure");
            return;
        }
        
        //let capture output to save video frame captured from camera
        readyToRecord = YES;
    }
    self.recording = YES;
    [self.delegate recordingWillStart];
}

- (void) stopRecording
{
    if ([captureSession isRunning] && self.recording) {
        if (movieOutput) {
            [movieOutput stopRecording];
        }else{
            dispatch_async(movieWriterQueue, ^{
                if (movieWriter.status == AVAssetWriterStatusWriting) {
                    if ([movieWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
                        [movieWriter finishWritingWithCompletionHandler:^{
                            [self cleanAssetWriter];
                            [self determineSavedToCameraRoll];
                        }];
                        readyToRecord = NO;
                    }else{
                        if ([movieWriter finishWriting]) {
                            readyToRecord = NO;
                            [self cleanAssetWriter];
                            [self determineSavedToCameraRoll];
                        }
                    }
                }else {
                    readyToRecord = NO;
                    [self cleanAssetWriter];
                    [self determineSavedToCameraRoll];
                }
            });
        }
    }
    
    [self.delegate recordingWillStop];
}

- (void)determineSavedToCameraRoll
{
    if (self.movieSavedToCameraRollAuto) {
        [self saveToCameraRoll];
    }else{
        //notify save over
        [self.delegate recordingDidStop];
        self.recording = NO;
    }
}

- (void)takePicture
{
    AVCaptureConnection *imageOutputConnection = [imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([imageOutputConnection isVideoOrientationSupported]) {
        imageOutputConnection.videoOrientation = self.currentOutputOrientation;
    }
    
    [imageOutput captureStillImageAsynchronouslyFromConnection:imageOutputConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!error) {
            if (imageDataSampleBuffer) {
                NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [UIImage imageWithData:jpegData];
                UIImageWriteToSavedPhotosAlbum([ImageResize rotateImage:image], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                return ;
            }
        }
        NSLog(@"take Photo failure");
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"save image to camera roll failure");
    }
}

#pragma config camera

- (void)pauseCaptureSession
{
    if ( captureSession.isRunning )
        [captureSession stopRunning];
}

- (void)resumeCaptureSession
{
    if ( !captureSession.isRunning )
        [captureSession startRunning];
}

- (void)changeActiveCamera
{
    BOOL willToFrontCamera = NO;
    for (AVCaptureDeviceInput *inputDevice in captureSession.inputs) {
        if ([inputDevice.device hasMediaType:AVMediaTypeVideo]) {
            AVCaptureDevice *newCamera = nil;
            if (inputDevice.device.position == [DeviceManager backCamera].position) {
                newCamera = [DeviceManager frontCamera];
                willToFrontCamera = YES;
            }else{
                newCamera = [DeviceManager backCamera];
                willToFrontCamera = NO;
            }
            if ([newCamera supportsAVCaptureSessionPreset:captureSession.sessionPreset]) {
                AVCaptureDeviceInput *newDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
                
                [captureSession beginConfiguration];
                [captureSession removeInput:inputDevice];
                if ([captureSession canAddInput:newDeviceInput]) {
                    [captureSession addInput:newDeviceInput];
                    isFrontCamera = willToFrontCamera;
                }else{
                    NSLog(@"switch failure");
                    [captureSession addInput:inputDevice];
                    isFrontCamera = !willToFrontCamera;
                }
                [captureSession commitConfiguration];
                [newDeviceInput release];
            }
            
            for (AVCaptureConnection *connection in videoDataOutput.connections) {
                if (connection.output == videoDataOutput) {
                    videoConnection = connection;
                }
            }
            return;
        }
    }
}

- (AVCaptureDevice *)activeCamera
{
    NSArray *inputDevices = captureSession.inputs;
    for (AVCaptureDeviceInput *inputDevice in inputDevices) {
        if ([inputDevice.device hasMediaType:AVMediaTypeVideo]) {
            return inputDevice.device;
        }
    }
    return nil;
}

#pragma AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error) {
        if (![[[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey] boolValue]){
            //give failure tip and nofity save over
            NSLog(@"first save failure");
            [self.delegate recordingDidStop];
            self.recording = NO;
            return;
        }
    }
    // save to Camera Roll
    [self determineSavedToCameraRoll];
}

- (void)saveToCameraRoll
{
    NSString *videoPath = [FoldManager temporaryMovieFilePath];
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }else{
        //notify save over
        [self.delegate recordingDidStop];
        self.recording = NO;
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if ([error code]) {
        // give failure tip
        NSLog(@"second save failure");
    }
    //notify save over
    [self.delegate recordingDidStop];
    self.recording = NO;
}

#pragma config movie output

- (void) writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
    if ( movieWriter.status == AVAssetWriterStatusWriting ) {
        if (mediaType == AVMediaTypeVideo) {
            if (videoWriterInput.readyForMoreMediaData) {
                if (![videoWriterInput appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"can't save video");
                }
            }
        }else if (mediaType == AVMediaTypeAudio) {
            if (audioWriterInput.readyForMoreMediaData) {
                if (![audioWriterInput appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"can't save audio");
                }
            }
        }
    }else if (movieWriter.status == AVAssetWriterStatusUnknown){
        if ([movieWriter startWriting]) {
            [movieWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        }else {
            NSLog(@"can't start AVAssetWriter");
            //close asset writer
            
        }
    }
}

- (BOOL) setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    NSData *currentChannelLayoutData = nil;
    
    // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
    if ( currentChannelLayout && aclSize > 0 )
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    else
        currentChannelLayoutData = [NSData data];
    
    NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                              [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
                                              [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
                                              currentChannelLayoutData, AVChannelLayoutKey,
                                              nil];
    if ([movieWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
        audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        audioWriterInput.expectsMediaDataInRealTime = YES;
        if ([movieWriter canAddInput:audioWriterInput])
            [movieWriter addInput:audioWriterInput];
        else {
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }
    else {
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

- (BOOL) setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                               [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
                                               nil], AVVideoCompressionPropertiesKey,
                                              nil];
    if ([movieWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        videoWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        videoWriterInput.expectsMediaDataInRealTime = YES;
        videoWriterInput.transform = [self newTransform:self.currentOutputOrientation  oldTransform:videoConnection.videoOrientation];
        if ([movieWriter canAddInput:videoWriterInput])
            [movieWriter addInput:videoWriterInput];
        else {
            NSLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }
    else {
        NSLog(@"Couldn't apply video output settings.");
        return NO;
    }
    
    return YES;
}

- (CGAffineTransform)transformFromVideoDataOrientation:(AVCaptureVideoOrientation)newOrientation
{
    return [self newTransform:newOrientation oldTransform:videoConnection.videoOrientation];
}

- (CGAffineTransform)newTransform:(AVCaptureVideoOrientation)inOrientation oldTransform:(AVCaptureVideoOrientation)oldOrientation
{
  
    return CGAffineTransformMakeRotation([self angleOffset:inOrientation oldOrientation:oldOrientation]);
}

- (CGFloat)angleOffsetFromVideoDataOrientation:(AVCaptureVideoOrientation)newOrientaion
{
    return [self angleOffset:newOrientaion oldOrientation:videoConnection.videoOrientation];
}

- (CGFloat)angleOffset:(AVCaptureVideoOrientation)newOrientaion oldOrientation:(AVCaptureVideoOrientation)oldOrientation
{
    CGFloat newAngle = [self angleFromOrientation:newOrientaion];
    CGFloat oldAngle = [self angleFromOrientation:oldOrientation];
    CGFloat angleOffset = newAngle - oldAngle;
    return angleOffset;
}

- (CGFloat)angleFromOrientation:(AVCaptureVideoOrientation)orientation
{
    CGFloat currentAngle = 0.0f;
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            currentAngle = 0.0f;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            currentAngle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            currentAngle = - M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            currentAngle = M_PI_2;
    }
    return currentAngle;
}

- (AVCaptureVideoOrientation)imageOrientaionFromInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    UIImageOrientation imageOrientation;
    if (isFrontCamera) {
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
                imageOrientation = UIImageOrientationRight;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                imageOrientation = UIImageOrientationLeft;
                break;
            case UIInterfaceOrientationLandscapeRight:
                imageOrientation = UIImageOrientationUp;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                imageOrientation = UIImageOrientationDown;
                break;
        }
    }else{
        switch (orientation) {
            case UIInterfaceOrientationPortrait:
                imageOrientation = UIImageOrientationLeftMirrored;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                imageOrientation = UIImageOrientationRightMirrored;
                break;
            case UIInterfaceOrientationLandscapeRight:
                imageOrientation = UIImageOrientationDownMirrored;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                imageOrientation = UIImageOrientationUpMirrored;
                break;
        }
    }
        return imageOrientation;
}

- (void)rotateVideoPreviewLayer
{
    if (UIInterfaceOrientationIsLandscape(self.currentOutputOrientation)) {
        videoPreview.position = CGPointMake(videoPreview.superlayer.position.y, videoPreview.superlayer.position.x);
    }else{
        videoPreview.position = videoPreview.superlayer.position;
    }
    videoPreview.affineTransform = CGAffineTransformMakeRotation([self angleFromOrientation:self.currentOutputOrientation]);
}

- (void)cleanAssetWriter
{
    [audioWriterInput release];
    audioWriterInput = nil;
    [videoWriterInput release];
    videoWriterInput = nil;
    
    [movieWriter release];
    movieWriter = nil;
    if (movieWriterQueue) {
        dispatch_release(movieWriterQueue);
    }
    movieWriterQueue = nil;
    
    readyToRecordVideo = NO;
    readyToRecordVideo = NO;
}
@end
