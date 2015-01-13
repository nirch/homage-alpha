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
#import "Mixpanel.h"
#import "HMServer+analytics.h"

@interface HMRecorderPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiContainerView;
@property (weak, nonatomic) HMSimpleVideoViewController *videoVC;
@property (nonatomic) BOOL alreadyDismissed;

@end

// TODO: rename this class (general name for playing videos in full screen in recorder)
@implementation HMRecorderPreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMRecorderBigVideoPlayerView"
                                                                                 inParentVC:self
                                                                              containerView:self.guiContainerView rotationSensitive:NO
                                       ];
    vc.delegate = self;
    
    if (self.footage) {
        vc.videoLabelText = LS(@"SHOW_YOUR_TAKE");
        vc.videoURL = [NSString stringWithFormat:@"file://%@", self.footage.rawLocalFile];
        vc.originatingScreen = [NSNumber numberWithInteger:HMRecorderPreview];
    } else if (self.videoURL) {
        vc.videoURL = self.videoURL;
        vc.originatingScreen = [NSNumber numberWithInteger:HMRecorderMessage];
    }
    
    vc.resetStateWhenVideoEnds = NO;
    vc.delegate = self;
    vc.entityType = [NSNumber numberWithInteger:HMScene];
    vc.entityID = @"none";
    [vc extractThumbFromVideo];

    self.videoVC = vc;
    self.alreadyDismissed = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
