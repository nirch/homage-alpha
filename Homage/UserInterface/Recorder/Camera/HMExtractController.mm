//
//  HMExtractController.m
//  Homage
//
//  Created by Aviv Wolf on 3/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMExtractController.h"

#import "Gpw/Vtool/Vtool.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Image3/Image3Tool.h"
#import "ImageType/ImageTool.h"
#import "ImageMark/ImageMark.h"
#import "Utime/GpTime.h"
#import "HMRecorderChildInterface.h"
#import "HMNotificationCenter.h"
#import "HMUploadManager.h"
#import "Mixpanel.h"
#import "HMAppDelegate.h"



@interface HMExtractController (){
    
    BOOL _postedStopRequest;
    int counter;
    CUniformBackground *m_foregroundExtraction;
    image_type *m_original_image;
    image_type *m_foreground_image;
    image_type *m_output_image;
    
    gpTime_type m_gTime;
    gpTime_type m_gTimeBuffer2image;
    gpTime_type m_gTimeImage2Buffrt;
    gpTime_type m_gTimeProcess;
    gpTime_type m_gTimeAppend;
    
    CVtool *_cvTool;
}

@property (nonatomic, readonly, weak) AVCaptureSession *session;
@property (nonatomic, readonly, weak) id<AVCaptureFileOutputRecordingDelegate> recordingDelegate;

@property (nonatomic, readonly) dispatch_queue_t extractQueue;
@property (readonly) BOOL isCurrentlyRecording;
@property (nonatomic) BOOL backgroundDetectionEnabled;
@property (readonly) NSURL *outputFileURL;

@property (readonly) AVAssetWriter *assetWriter;
@property (readonly) AVAssetWriterInput *writerVideoInput;
@property (readonly) AVAssetWriterInput *writerAudioInput;

@property (readonly,nonatomic) AVCaptureVideoDataOutput *movieDataOutput;
@property (readonly,nonatomic) AVCaptureAudioDataOutput *audioDataOutput;

@property (readonly) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;
@property (nonatomic) NSInteger extractCounter;
@property (nonatomic) BOOL frontCamera;
@property (nonatomic) BOOL micEnabled;
@property (nonatomic) UIInterfaceOrientation interfaceOrientaion;
@property (nonatomic) NSString *contourFile;

@property (nonatomic) CMTime firstSampleTime;

@property (nonatomic) BOOL isSlowDevice;
@property (nonatomic) BOOL shouldWriteAudio;

//@property (readonly) CHomage *h_ext;

//@property CMTime frameTime;
//@property CMTime presentTime;

//@property CMTime lastSampleTime;

@end

@implementation HMExtractController

#define EXTRACT_TH 0
#define EXTRACT_EXCEPTION 9
#define EXTRACT_TIMER_INTERVAL 13 //25 is 1 sec interval, 13~0.5 sec

#define OUTPUT_DEFAULT_WIDTH 640
#define OUTPUT_DEFAULT_HEIGHT 360

#define OUTPUT_720_WIDTH 1280
#define OUTPUT_720_HEIGHT 720

#define OUTPUT_1080_WIDTH 1920
#define OUTPUT_1080_HEIGHT 1080

-(id)init
{
    self = [super init];
    if (self) {
        // Recording duration.
        _recordingDuration = 0;
        _cvTool = new CVtool();
        // Is slow device?
        HMAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        self.isSlowDevice = [appDelegate isSlowDevice];
    }
    return self;
}

