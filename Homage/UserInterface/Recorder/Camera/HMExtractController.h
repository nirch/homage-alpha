//
//  HMExtractController.h
//  Homage
//
//  Created by Aviv Wolf on 3/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define K_BAD_BACKGROUND_MARK @"bad background mark"
#define K_GOOD_BACKGROUND_MARK @"good background mark"


typedef NS_ENUM(NSInteger, HMOutputResolution) {
    HMOutputResolution360,
    HMOutputResolution720,
    HMOutputResolution1080
};

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

/**
 *  Start recording. This will output the default 360p video file.
 *
 *  @param outputFileURL     NSURL Output file URL
 *  @param delegate          <AVCaptureFileOutputRecordingDelegate>
 *  @param shouldRecordAudio BOOL YES if should also record and output audio
 */
-(void)startRecordingToOutputFileURL:(NSURL *)outputFileURL
                   recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate
                   shouldRecordAudio:(BOOL)shouldRecordAudio;

/**
 *  Start recording. This will output the default 360p video file.
 *
 *  @param outputFileURL     NSURL Output file URL
 *  @param delegate          <AVCaptureFileOutputRecordingDelegate>
 *  @param shouldRecordAudio BOOL YES if should also record and output audio
 *  @param outputResolution  HMOutputResolution supports 360p, 720p and 1080p. All using 16/9 aspect ratio.
 */
-(void)startRecordingToOutputFileURL:(NSURL *)outputFileURL
                   recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate
                   shouldRecordAudio:(BOOL)shouldRecordAudio
                    outputResolution:(HMOutputResolution)outputResolution;


-(void)stopRecording;
-(void)updateForegroundExtractorForOrientation:(UIInterfaceOrientation)orientation andCameraDirection:(BOOL)front;


@end
