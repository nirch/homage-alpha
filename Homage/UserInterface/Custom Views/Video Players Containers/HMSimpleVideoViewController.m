//
//  HMSimpleVideoViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@import MediaPlayer;
@import AVFoundation;

#import "HMSimpleVideoViewController.h"
#import "HMNotificationCenter.h"

@implementation UIDevice (ALSystemVersion)

static const CGFloat movieBackgroundPadding = 0.f;
static const NSTimeInterval fullscreenAnimationDuration = 0.3;

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
@interface HMSimpleVideoViewController ()

@property (nonatomic, readonly) BOOL isFullscreen;
@property (nonatomic, readonly, weak) UIView *containerView;
@property (nonatomic, readonly) UIView *movieTempFullscreenBackgroundView;
@property (nonatomic, readonly) MPMoviePlayerController *videoPlayer;
@property (atomic) BOOL waitingToStartPlayingTheFile;
@property (nonatomic, readonly) BOOL shouldDisplayVideoLabel; // YES by default
@property (nonatomic, readonly) NSDate *timePressedPlay;

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
        _containerView = containerView;
        _isFullscreen = NO;
        [self.containerView addSubview:self.view];
        _shouldDisplayVideoLabel = YES;
        _videoView = (HMSimpleVideoView *)self.view;

        
        _movieTempFullscreenBackgroundView = [[UIView alloc] init];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.frame = self.containerView.bounds;
    self.containerView.clipsToBounds = YES;

    [self fixLayout];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initObservers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
    if (self.resetStateWhenVideoEnds) [self done];
}

-(void)onMoviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        self.videoPlayer.view.alpha = 1;
        [self.videoView.guiLoadActivity stopAnimating];
        self.videoView.guiPlayPauseButton.selected = YES;
        self.videoView.guiVideoSlider.hidden = YES;
    } else {
        self.videoView.guiPlayPauseButton.selected = NO;
        self.videoView.guiVideoSlider.hidden = NO;
        self.videoView.guiVideoSlider.value = self.videoPlayer.currentPlaybackTime / self.videoPlayer.duration;
    }
}

-(void)onMoviePlayerDidExitFullscreen:(NSNotification *)notification
{
    self.videoPlayer.controlStyle = MPMovieControlStyleNone;
    if ([self.delegate respondsToSelector:@selector(videoPlayerDidExitFullScreen)]) {
        [self.delegate videoPlayerDidExitFullScreen];
    }
}

-(void)_startToPlayTheActualVideo
{
    self.waitingToStartPlayingTheFile = NO;
    
    // If no time passed since play, don't do the fade out animation.
    if ([[NSDate date] timeIntervalSinceDate:self.timePressedPlay] < 3.0f) {
        self.videoView.alpha = 1;
        [self.videoPlayer play];
        return;
    }
    
    
    NSTimeInterval animationDuration = 0.4;
    [UIView animateWithDuration:animationDuration animations:^{
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
    self.videoView.guiPlayPauseButton.selected = YES;
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

-(void)extractThumbFromVideo
{
    //if (!self.extractThumbAtTime) return;
    
    NSURL *url = [NSURL URLWithString:self.videoURL];
    AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:url options:nil];

    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    NSError *error;
    CMTime time = CMTimeMake(1, 2);
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:&error];
    if (error) return;
    self.videoImage = [[UIImage alloc] initWithCGImage:imageRef];
}

-(void)playVideo
{
    _timePressedPlay = [NSDate date];
    self.waitingToStartPlayingTheFile = YES;
    NSURL *url = [NSURL URLWithString:self.videoURL];
    HMGLogDebug(@"Trying to play video at:%@", url);
    if (!self.videoPlayer.contentURL) self.videoPlayer.contentURL = [NSURL URLWithString:self.videoURL];
    [self.videoPlayer prepareToPlay];
    if ([self.delegate respondsToSelector:@selector(videoPlayerWillPlay)]) [self.delegate videoPlayerWillPlay];
}

-(void)done
{
    [self.videoPlayer stop];
    self.videoView.guiPlayPauseButton.selected = NO;
    if ([self.delegate respondsToSelector:@selector(videoPlayerDidStop)]) [self.delegate videoPlayerDidStop];
    if (self.isFullscreen) {
        [self setFullScreen:NO animated:YES];
    }

    if (self.shouldDisplayVideoLabel) self.videoView.guiVideoLabel.hidden = NO;
    
    self.videoView.guiPlayButton.hidden = NO;
    self.videoView.guiLoadActivity.alpha = 1;
    self.videoView.guiControlsContainer.hidden = YES;
    [self.videoView.guiLoadActivity stopAnimating];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.videoPlayer.view.alpha = 0;
        self.videoView.guiVideoThumb.alpha = 1;
        self.videoView.guiPlayButton.alpha = 1;
        if (self.shouldDisplayVideoLabel) self.videoView.guiVideoLabel.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];}