-(id)initWithSession:(AVCaptureSession *)session movieDataOutput:(AVCaptureVideoDataOutput *)movieDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput
{
    self = [super init];
    if (self) {
        _session = session;
        _isCurrentlyRecording = NO;
        _extractCounter = 0;
        _extractQueue = dispatch_queue_create("ExtractionQueue", DISPATCH_QUEUE_SERIAL);
        _movieDataOutput = movieDataOutput;
        _audioDataOutput = audioDataOutput;
        
        [movieDataOutput setSampleBufferDelegate:self queue:self.extractQueue];
        [audioDataOutput setSampleBufferDelegate:self queue:self.extractQueue];
        
        [self.session addOutput:movieDataOutput];
        
        if ([self.session canAddOutput:audioDataOutput]) {
            [self.session addOutput:audioDataOutput];
        } else {
            NSLog(@"can't add audio output");
        }
        
        //self.frameTime = CMTimeMake(1,25);
        
        m_foregroundExtraction = new CUniformBackground();
        
        
        if (_contourFile)
        {
            NSLog(@"contour file is: %@" , _contourFile);
            int result = m_foregroundExtraction->ReadMask((char*)_contourFile.UTF8String, OUTPUT_DEFAULT_WIDTH, OUTPUT_DEFAULT_HEIGHT);
            if (result == -1)
            {
                NSLog(@"unable to read contour file! debug this");
                [[Mixpanel sharedInstance] track:@"unable_to_open_file" properties:@{@"contour_path" : _contourFile}];
                _contourFile = nil;
            } else {
                self.backgroundDetectionEnabled = YES;
            }
        } else
        {
            self.backgroundDetectionEnabled = NO;
        }
        
        
        m_original_image = NULL;
        m_foreground_image = NULL;
        m_output_image = NULL;
        
        gpTime_init( &m_gTime);
        gpTime_init( & m_gTimeBuffer2image);
        gpTime_init( & m_gTimeImage2Buffrt);
        gpTime_init( & m_gTimeProcess);
        gpTime_init( & m_gTimeAppend);
        
        counter = 0;
        
        [self initObservers];
    }
    return self;
}

-(void)updateContour:(NSString *)contourFile
{
    _contourFile = contourFile;
    NSLog(@"contour file is: %@" , _contourFile);
    int result = m_foregroundExtraction->ReadMask((char*)contourFile.UTF8String, OUTPUT_DEFAULT_WIDTH, OUTPUT_DEFAULT_HEIGHT);
    if (result == -1)
    {
        NSLog(@"unable to read contour file! debug this");
        [[Mixpanel sharedInstance] track:@"unable_to_open_file" properties:@{@"contour_path" : contourFile}];
        _contourFile = nil;
    }
    //self.backgroundDetectionEnabled = YES;
}


-(void)initObservers
{
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(disableBackgroundDetection)
                                                       name:HM_DISABLE_BG_DETECTION
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(enableBackgroundDetection)
                                                       name:HM_ENABLE_BG_DETECTION
                                                     object:nil];
}


-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_DISABLE_BG_DETECTION object:nil];
    [nc removeObserver:self name:HM_ENABLE_BG_DETECTION object:nil];
}

-(void)dealloc
{
    [self removeObservers];
}


#pragma mark - Recording
-(BOOL)isRecording
{
    return _isCurrentlyRecording;
}

-(void)setupExtractorientationWithDeviceOrientation:(UIInterfaceOrientation)orientation frontCamera:(BOOL)front
{
    self.interfaceOrientaion = orientation;
    self.frontCamera = front;
}

-(void)updateForegroundExtractorForOrientation:(UIInterfaceOrientation)orientation andCameraDirection:(BOOL)front
{
    self.interfaceOrientaion = orientation;
    self.frontCamera = front;
    if ([self shouldFlipVideo])
    {
        m_foregroundExtraction->SetFlip(1);
    } else
    {
        m_foregroundExtraction->SetFlip(0);
    }
}


-(BOOL)shouldFlipVideo
{
    BOOL shouldFlip = self.interfaceOrientaion == UIInterfaceOrientationLandscapeLeft;
    if (self.frontCamera) shouldFlip = !shouldFlip;
    return shouldFlip;
}


-(void)startRecordingToOutputFileURL:(NSURL *)outputFileURL
                   recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate
                   shouldRecordAudio:(BOOL)shouldRecordAudio
{
    [self startRecordingToOutputFileURL:outputFileURL
                      recordingDelegate:delegate
                      shouldRecordAudio:shouldRecordAudio
                       outputResolution:HMOutputResolution360];
}

