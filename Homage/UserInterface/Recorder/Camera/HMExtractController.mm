//
//  HMExtractController.m
//  Homage
//
//  Created by Aviv Wolf on 3/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMExtractController.h"

//#import "Gpw/FrameBuffer/Mac/FrameBufferIos.h"
//#import	"ImageAcquisition/Mac/CameraAcquisitionMac.h"
//#import "Gpw/FrameLabel/FrameLabelM.h"
//#import "Gpw/MAC/GpwIos.h"
//#import "Gpw/TextLabel/TextLabelIos.h"
//#include "HomageLib/Homage.h"
#import "Gpw/Vtool/Vtool.h"
#import "MattingLib/UniformBackground/UniformBackground.h"
#import "Image3/Image3Tool.h"
#import "ImageType/ImageTool.h"

@interface HMExtractController (){
    
    int counter;
    //CFrameBufferIos *m_fb;
    //CHomage *m_hm;
    CUniformBackground *m_foregroundExtraction;
    image_type *m_original_image;
    image_type *m_foreground_image;
    image_type *m_output_image;
    image_type *m_temp_image;
    image_type *m_temp2_image;
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
        m_temp_image = NULL;
        m_temp2_image = NULL;

        
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
          //                             AVVideoAverageBitRateKey:@1200000
            //                           };
       
        // Specifing settings for the new video (codec, width, hieght)
        NSDictionary *videoSettings = @{
                                        AVVideoCodecKey:AVVideoCodecH264,
                                        AVVideoWidthKey:@640,
                                        AVVideoHeightKey:@480//,
                                        //AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                        //AVVideoCompressionPropertiesKey:codecSettings
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
    });
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_isCurrentlyRecording) return;
    
    NSLog(@"Frame: %d", counter);
    
    if (counter % 10 == 0)
    {
        NSLog(@"Processing frame: %d", counter);

        
        CMTime lastSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        
        if (self.assetWriter.status != AVAssetWriterStatusWriting)
        {
            [self.assetWriter startWriting];
            [self.assetWriter startSessionAtSourceTime:lastSampleTime];
        }
        
        //[self.writerInput appendSampleBuffer:sampleBuffer];
        
        // SampleBuffer to PixelBuffer
        //CVPixelBufferRef originalPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        // PixelBuffer to image_type (algo image type)
        //m_original_image = CVtool::CVPixelBufferRef_to_image(originalPixelBuffer, m_original_image);
        
        UIImage *originalImage = [self imageFromSampleBuffer:sampleBuffer];

        // saving the UI image
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *imageName = [NSString stringWithFormat:@"original%d.jpg", counter];
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [UIImagePNGRepresentation(originalImage) writeToFile:filePath atomically:YES];
        
        m_temp_image = CVtool::DecomposeUIimage(originalImage);
        m_original_image = image3_from(m_temp_image, m_original_image);
        image_type* temp3_image = image3_to_BGR(m_original_image, NULL);
        
        // Running the algo - result of the algo into m_foreground_image
        m_foregroundExtraction->Process(temp3_image, 1, &m_foreground_image);
        
        // Save image to file
        /*UIImage *foregroundImage = CVtool::CreateUIImage(m_foreground_image);
        imageName = [NSString stringWithFormat:@"foreground%d.jpg", counter];
        filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [UIImagePNGRepresentation(foregroundImage) writeToFile:filePath atomically:YES];*/
        
        // Creating an image with green background and original foreground
        m_temp2_image = imageA_set_color(m_original_image, m_foreground_image, 255, 0x00FF00, m_temp2_image);
        image_type* temp4_image = image3_to_BGR(m_temp2_image, NULL);
        m_output_image = image4_from(temp4_image,m_output_image);
        
        // Output image_type to PixelBuffer
        //CVPixelBufferRef outputPixelBuffer = CVtool::CVPixelBufferRef_from_image(m_output_image);
        UIImage *outputImage = CVtool::CreateUIImage(m_output_image);
       
        // Save image to file
        imageName = [NSString stringWithFormat:@"output%d.jpg", counter];
        filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:imageName];
        [UIImagePNGRepresentation(outputImage) writeToFile:filePath atomically:YES];
        
        CVPixelBufferRef outputPixelBuffer = [HMExtractController newPixelBufferFromCGImage:outputImage.CGImage frameSize:outputImage.size];

        
        [self.pixelBufferAdaptor appendPixelBuffer:outputPixelBuffer withPresentationTime:lastSampleTime];
        CVPixelBufferRelease(outputPixelBuffer);
        image_destroy(m_temp_image, 1);
        image_destroy(temp3_image, 1);
        image_destroy(temp4_image, 1);
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
