//
//  HMVideoPlayerVC.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMVideoPlayerVC.h"
#import "HMSimpleVideoViewController.h"
#import <ALMoviePlayerController/ALMoviePlayerController.h>
#import "HMColor.h"
#import "HMNotificationCenter.h"


@interface HMVideoPlayerVC () <ALMoviePlayerControllerDelegate>
@property (nonatomic, strong) ALMoviePlayerController *moviePlayer;
@property (nonatomic) BOOL movieFinished;
@end

@implementation HMVideoPlayerVC

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    
    // create a movie player using ALMoviePlayerControllerDelegate
    self.moviePlayer = [[ALMoviePlayerController alloc] initWithFrame:self.view.frame];
    self.moviePlayer.delegate = self;
    [self.moviePlayer setFullscreen:YES animated:YES];
    self.movieFinished = NO;
    
    // create the controls
    ALMoviePlayerControls *movieControls = [[ALMoviePlayerControls alloc] initWithMoviePlayer:self.moviePlayer style:ALMoviePlayerControlsStyleFullscreen];
    
    // optionally customize the controls here...

    [movieControls setTimeRemainingDecrements:YES];
    [movieControls setFadeDelay:2.0];
    [movieControls setBarHeight:30.f];
    [movieControls setSeekRate:2.f];
    
    // assign the controls to the movie player
    [self.moviePlayer setControls:movieControls];
    
    // add movie player to your view
    [self.view addSubview:self.moviePlayer.view];
    
    //set contentURL (this will automatically start playing the movie)
    [self.moviePlayer setContentURL:self.videoURL];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidAppear:(BOOL)animated
{
    //[self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    //[self removeObservers];
}

-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerPlaybackDidFinish:)
                     name:MPMoviePlayerPlaybackDidFinishNotification
                   object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
}


-(void)onMoviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *finishReason = info[@"MPMoviePlayerPlaybackDidFinishReasonUserInfoKey"];
    if (finishReason.integerValue == MPMovieFinishReasonPlaybackEnded)
    {
        self.movieFinished = YES;
        [self moviePlayerWillMoveFromWindow];
    }
}


- (void)moviePlayerWillMoveFromWindow
{
    [self.moviePlayer stop];
    if (self.movieFinished)
    {
        [self.delegate videoPlayerFinished];
    } else
    {
        [self.delegate videoPlayerStopped];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        //when need to return to specific container, uncomment this
        //if (![self.view.subviews containsObject:self.moviePlayer.view])
        //[self.view addSubview:self.moviePlayer.view];
    }];
    
}


-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(BOOL)shouldAutorotate
{
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
