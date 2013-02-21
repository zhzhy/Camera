#import <AVFoundation/AVFoundation.h>

@protocol VideoProcessorDelegate;

@interface Camera : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureFileOutputRecordingDelegate>
@property (readwrite, assign) id <VideoProcessorDelegate> delegate;
@property (readonly, getter=isRecording) BOOL recording;
@property (nonatomic,retain) NSString *customPresest;
@property (nonatomic,assign) AVCaptureVideoOrientation currentOutputOrientation;
@property (assign) BOOL pixelBufferReadyForOutput;
@property (assign) BOOL movieSavedToCameraRollAuto;

- (BOOL)setupPreview:(CALayer *)superLayer;
- (BOOL)setupMovieOutputAndPreview:(CALayer *)superLayer;
- (BOOL)setupVideoDataAndPreview:(CALayer *)superLayer;
- (BOOL)setupVideoData;
- (BOOL)setupImageOutputAndPreview:(CALayer *)superLayer;
- (BOOL)setupImageWithMovieOutputAndPreview:(CALayer *)superLayer;
- (BOOL)setupImageWithVideoDataAndPreview:(CALayer *)superLayer;
- (BOOL)setupImageAndVideoData;

- (void)startRecording;
- (void)stopRecording;
- (void)takePicture;

- (void)pauseCaptureSession; // Pausing while a recording is in progress will cause the recording to be stopped and saved.
- (void)resumeCaptureSession;
- (void)changeActiveCamera;
- (AVCaptureDevice *)activeCamera;

- (CGAffineTransform)transformFromVideoDataOrientation:(AVCaptureVideoOrientation)newOrientation;
- (AVCaptureVideoOrientation)imageOrientaionFromInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (CGFloat)angleOffsetFromVideoDataOrientation:(AVCaptureVideoOrientation)newOrientaion;
@end

@protocol VideoProcessorDelegate <NSObject>
@optional
- (void)pixelBufferReadyForDisplay:(CMSampleBufferRef)sampleBuffer;
- (void)recordingWillStart;
- (void)recordingDidStart;
- (void)recordingWillStop;
- (void)recordingDidStop;
@end
