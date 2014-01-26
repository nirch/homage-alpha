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

@end

@implementation HMRecorderPreviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMRecorderBigVideoPlayerView"
                                                                                 inParentVC:self
                                                                              containerView:self.guiContainerView
                                       ];
    //vc.delegate = self;
    vc.videoLabelText = LS(@"SHOW YOUR TAKE");
    vc.videoURL = [NSString stringWithFormat:@"file://%@", self.footage.rawLocalFile];
    vc.resetStateWhenVideoEnds = NO;
    [vc extractThumbFromVideo];
    
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
    // TODO: fix this, when camera problems with upside down captures are resolved.
    return UIInterfaceOrientationMaskLandscape;
}


@end
