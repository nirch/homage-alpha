//
//  HMFullScreenVideoPlayerViewController.m
//  Homage
//
//  Created by Yoav Caspin on 3/2/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMFullScreenVideoPlayerViewController.h"
#import "HMSimpleVideoViewController.h"
#import "HMSimpleVideoPlayerDelegate.h"

@interface HMFullScreenVideoPlayerViewController () <HMSimpleVideoPlayerDelegate>

@property (strong,nonatomic) HMSimpleVideoViewController *videoVC;
@property (weak, nonatomic) IBOutlet UIView *guiVideoContainer;

@end

@implementation HMFullScreenVideoPlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMRecorderBigVideoPlayerView"
                                                                                 inParentVC:self
                                                                              containerView:self.guiVideoContainer
                                       ];
    vc.delegate = self;
    vc.videoURL = self.videoURL;
    vc.resetStateWhenVideoEnds = NO;    
    self.videoVC = vc;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.videoVC play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
