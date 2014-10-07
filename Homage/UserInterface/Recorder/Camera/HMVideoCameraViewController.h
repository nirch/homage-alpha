//
//  HMVideoCameraViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class AVCaptureSession;

#import "HMRecorderChildInterface.h"
#import "AVCamPreviewView.h"


@interface HMVideoCameraViewController : UIViewController

@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;


+(BOOL)canFlipToFrontCamera;
-(void)releaseCameraIO;
-(void)attachCameraIO;
-(void)updateContour:(NSString *)contourlocalURL;


-(void)cameraWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)cameraDidRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;

@end
