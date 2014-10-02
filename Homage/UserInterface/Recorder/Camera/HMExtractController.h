//
//  HMExtractController.h
//  Homage
//
//  Created by Aviv Wolf on 3/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface HMExtractController : NSObject <
    AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate
>

@property (nonatomic) NSTimeInterval recordingDuration;

-(id)initWithSession:(AVCaptureSession *)session movieDataOutput:(AVCaptureVideoDataOutput *)movieDataOutput audioDataOutput:(AVCaptureAudioDataOutput *)audioDataOutput;

-(void)updateContour:(NSString *)contourFile;

#pragma mark - Recording
-(BOOL)isRecording;
-(void)enableBackgroundDetection;
-(void)disableBackgroundDetection;
-(void)setupExtractorientationWithDeviceOrientation:(UIInterfaceOrientation)orientation frontCamera:(BOOL)front;
-(void)startRecordingToOutputFileURL:(NSURL*)outputFileURL recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate;
-(void)stopRecording;
-(void)updateForegroundExtractorForOrientation:(UIInterfaceOrientation)orientation andCameraDirection:(BOOL)front;


@end
