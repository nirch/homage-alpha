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
#import "Utime/GpTime.h"

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
@property (readonly) NSURL *outputFileURL;

@property (readonly) AVAssetWriter *assetWriter;
@property (readonly) AVAssetWriterInput *writerInput;

@property (readonly) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;

//@property (readonly) CHomage *h_ext;

//@property CMTime frameTime;
//@property CMTime presentTime;

//@property CMTime lastSampleTime;

@end

@implementation HMExtractController

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

-(id)initWithSession:(AVCaptureSession *)session movieDataOutput:(AVCaptureVideoDataOutput *)movieDataOutput;
{
    self = [super init];
    if (self) {
        _session = session;
        _isCurrentlyRecording = NO;
        _extractQueue = dispatch_queue_create("ExtractionQueue", DISPATCH_QUEUE_SERIAL);
        [movieDataOutput setSampleBufferDelegate:self queue:self.extractQueue];
        [self.session addOutput:movieDataOutput];
        //self.frameTime = CMTimeMake(1,25);
        
        
        m_foregroundExtraction = new CUniformBackground();
        
        NSString *contourFile = [[NSBundle mainBundle] pathForResource:@"close up 480" ofType:@"ctr"];
        m_foregroundExtraction->ReadMask((char*)contourFile.UTF8String, 640, 480);
        
        m_original_image = NULL;
        m_foreground_image = NULL;
        m_output_image = NULL;
        
        
        
        gpTime_init( &m_gTime);
        gpTime_init( & m_gTimeBuffer2image);
        gpTime_init( & m_gTimeImage2Buffrt);
        gpTime_init( & m_gTimeProcess);
        gpTime_init( & m_gTimeAppend);

        
        counter = 0;
    }
    return self;
}

#pragma mark - Recording
-(BOOL)isRecording
{
    return _isCurrentlyRecording;
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
        //NSDictionary *codecSettings = @{
        //                               AVVideoAverageBitRateKey:@3000000
        //                               };
       
        // Specifing settings for the new video (codec, width, hieght)
        NSDictionary *videoSettings = @{
                                        AVVideoCodecKey:AVVideoCodecH264,
                                        AVVideoWidthKey:@640,
                                        AVVideoHeightKey:@480//,
                                        //AVVideoCompressionPropertiesKey:codecSettings
                                        //AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                        
                                        };
        
        _writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        _pixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:nil];
        [self.assetWriter addInput:self.writerInput];
        
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
        
        NSLog(@"Finish");
        _isCurrentlyRecording = NO;

        // Finishing the video. The actaul finish process is asynchronic, so we are assigning a completion handler to be invoked once the the video is ready
        NSLog(@"finishing the record");
        //[self.writerInput markAsFinished];
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
    if (!_isCurrentlyRecording) return;
    
    NSLog(@"Frame: %d", counter);
    
    
    if (counter < 82)
    {
        gp_time_start( &m_gTime );
        NSLog(@"Processing frame: %d", counter);

        CMTime lastSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        
        if (self.assetWriter.status != AVAssetWriterStatusWriting)
        {
            [self.assetWriter startWriting];
            [self.assetWriter startSessionAtSourceTime:lastSampleTime];
        }
        
        //[self.writerInput appendSampleBuffer:sampleBuffer];
        
        // SampleBuffer to PixelBuffer
        CVPixelBufferRef originalPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        // PixelBuffer to image_type (algo image type)
        gp_time_start( &m_gTimeBuffer2image );
        m_original_image = CVtool::CVPixelBufferRef_to_image(originalPixelBuffer, m_original_image);
        gp_time_stop( &m_gTimeBuffer2image );
        
        // Running the algo - result of the algo into m_foreground_image
        gp_time_start( &m_gTimeProcess );
        m_foregroundExtraction->Process(m_original_image, 1, &m_foreground_image);
        
        
        // Save image to file
        //UIImage *foregroundImage = CVtool::CreateUIImage(m_foreground_image);
        //imageName = [NSString stringWithFormat:@"foreground%d.jpg", counter];
        //filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        //[UIImagePNGRepresentation(foregroundImage) writeToFile:filePath atomically:YES];
        
        //m_output_image = imageA_set_color(m_original_image, m_foreground_image, 255, 0x00FF00, m_output_image);
        m_output_image = imageA_set_colorN(m_original_image, m_foreground_image, 0x00FF00, m_output_image);
        gp_time_stop( &m_gTimeProcess );
        
        // Output image_type to PixelBuffer
        gp_time_start( &m_gTimeImage2Buffrt );
        CVPixelBufferRef outputPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_output_image);
        gp_time_stop( &m_gTimeImage2Buffrt );
        
        gp_time_start( &m_gTimeAppend );
        [self.pixelBufferAdaptor appendPixelBuffer:outputPixelBuffer withPresentationTime:lastSampleTime];
        gp_time_stop( &m_gTimeAppend );
        CVPixelBufferRelease(outputPixelBuffer);
        //image_destroy(m_temp_image, 1);
        //image_destroy(temp3_image, 1);
        //image_destroy(temp4_image, 1);
        gp_time_stop( &m_gTime );
    }
    
    
    
    counter = counter + 1;
/*
    UIImage *outputImage = [self imageFromSampleBuffer:sampleBuffer];

    // TODO: Manipulate image using the algorithm here.
    // Need to be able to call CHomage -> Process here and pass it directly a UIImage or CMSampleBufferRef object for each frame.
    // (no need for the C++ code to handle capturing the frames directly from the camera)

    image_type *originalImage = CVtool::DecomposeUIimage(image);
    image_type *foregroundImage;
    
    m_foregroundExtraction->Process(originalImage, 1, &foregroundImage);
    image_type *greenScreenImage = imageA_set_color( originalImage, foregroundImage, 255, 0x00FFFF, NULL);
    
    UIImage *outputImage = CVtool::CreateUIImage(greenScreenImage);
 
    // Append manipulated frame to disk.
    self.presentTime = CMTimeAdd(self.presentTime,self.frameTime);
    CVPixelBufferRef buffer = [HMExtractController newPixelBufferFromCGImage:outputImage.CGImage frameSize:outputImage.size];
    [self.pixelBufferAdaptor appendPixelBuffer:buffer withPresentationTime:self.presentTime];
    CVPixelBufferRelease(buffer);
 */
    
/*
    // Just appending the sample buffer to the writer (with no manipulation)
    if (self.assetWriter.status != AVAssetWriterStatusWriting)
    {
        CMTime lastSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:lastSampleTime];
    }
    
    [self.writerInput appendSampleBuffer:sampleBuffer];
*/
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
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

@end