-(void)startRecordingToOutputFileURL:(NSURL *)outputFileURL
                   recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate
                   shouldRecordAudio:(BOOL)shouldRecordAudio
                    outputResolution:(HMOutputResolution)outputResolution
{
    if (_isCurrentlyRecording) return;
    self.shouldWriteAudio = shouldRecordAudio;
    dispatch_async(self.extractQueue, ^{
        _isCurrentlyRecording = YES;
        NSLog(@"Start recording with FG extraction: %@", outputFileURL);
        _outputFileURL = outputFileURL;
        _recordingDelegate = delegate;
        _postedStopRequest = NO;
        
        // Creating the container to which the video will be written to
        NSError *error;
        _assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputFileURL
                                                 fileType:AVFileTypeQuickTimeMovie
                                                    error:&error];
        
        // Output video bitrate
        NSDictionary *codecSettings = @{
                                        AVVideoAverageBitRateKey:@3000000
                                        };
        
        NSString *scalingMode = AVVideoScalingModeResizeAspect;
        if (self.session.sessionPreset == AVCaptureSessionPreset640x480)
        {
            scalingMode = AVVideoScalingModeResizeAspectFill;
        }
        
        // Specifing settings for the new video (codec, width, hieght)
        NSDictionary *videoSettings = @{
                                        AVVideoCodecKey:AVVideoCodecH264,
                                        AVVideoWidthKey:@([self outputWidthForResolution:outputResolution]),
                                        AVVideoHeightKey:@([self outputHeightForResolution:outputResolution]),
                                        AVVideoCompressionPropertiesKey:codecSettings,
                                        AVVideoScalingModeKey:scalingMode
                                        };
        
        _writerVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        _writerVideoInput.expectsMediaDataInRealTime = YES;
        
        // We are flipping the video frame by frame if required (not on slow devices)
        if (self.isSlowDevice && [self shouldFlipVideo]) {
            _writerVideoInput.transform = CGAffineTransformMakeRotation(M_PI);
        }
        
        _writerAudioInput = nil;
        
        // Checking if the mic is enabled or not
        if (self.shouldWriteAudio) {
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL response){
                self.micEnabled = response;
            }];
        }
        
        //_pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerVideoInput sourcePixelBufferAttributes:nil];
        [self.assetWriter addInput:self.writerVideoInput];
    });
}

-(NSInteger)outputWidthForResolution:(HMOutputResolution)outputResolution
{
    switch (outputResolution) {
        case HMOutputResolution360:
            return OUTPUT_DEFAULT_WIDTH;
        case HMOutputResolution720:
            return OUTPUT_720_WIDTH;
        case HMOutputResolution1080:
            return OUTPUT_1080_WIDTH;
    }
}

-(NSInteger)outputHeightForResolution:(HMOutputResolution)outputResolution
{
    switch (outputResolution) {
        case HMOutputResolution360:
            return OUTPUT_DEFAULT_HEIGHT;
        case HMOutputResolution720:
            return OUTPUT_720_HEIGHT;
        case HMOutputResolution1080:
            return OUTPUT_1080_HEIGHT;
    }
}


