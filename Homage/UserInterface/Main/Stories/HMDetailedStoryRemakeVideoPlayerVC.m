//
//  HMDetailedStoryRemakeVideoPlayerVC.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMDetailedStoryRemakeVideoPlayerVC.h"
#import "HMSimpleVideoViewController.h"


@interface HMDetailedStoryRemakeVideoPlayerVC ()
@property (weak, nonatomic) IBOutlet UIView *guiVideoContainerView;

@end

@implementation HMDetailedStoryRemakeVideoPlayerVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMFullScreenVideoPlayerPortrait"
                                                                                 inParentVC:self
                                                                              containerView:self.guiVideoContainerView
                                       ];
    //vc.delegate = self;
    vc.videoURL = self.videoURL;
    vc.resetStateWhenVideoEnds = NO;
    vc.delegate = self;
    //[vc extractThumbFromVideo];
    [vc play];
    [vc setScalingMode:@"aspect fit"];
}


-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(void)videoPlayerDidStop
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
