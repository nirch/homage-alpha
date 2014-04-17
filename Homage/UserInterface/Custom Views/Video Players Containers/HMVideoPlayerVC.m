//
//  HMVideoPlayerVC.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMVideoPlayerVC.h"
#import "HMNotificationCenter.h"

@import MediaPlayer;
@import AVFoundation;

@implementation UIDevice (ALSystemVersion)

//static const CGFloat movieBackgroundPadding = 0.f;
//static const NSTimeInterval fullscreenAnimationDuration = 0.3;

+ (float)iOSVersion {
    static float version = 0.f;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        version = [[[UIDevice currentDevice] systemVersion] floatValue];
    });
    return version;
}

@end

@implementation UIApplication (ALAppDimensions)

+ (CGSize)sizeInOrientation:(UIInterfaceOrientation)orientation {
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIApplication *application = [UIApplication sharedApplication];
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        size = CGSizeMake(size.height, size.width);
    }
    if (!application.statusBarHidden && [UIDevice iOSVersion] < 7.0) {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size;
}

@end
@interface HMVideoPlayerVC ()

@property (nonatomic, readonly) BOOL isFullscreen;
@property (nonatomic, readonly, weak) UIView *containerView;
@property (nonatomic, readonly) UIView *movieTempFullscreenBackgroundView;
@property (nonatomic, readonly) MPMoviePlayerController *videoPlayer;
@property (atomic) BOOL waitingToStartPlayingTheFile;
@property (nonatomic, readonly) BOOL shouldDisplayVideoLabel; // YES by default
@property (nonatomic, readonly) NSDate *timePressedPlay;
@end

@implementation HMVideoPlayerVC
@synthesize videoPlayer = _videoPlayer;

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    _isFullscreen = NO;
    _movieTempFullscreenBackgroundView = [[UIView alloc] init];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    self.videoPlayer.fullscreen = YES;
    [self play];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [self.videoPlayer stop];
    [self removeObservers];
}

#pragma mark - The video player
-(MPMoviePlayerController *)videoPlayer
{
    if (_videoPlayer) return _videoPlayer;
    _videoPlayer = [[MPMoviePlayerController alloc] init];
    _videoPlayer.view.frame = self.view.bounds;
    _videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
    _videoPlayer.controlStyle = MPMovieControlStyleFullscreen;
    _videoPlayer.shouldAutoplay = YES;
    _videoPlayer.view.alpha = 1;
    /*_videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;*/
    [self.view addSubview:self.videoPlayer.view];
    return _videoPlayer;
}


#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerPlaybackDidFinish:)
                     name:MPMoviePlayerPlaybackDidFinishNotification
                   object:self.videoPlayer];
    
    [nc addUniqueObserver:self
                 selector:@selector(onMoviePlayerDidExitFullscreen:)
                     name:MPMoviePlayerDidExitFullscreenNotification
                   object:self.videoPlayer];
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:self.videoPlayer];
}


-(void)onMoviePlayerDidExitFullscreen:(NSNotification *)notification
{
    [self.videoPlayer stop];
    if ([self.delegate respondsToSelector:@selector(videoPlayerStopped)]) [self.delegate videoPlayerStopped];
}

-(void)onMoviePlayerPlaybackDidFinish:(NSNotification *)notification
{
    [self.videoPlayer stop];
    if ([self.delegate respondsToSelector:@selector(videoPlayerFinishedPlaying)]) [self.delegate videoPlayerFinishedPlaying];
}

-(void)setFullScreen
{
    [self setFullScreen:YES animated:YES];
}

