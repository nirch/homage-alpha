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
    AVCaptureVideoDataOutputSampleBufferDelegate
>

-(id)initWithSession:(AVCaptureSession *)session movieDataOutput:(AVCaptureVideoDataOutput *)movieDataOutput;

#pragma mark - Recording
-(BOOL)isRecording;
-(void)startRecordingToOutputFileURL:(NSURL*)outputFileURL recordingDelegate:(id<AVCaptureFileOutputRecordingDelegate>)delegate;
-(void)stopRecording;


@end
