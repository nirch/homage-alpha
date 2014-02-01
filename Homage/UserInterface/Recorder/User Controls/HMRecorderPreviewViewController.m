//
//  HMRecorderPreviewViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderPreviewViewController.h"
#import "HMSimpleVideoViewController.h"
#import "DB.h"

@interface HMRecorderPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiContainerView;
@property (weak, nonatomic) HMSimpleVideoViewController *videoVC;
@property (nonatomic) BOOL alreadyDismissed;

@end

@implementation HMRecorderPreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMRecorderBigVideoPlayerView"
                                                                                 inParentVC:self
                                                                              containerView:self.guiContainerView
                                       ];
    vc.delegate = self;
    vc.videoLabelText = LS(@"SHOW YOUR TAKE");
    vc.videoURL = [NSString stringWithFormat:@"file://%@", self.footage.rawLocalFile];
    vc.resetStateWhenVideoEnds = NO;
    vc.delegate = self;
    [vc extractThumbFromVideo];

    self.videoVC = vc;
    self.alreadyDismissed = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.videoVC play];
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - HMSimpleVideoPlayerDelegate
-(void)videoPlayerDidStop
{
    if (self.alreadyDismissed) return;
    self.alreadyDismissed = YES;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)videoPlayerDidFinishPlaying
{
    if (self.alreadyDismissed) return;
    self.alreadyDismissed = YES;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
