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
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
	HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMFullScreenVideoPlayerPortrait"
                                                                                 inParentVC:self
                                                                              containerView:self.guiVideoContainerView
                                       ];
    vc.videoURL = self.videoURL;
    vc.resetStateWhenVideoEnds = NO;
    vc.delegate = self;
    [vc play];
    //[vc setScalingMode:@"aspect fit"];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
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
