//
//  HMSimpleVideoViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@import MediaPlayer;

#import "HMSimpleVideoViewController.h"
#import "HMNotificationCenter.h"

@interface HMSimpleVideoViewController ()

@property (nonatomic, readonly) MPMoviePlayerController *videoPlayer;
@property (atomic) BOOL waitingToStartPlayingTheFile;
@property (atomic) BOOL videoLabelToBeHidden;

@end

@implementation HMSimpleVideoViewController

@synthesize videoPlayer = _videoPlayer;

-(id)initWithDefaultNibInParentVC:(UIViewController *)parentVC containerView:(UIView *)containerView;
{
    self = [self initWithNibNamed:@"HMSimpleVideoViewController" inParentVC:parentVC containerView:containerView];
    if (self) {
    }
    return self;
}

-(id)initWithNibNamed:(NSString *)nibName inParentVC:(UIViewController *)parentVC containerView:(UIView *)containerView
{
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        [parentVC addChildViewController:self];
        [containerView addSubview:self.view];
        self.view.frame = containerView.bounds;
        _videoView = (HMSimpleVideoView *)self.view;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self initObservers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerLoadStateDidChange:)
                     name:MPMoviePlayerLoadStateDidChangeNotification
                   object:self.videoPlayer];

    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerPlaybackDidFinish:)
                     name:MPMoviePlayerPlaybackDidFinishNotification
                   object:self.videoPlayer];

    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerPlaybackStateDidChange:)
                     name:MPMoviePlayerPlaybackStateDidChangeNotification
                   object:self.videoPlayer];

    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerDidExitFullscreen:)
                     name:MPMoviePlayerDidExitFullscreenNotification
                   object:self.videoPlayer];

}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.videoPlayer];
}

#pragma mark - Observers handlers
-(void)onMoviePlayerLoadStateDidChange:(NSNotification *)notification
{
    if ((self.videoPlayer.loadState & MPMovieLoadStatePlayable) && self.waitingToStartPlayingTheFile) {
        [self _startToPlayTheActualVideo];
    }
}

-(void)onMoviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    [self done];
}

-(void)onMoviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoPlayer.view.alpha = 1;
        [self.videoView.guiLoadActivity stopAnimating];
    }
}

-(void)onMoviePlayerDidExitFullscreen:(NSNotification *)notification
{
    self.videoPlayer.controlStyle = MPMovieControlStyleNone;
    if (self.delegate) [self.delegate videoExitFullScreen];
}

-(void)_startToPlayTheActualVideo
{
    self.waitingToStartPlayingTheFile = NO;
    [UIView animateWithDuration:0.8 animations:^{
        self.videoView.guiVideoThumb.alpha = 0;
        self.videoView.guiLoadActivity.alpha = 0;
        self.videoView.backgroundColor = [UIColor clearColor];
        self.videoPlayer.backgroundView.backgroundColor = [UIColor clearColor];
        self.videoView.alpha = 1;
    } completion:^(BOOL finished) {
        [self.videoPlayer play];
    }];
}


#pragma mark - Video player user interface
-(UIImage *)videoImage
{
    return self.videoView.guiVideoThumb.image;
}

-(void)setVideoImage:(UIImage *)videoImage
{
    self.videoView.guiVideoThumb.image = videoImage;
}

-(NSString *)videoLabelText
{
    return self.videoView.guiVideoLabel.text;
}

-(void)setVideoLabelText:(NSString *)videoLabelText
{
    self.videoView.guiVideoLabel.text = videoLabelText;
}

-(void)updateUIToPlayVideoState
{
    [self.videoView.guiLoadActivity startAnimating];
    [UIView animateWithDuration:0.3 animations:^{
        self.videoView.guiPlayButton.alpha = 0;
        self.videoView.guiVideoLabel.alpha = 0;
        self.videoView.guiVideoLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        self.videoView.guiVideoLabel.hidden = YES;
        self.videoView.guiPlayButton.hidden = YES;
        self.videoView.guiVideoLabel.transform = CGAffineTransformIdentity;

    }];
}

