//
//  HMUploaderTestViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUploaderTestViewController.h"
#import "HMUploadManager.h"
#import "DB.h"
#import "AWTimeProgressView.h"

@interface HMUploaderTestViewController ()

@property id<HMUploadWorkerProtocol> worker;
@property (weak, nonatomic) IBOutlet AWTimeProgressView *guiProgress;

@end

@implementation HMUploaderTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.guiProgress.duration = 30;
    [self.guiProgress start];
    [HMUploadManager.sh startMonitoring];
}

- (IBAction)onTestPressed:(id)sender
{
    [HMUploadManager.sh checkForUploads];
}

- (IBAction)onPressedCancelProgress:(id)sender {
    [self.guiProgress stopAnimated:YES];
}

- (IBAction)onPressedStart:(id)sender {
    [self.guiProgress start];
}

- (IBAction)onChangedDuration:(UISlider *)sender {
    self.guiProgress.duration = sender.value;
}

@end
