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



@interface HMExtractController (){
    
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

//@property (readonly) CHomage *h_ext;

//@property CMTime frameTime;
//@property CMTime presentTime;

//@property CMTime lastSampleTime;

@end

@implementation HMExtractController

#define EXTRACT_TH 0
#define EXTRACT_EXCEPTION 9
#define EXTRACT_TIMER_INTERVAL 13 //25 is 1 sec interval, 13~0.5 sec

#define OUTPUT_WIDTH 640
#define OUTPUT_HEIGHT 360

-(id)init
{
    self = [super init];
    if (self) {
        // TODO: Initialize CHomage here.
        // Is CFrameBufferIos *m_fb really needed? The images are now provided in the recording output delegate.
        // No need to get the frames in the C++ code.
        // m_hm = new CHomage( NULL );
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
            m_foregroundExtraction->ReadMask((char*)_contourFile.UTF8String, OUTPUT_WIDTH, OUTPUT_HEIGHT);
            self.backgroundDetectionEnabled = YES;
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
    m_foregroundExtraction->ReadMask((char*)contourFile.UTF8String, OUTPUT_WIDTH, OUTPUT_HEIGHT);
    self.backgroundDetectionEnabled = YES;
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
    if (!self.frontCamera && self.interfaceOrientaion == UIInterfaceOrientationLandscapeRight) return NO;
    if (self.frontCamera && self.interfaceOrientaion == UIInterfaceOrientationLandscapeRight) return YES;
    if (self.frontCamera && self.interfaceOrientaion == UIInterfaceOrientationLandscapeLeft)
        return NO;
    if (!self.frontCamera && self.interfaceOrientaion == UIInterfaceOrientationLandscapeLeft)
        return YES;
    return NO;
}

-(void)startRecordingToOutputFileURL:(NSURL *)outputFileURL recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate
{
    if (_isCurrentlyRecording) return;
   dispatch_async(self.extractQueue, ^{
        _isCurrentlyRecording = YES;
        NSLog(@"Start recording with FG extraction: %@", outputFileURL);
        _outputFileURL = outputFileURL;
        _recordingDelegate = delegate;
        
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
                                        AVVideoWidthKey:@OUTPUT_WIDTH,
                                        AVVideoHeightKey:@OUTPUT_HEIGHT,
                                        AVVideoCompressionPropertiesKey:codecSettings,
                                        AVVideoScalingModeKey:scalingMode
                                        };
       
       _writerVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
       
       if ([self shouldFlipVideo]) _writerVideoInput.transform = CGAffineTransformMakeRotation(M_PI);
        _writerAudioInput = nil;
      
       // Checking if the mic is enabled or not
       [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL response){
           self.micEnabled = response;
       }];

       //_pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerVideoInput sourcePixelBufferAttributes:nil];
       [self.assetWriter addInput:self.writerVideoInput];
       
        // Start writing
        //self.presentTime = CMTimeMake(0, self.frameTime.timescale);
        //[self.assetWriter startWriting];
        //[self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    });
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
        if (self.extractCounter % EXTRACT_TIMER_INTERVAL == 0 && self.backgroundDetectionEnabled)
        {
            // SampleBuffer to PixelBuffer
            CVPixelBufferRef originalPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            
            if (self.session.sessionPreset == AVCaptureSessionPreset640x480)
            {
                int x = 0;
                int y = (480 - OUTPUT_HEIGHT) / 2;
                m_original_image = CVtool::CVPixelBufferRef_to_image_crop(originalPixelBuffer, x, y, OUTPUT_WIDTH, OUTPUT_HEIGHT, m_original_image);
            }
            else // assuming this is 720X1280
            {
                m_original_image = CVtool::CVPixelBufferRef_to_image_sample2(originalPixelBuffer, m_original_image);
            }            
            
            int result = m_foregroundExtraction->ProcessBackground(m_original_image, 1);
            
            if (result < EXTRACT_TH)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:HM_CAMERA_BAD_BACKGROUND object:self];
                //if (result == EXTRACT_EXCEPTION)
                //{
                    [self reportBackgroundExceptionToServer];
                //}
                
            } else
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:HM_CAMERA_GOOD_BACKGROUND object:self];
            }
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
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:lastSampleTime];
    }
    
    if (captureOutput == _movieDataOutput) {
        [self.writerVideoInput appendSampleBuffer:sampleBuffer];
    }
    else if (captureOutput == _audioDataOutput)
    {
        [self.writerAudioInput appendSampleBuffer:sampleBuffer];
    }

}

-(void)reportBackgroundExceptionToServer
{
    //test - save pics
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *path = [NSString stringWithFormat:@"/%ld-%d.jpg" , (long)self.extractCounter , EXTRACT_EXCEPTION];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:path];
    
    //CVPixelBufferRef pixelBufferToSave = CVtool::CVPixelBufferRef_from_image(m_original_image);
    image_type *fixRGB = image3_to_BGR(m_original_image, NULL);
    image_type *background_image = image4_from(fixRGB, NULL);
    UIImage *bgImage = CVtool::CreateUIImage(background_image);
    [UIImageJPEGRepresentation(bgImage, 1.0) writeToFile:dataPath atomically:YES];
    
    [HMUploadManager.sh uploadFile:dataPath];
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
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height, kCVPixelFormatType_32ARGB, (__bridge  CFDictionaryRef) options,
                                          &pxbuffer);
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