#pragma mark - The video player
-(MPMoviePlayerController *)videoPlayer
{
    if (_videoPlayer) return _videoPlayer;
    _videoPlayer = [[MPMoviePlayerController alloc] init];
    _videoPlayer.view.frame = self.videoView.guiVideoContainer.bounds;
    _videoPlayer.scalingMode = MPMovieScalingModeAspectFill;
    _videoPlayer.controlStyle = MPMovieControlStyleNone;
    _videoPlayer.shouldAutoplay = NO;
    _videoPlayer.view.alpha = 0;
    [self.videoView.guiVideoContainer addSubview:self.videoPlayer.view];
    return _videoPlayer;
}

-(void)playVideo
{
    self.videoPlayer.contentURL = [NSURL URLWithString:self.videoURL];
    self.waitingToStartPlayingTheFile = YES;
    [self.videoPlayer prepareToPlay];
    if (self.delegate) [self.delegate videoPlayerHitPlayButton];
}

-(void)done
{
    [self.videoPlayer stop];
    if (self.delegate) [self.delegate videoPlayerHitStopButton];
    if (self.videoPlayer.isFullscreen) {
        [self.videoPlayer setFullscreen:NO animated:YES];
    }
    if (!self.videoLabelToBeHidden)  self.videoView.guiVideoLabel.hidden = NO;   
    self.videoView.guiPlayButton.hidden = NO;
    self.videoView.guiLoadActivity.alpha = 1;
    self.videoView.guiControlsContainer.hidden = YES;
    [self.videoView.guiLoadActivity stopAnimating];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.videoPlayer.view.alpha = 0;
        self.videoView.guiVideoThumb.alpha = 1;
        self.videoView.guiPlayButton.alpha = 1;
        self.videoView.guiVideoLabel.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];}

-(void)play
{
    [self updateUIToPlayVideoState];
    [self playVideo];
}

-(void)hideVideoLabel
{
    [self.videoView.guiVideoLabel setHidden:YES];
    self.videoLabelToBeHidden = YES;
}
-(void)setFullScreen
{
    if (!self.videoPlayer.isFullscreen)
    {
        self.videoPlayer.controlStyle = MPMovieControlStyleFullscreen;
        [self.videoPlayer setFullscreen:YES animated:YES];
        [self.videoPlayer setScalingMode:MPMovieScalingModeAspectFit];
    }
}

-(void)hideMediaControls
{
    [self.videoView.guiControlsContainer setHidden:YES];
}

-(BOOL)isInAction
{
    if (self.videoPlayer.playbackState != MPMoviePlaybackStateStopped)
    {
        return YES;
    } else
    {
        return  NO;
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)guiPressedPlayButton:(UIButton *)sender
{
    if (!self.videoURL) return;
    [self play];
}

- (IBAction)onPressedStopButton:(id)sender
{
    [self done];
}

- (IBAction)onPressedPausePlayButton:(id)sender
{
    if (self.videoPlayer.playbackState == MPMoviePlaybackStateStopped || self.videoPlayer.playbackState == MPMoviePlaybackStatePaused) {
        [self.videoPlayer play];
        self.videoView.guiPlayPauseButton.highlighted = YES;
    } else if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        [self.videoPlayer pause];
        self.videoView.guiPlayPauseButton.highlighted = NO;
    }
}

- (IBAction)onPressedFullScreenButton:(id)sender
{
    if (!self.videoPlayer.isFullscreen) {
        self.videoPlayer.controlStyle = MPMovieControlStyleFullscreen;
        [self.videoPlayer setFullscreen:YES animated:YES];
    }
}

- (IBAction)onPressedToggleControls:(id)sender
{
    self.videoView.guiControlsContainer.hidden = !self.videoView.guiControlsContainer.hidden;
}

@end
