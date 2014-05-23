//
//  HMVideoCameraViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class AVCaptureSession;

#import "HMRecorderChildInterface.h"

@interface HMVideoCameraViewController : UIViewController

+(BOOL)canFlipToFrontCamera;
-(void)releaseCameraIO;
-(void)attachCameraIO;
-(void)updateContour:(NSString *)contourlocalURL;

@end