-(void)stopRecording
{
    if (!_isCurrentlyRecording) return;
    dispatch_async(self.extractQueue, ^{
        
        _isCurrentlyRecording = NO;

        // Finishing the video. The actaul finish process is asynchronic, so we are assigning a completion handler to be invoked once the the video is ready
        [self.writerAudioInput markAsFinished];
        [self.writerVideoInput markAsFinished];
        //[self.assetWriter endSessionAtSourceTime:self.lastSampleTime];
        [self.assetWriter finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.recordingDelegate captureOutput:nil didFinishRecordingToOutputFileAtURL:self.outputFileURL fromConnections:nil error:nil];
            });
        }];
        
        int frameProcess = gpTime_mpf( &m_gTime );
        int buffer2image = gpTime_mpf( & m_gTimeBuffer2image);
        int image2Buffrt = gpTime_mpf( & m_gTimeImage2Buffrt);
        int process = gpTime_mpf( & m_gTimeProcess);
        int append = gpTime_mpf( & m_gTimeAppend);
        
        NSLog(@"frameProcess: %d", frameProcess);
        NSLog(@"buffer2image: %d", buffer2image);
        NSLog(@"image2Buffrt: %d", image2Buffrt);
        NSLog(@"process: %d", process);
        NSLog(@"append: %d", append);
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //detect bad background
    if (captureOutput == _movieDataOutput)
    {
        if (self.extractCounter % EXTRACT_TIMER_INTERVAL == 0 && self.backgroundDetectionEnabled && self.contourFile)
        {
            [self handleBackgroundDetectionForSampleBuffer:sampleBuffer];
        }
        
        self.extractCounter++;
    }
    
    if (!_isCurrentlyRecording) return;
    
    // Just appending the sample buffer to the writer (with no manipulation)
    if (self.assetWriter.status != AVAssetWriterStatusWriting)
    {
        
        if (self.micEnabled && captureOutput != _audioDataOutput) return;
        
        if (self.micEnabled && !self.writerAudioInput)
        {
            [self initAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
        }
        
        CMTime lastSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        self.firstSampleTime = lastSampleTime;
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:lastSampleTime];
    }
    
    if (captureOutput == _movieDataOutput) {
        CMTime lastSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        CMTime timePassed = CMTimeSubtract(lastSampleTime, self.firstSampleTime);
        NSTimeInterval timePassedMS = CMTimeGetSeconds(timePassed) * 1000.0f;

        if (self.writerVideoInput.readyForMoreMediaData)
        {
            // Check if reached recording duration (if recording duration was set)
            if (self.recordingDuration > 0 && timePassedMS >= self.recordingDuration) {
                if (!_postedStopRequest) {
                    // Reached the set recording duration.
                    // Notify that should stop recording.
                    // And skip writing unneeded frames.
                    NSDictionary *info = @{HM_INFO_KEY_RECORDING_STOP_REASON:@(HMRecordingStopReasonEndedSuccessfully)};
                    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                                        object:self
                                                                      userInfo:info];
                    _postedStopRequest = YES;
                }
            } else {
                
                if (!self.isSlowDevice && [self shouldFlipVideo]) {
                    // Process and rotate the video 180Deg if required before saving.
                    CVPixelBufferRef bufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
                    _cvTool->CVPixelBufferRef_rotate180(bufferRef);
                }
                
                // Write the sample buffer.
                [self.writerVideoInput appendSampleBuffer:sampleBuffer];
            }
        }
        else
        {
            NSDictionary *errorDictionary = @{@"message": @"writerVideoInput NOT readyForMoreMediaData", @"file": self.outputFileURL.lastPathComponent};
            [[Mixpanel sharedInstance] track:@"ErrWriterInput" properties:errorDictionary];
        }
    }
    else if (captureOutput == _audioDataOutput)
    {
        if (self.writerAudioInput.readyForMoreMediaData)
        {
            CMTime lastSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
            CMTime timePassed = CMTimeSubtract(lastSampleTime, self.firstSampleTime);
            NSTimeInterval timePassedMS = CMTimeGetSeconds(timePassed) * 1000.0f;

            if (self.recordingDuration > 0 && timePassedMS >= self.recordingDuration) {
                // Over the time limit.
                // Skip writing audio.
            } else {
                // In duration. Write the audio.
                if (self.shouldWriteAudio)
                    [self.writerAudioInput appendSampleBuffer:sampleBuffer];
            }
        }
        else
        {
            NSDictionary *errorDictionary = @{@"message": @"writerAudioInput NOT readyForMoreMediaData", @"file": self.outputFileURL.lastPathComponent};
            [[Mixpanel sharedInstance] track:@"ErrWriterInput" properties:errorDictionary];
        }
    }
}

-(void)handleBackgroundDetectionForSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // SampleBuffer to PixelBuffer
    CVPixelBufferRef originalPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // Resize image to expected size.
    if (self.session.sessionPreset == AVCaptureSessionPreset640x480) {
        // 640x480 - needs to be cropped to 16/9 360p image.
        int x = 0;
        int y = (480 - OUTPUT_DEFAULT_HEIGHT) / 2;
        m_original_image = CVtool::CVPixelBufferRef_to_image_crop(originalPixelBuffer, x, y, OUTPUT_DEFAULT_WIDTH, OUTPUT_DEFAULT_HEIGHT, m_original_image);
    } else {
        // assuming this is 720X1280
        m_original_image = CVtool::CVPixelBufferRef_to_image_sample2(originalPixelBuffer, m_original_image);
    }
    
    // Process the background.
//    int bgMark = m_foregroundExtraction->ProcessBackground(m_original_image, 1);
    int bgMark = 1;

    // If result is lower than allowed threshold,
    // then we got a bad background on our hands!
    if (bgMark < EXTRACT_TH) {
       
        //
        // Bad backgrounds make the algorithm very very sad :-(
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *info = @{K_BAD_BACKGROUND_MARK:@(bgMark)};
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_CAMERA_BAD_BACKGROUND
                                                                object:self
                                                              userInfo:info];
        });

        // TODO: check if this is really needed / doesn't hinder performance.
        // Reporting to server for every bad background frame?
        // Is this really needed?
        if (bgMark == EXTRACT_EXCEPTION)
            [self reportBackgroundExceptionToServer];
        
    } else {
        
        //
        // Good background :-) YEY!
        //
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *info = @{K_GOOD_BACKGROUND_MARK:@(bgMark)};
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_CAMERA_GOOD_BACKGROUND
                                                                object:self
                                                              userInfo:info];
        });
    }

}

-(void)reportBackgroundExceptionToServer
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *contourName = [self.contourFile lastPathComponent];
   
    NSString *path = [NSString stringWithFormat:@"/%ld-%d-%@.jpg" , (long)self.extractCounter , EXTRACT_EXCEPTION , contourName];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:path];

    //CVPixelBufferRef pixelBufferToSave = CVtool::CVPixelBufferRef_from_image(m_original_image);
    image_type *fixRGB = image3_bgr2rgb(m_original_image, NULL);
    image_type *background_image = image4_from(fixRGB, NULL);
    UIImage *bgImage = CVtool::CreateUIImage(background_image);
    [UIImageJPEGRepresentation(bgImage, 1.0) writeToFile:dataPath atomically:YES];
    image_destroy(fixRGB, 1);
    image_destroy(background_image, 1);
    
    [HMUploadManager.sh uploadFile:dataPath];
    [[Mixpanel sharedInstance] track:@"process_background_exception" properties:@{@"local_path" : dataPath}];
}

-(void)initAudioInput:(CMFormatDescriptionRef)currentFormatDescription
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
                                              
                                              [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
                                              
                                              [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
                                              
                                              currentChannelLayoutData, AVChannelLayoutKey,
                                              
                                              nil];
    _writerAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings: audioCompressionSettings];
    _writerAudioInput.expectsMediaDataInRealTime = YES;
    [self.assetWriter addInput:self.writerAudioInput];
    
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);

    return [self imageFromImageBuffer:imageBuffer];
}

- (UIImage *)imageFromImageBuffer:(CVImageBufferRef) imageBuffer
{
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}


// Creating a CVPixelBuffer from a CGImage
+(CVPixelBufferRef) newPixelBufferFromCGImage: (CGImageRef) image frameSize:(CGSize)frameSize
{
    CVPixelBufferRef pxbuffer = NULL;

    #ifdef DEBUG
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge  CFDictionaryRef) options,
                                          &pxbuffer);
    #endif
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);

    // Release
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(void)enableBackgroundDetection
{
    self.backgroundDetectionEnabled = YES;
}


-(void)disableBackgroundDetection;
{
    self.backgroundDetectionEnabled = NO;
}

@end