-(void)play
{
    [self updateUIToPlayVideoState];
    [self playVideo];
}

-(void)hideVideoLabel
{
    [self hideVideoLabelAnimated:NO];
}

-(void)hideVideoLabelAnimated:(BOOL)animated
{
    _shouldDisplayVideoLabel = NO;
    
    if (!animated) {
        self.videoView.guiVideoLabel.hidden = YES;
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.videoView.guiVideoLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.videoView.guiVideoLabel.alpha = 0;
        self.videoView.guiVideoLabel.hidden = YES;
    }];
}

-(void)showVideoLabel
{
    [self showVideoLabelAnimated:NO];
}

-(void)showVideoLabelAnimated:(BOOL)animated
{
    _shouldDisplayVideoLabel = YES;
    
    if (!animated) {
        self.videoView.guiVideoLabel.hidden = NO;
        return;
    }
    
    self.videoView.guiVideoLabel.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.videoView.guiVideoLabel.alpha = 1;
    } completion:^(BOOL finished) {
        self.videoView.guiVideoLabel.alpha = 1;
    }];
}

//-(void)setFullScreen
//{
//    if (self.isFullScreen) return;
//    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
//
//    [self.view removeFromSuperview];
//    [keyWindow addSubview:self.view];
//    
////    if (!self.videoPlayer.isFullscreen) {
////        self.videoPlayer.controlStyle = MPMovieControlStyleFullscreen;
////        [self.videoPlayer setFullscreen:YES animated:YES];
////    }
//}

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

                    self.videoView.frame = self.movieTempFullscreenBackgroundView.bounds;
                    self.videoView.guiVideoContainer.frame = self.videoView.bounds;
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
            [self moviePlayerWillMoveFromWindow];
            [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.view.alpha = 1;
            } completion:^(BOOL finished) {
                [self.movieTempFullscreenBackgroundView removeFromSuperview];
                [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidExitFullscreenNotification object:nil];
            }];
        }];
    }
}


-(void)fixLayout
{
    self.view.frame = self.containerView.bounds;
    self.videoPlayer.view.frame = self.videoView.guiVideoContainer.bounds;
}

- (void)moviePlayerWillMoveFromWindow {
    
    if (![self.containerView.subviews containsObject:self.view]) {
        [self.containerView addSubview:self.view];
    }
    [self fixLayout];
}

- (CGFloat)statusBarHeightInOrientation:(UIInterfaceOrientation)orientation {
    if ([UIDevice iOSVersion] >= 7.0)
    return 0.f;
    else if ([UIApplication sharedApplication].statusBarHidden)
    return 0.f;
    return 20.f;
}

- (void)rotateMoviePlayerForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void (^)(void))completion {
    CGFloat angle;
    CGSize windowSize = [UIApplication sizeInOrientation:orientation];
    CGRect backgroundFrame;
    CGRect movieFrame;
    
    CGFloat movieBackgroundPadding = 0;
    
    
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
        self.videoView.guiPlayPauseButton.selected = YES;
    } else if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        [self.videoPlayer pause];
        self.videoView.guiPlayPauseButton.selected = NO;
    }
}

- (IBAction)onPressedFullScreenButton:(id)sender
{
    [self setFullScreen:!self.isFullscreen animated:YES];
}

- (IBAction)onPressedToggleControls:(id)sender
{
    self.videoView.guiControlsContainer.hidden = !self.videoView.guiControlsContainer.hidden;
}

- (IBAction)onMovedSlider:(UISlider *)sender
{
    [self.videoPlayer setCurrentPlaybackTime:sender.value * self.videoPlayer.duration];
}


@end
