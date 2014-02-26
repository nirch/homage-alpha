//
//  HMDetailedStoryRemakeVideoPlayerVC.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMDetailedStoryRemakeVideoPlayerVC.h"
#import "HMSimpleVideoViewController.h"
#import <ALMoviePlayerController/ALMoviePlayerController.h>
#import "HMColor.h"


@interface HMDetailedStoryRemakeVideoPlayerVC () <ALMoviePlayerControllerDelegate>
@property (nonatomic, strong) ALMoviePlayerController *moviePlayer;
@end

@implementation HMDetailedStoryRemakeVideoPlayerVC

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
	
    // create a movie player
    self.moviePlayer = [[ALMoviePlayerController alloc] initWithFrame:self.view.frame];
    self.moviePlayer.delegate = self;
    [self.moviePlayer setFullscreen:YES animated:YES];
    
    // create the controls
    ALMoviePlayerControls *movieControls = [[ALMoviePlayerControls alloc] initWithMoviePlayer:self.moviePlayer style:ALMoviePlayerControlsStyleFullscreen];
    
    // optionally customize the controls here...

    
    UIColor *barColor = [[HMColor.sh main2] colorWithAlphaComponent:0.6];
    [movieControls setBarColor:barColor];
    [movieControls setTimeRemainingDecrements:YES];
    [movieControls setFadeDelay:2.0];
    [movieControls setBarHeight:30.f];
    [movieControls setSeekRate:2.f];
    
    // assign the controls to the movie player
    [self.moviePlayer setControls:movieControls];
    
    // add movie player to your view
    [self.view addSubview:self.moviePlayer.view];
    
    //set contentURL (this will automatically start playing the movie)
    [self.moviePlayer setContentURL:[NSURL URLWithString:self.videoURL]];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (void)moviePlayerWillMoveFromWindow
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self.moviePlayer stop];
        if (![self.view.subviews containsObject:self.moviePlayer.view])
            [self.view addSubview:self.moviePlayer.view];        
    }];
}

- (void)movieTimedOut
{
    
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