- (void)setFullScreen:(BOOL)fullscreen animated:(BOOL)animated {
    _isFullscreen = fullscreen;
    CGFloat fullscreenAnimationDuration = 0.4;
    if (fullscreen) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerWillEnterFullscreenNotification object:nil];
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        if (!keyWindow) {
            keyWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
        }
        if (CGRectEqualToRect(self.movieTempFullscreenBackgroundView.frame, CGRectZero)) {
            [self.movieTempFullscreenBackgroundView setFrame:keyWindow.bounds];
        }
        [keyWindow addSubview:self.movieTempFullscreenBackgroundView];
        
        self.movieTempFullscreenBackgroundView.alpha = 0.f;
        [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.alpha = 0.f;
            self.movieTempFullscreenBackgroundView.alpha = 1.f;
        } completion:^(BOOL finished) {
            [self.movieTempFullscreenBackgroundView addSubview:self.view];
            UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            [self rotateMoviePlayerForOrientation:currentOrientation animated:NO completion:^{
                [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.view.alpha = 1.f;
                } completion:^(BOOL finished) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidEnterFullscreenNotification object:nil];
                    //                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationWillChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
                    
                    self.videoPlayer.view.frame = self.movieTempFullscreenBackgroundView.bounds;
                }];
            }];
        }];
        
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerWillExitFullscreenNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.alpha = 0;
            self.movieTempFullscreenBackgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            //[self moviePlayerWillMoveFromWindow];
            [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.view.alpha = 1;
            } completion:^(BOOL finished) {
                [self.movieTempFullscreenBackgroundView removeFromSuperview];
                [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidExitFullscreenNotification object:nil];
            }];
        }];
    }
}

- (void)rotateMoviePlayerForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void (^)(void))completion {
    CGFloat angle;
    CGSize windowSize = [UIApplication sizeInOrientation:orientation];
    CGRect backgroundFrame;
    CGRect movieFrame;
    
    CGFloat movieBackgroundPadding = 0;
    
    //[self updateScalingModeForOrientation:orientation];
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, -movieBackgroundPadding, windowSize.width + movieBackgroundPadding*2, windowSize.height + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.width - movieBackgroundPadding*2, backgroundFrame.size.height - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI_2;
            backgroundFrame = CGRectMake([self statusBarHeightInOrientation:orientation] - movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding*2, windowSize.width + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding*2, backgroundFrame.size.width - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, -movieBackgroundPadding, windowSize.height + movieBackgroundPadding*2, windowSize.width + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.height - movieBackgroundPadding*2, backgroundFrame.size.width - movieBackgroundPadding*2);
            break;
        case UIInterfaceOrientationPortrait:
        default:
            angle = 0.f;
            backgroundFrame = CGRectMake(-movieBackgroundPadding, [self statusBarHeightInOrientation:orientation] - movieBackgroundPadding, windowSize.width + movieBackgroundPadding*2, windowSize.height + movieBackgroundPadding*2);
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, backgroundFrame.size.width - movieBackgroundPadding*2, backgroundFrame.size.height - movieBackgroundPadding*2);
            break;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.movieTempFullscreenBackgroundView.transform = CGAffineTransformMakeRotation(angle);
            self.movieTempFullscreenBackgroundView.frame = backgroundFrame;
            self.view.frame = movieFrame;
        } completion:^(BOOL finished) {
            if (completion)
                completion();
        }];
    } else {
        self.movieTempFullscreenBackgroundView.transform = CGAffineTransformMakeRotation(angle);
        self.movieTempFullscreenBackgroundView.frame = backgroundFrame;
        self.view.frame = movieFrame;
        if (completion)
            completion();
    }
}

- (CGFloat)statusBarHeightInOrientation:(UIInterfaceOrientation)orientation {
    if ([UIDevice iOSVersion] >= 7.0)
        return 0.f;
    else if ([UIApplication sharedApplication].statusBarHidden)
        return 0.f;
    return 20.f;
}

-(void)play
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // The UI / interface command to play the video.
        // Will update the UI, and the vide video player to start to play the video.
        [self playVideo];
    });
}

-(void)playVideo
{
    // Telling the video player what the url is,
    // and prepare to play the video.
    self.waitingToStartPlayingTheFile = YES;
    [self.videoPlayer prepareToPlay];
    self.videoPlayer.contentURL = self.videoURL;
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
