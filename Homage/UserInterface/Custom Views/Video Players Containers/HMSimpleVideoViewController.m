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
#import "HMServer+ReachabilityMonitor.h"
#import "Mixpanel.h"
#import "HMServer+analytics.h"
#import "DB.h"
#import "HMAppDelegate.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HMCacheManager.h"
#import "HMStyle.h"
#import "HMTOSViewController.h"



@implementation UIDevice (ALSystemVersion)

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
@property (nonatomic) MPMoviePlayerController *videoPlayer;
@property (atomic) BOOL waitingToStartPlayingTheFile;
@property (atomic) BOOL isPlaying;
@property (nonatomic) NSString* viewID;


@property (atomic) BOOL rotationSensitive;
@property (nonatomic, readonly) BOOL shouldDisplayVideoLabel; // YES by default
@property (nonatomic, readonly) NSDate *timePressedPlay;
@property (nonatomic) NSTimeInterval currentPlaybackTime;

@property (nonatomic) BOOL playPortrait;
@property (nonatomic) BOOL userPaused;

@property (nonatomic) BOOL reportedMovieStartedPlaying;

@property (nonatomic) BOOL markedAsDone;

@property (nonatomic) NSString *cachedVideoURL;
@property (nonatomic) BOOL isPlayedFromCache;

@end

@implementation HMSimpleVideoViewController

@synthesize videoPlayer = _videoPlayer;
@synthesize videoURL = _videoURL;

-(id)initWithDefaultNibInParentVC:(UIViewController *)parentVC containerView:(UIView *)containerView rotationSensitive:(BOOL)rotate;
{
    self = [self initWithNibNamed:@"HMSimpleVideoViewController" inParentVC:parentVC containerView:containerView rotationSensitive:(BOOL)rotate];
    if (self) {
        self.reportedMovieStartedPlaying = NO;
        self.markedAsDone = NO;
    }
    return self;
}

-(id)initWithNibNamed:(NSString *)nibName inParentVC:(UIViewController *)parentVC containerView:(UIView *)containerView rotationSensitive:(BOOL)rotate
{
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        [parentVC addChildViewController:self];
        _containerView = containerView;
        _rotationSensitive = rotate;
        _isFullscreen = NO;
        [self.containerView addSubview:self.view];
        _shouldDisplayVideoLabel = YES;
        _videoView = (HMSimpleVideoView *)self.view;
        _movieTempFullscreenBackgroundView = [[UIView alloc] init];
        [_movieTempFullscreenBackgroundView setBackgroundColor:[UIColor blackColor]];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    _isPlayedFromCache = NO;
    _cachedVideoURL = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.frame = self.containerView.bounds;
    self.containerView.clipsToBounds = YES;
    [self fixLayout];
    [self initObservers];
   
    self.videoPlayer.view.alpha = 0;
    self.videoView.guiVideoThumb.alpha = 1;
    
    self.userPaused = NO;
    
    self.playPortrait = [self shouldPlayPortrait];
    
    if (self.shouldAutoPlay)
    {
        [self updateUIToPlayVideoState];
        self.shouldAutoPlay = NO;
        [self determineIfPlayedFromCache];
        if (self.isPlayedFromCache) {
            [UIView animateWithDuration:0.2 animations:^{
                self.videoView.guiVideoThumb.alpha = 0;
            }];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self play];
        });
    }

    // ************
    // *  STYLES  *
    // ************
    self.videoView.guiVideoLabel.textColor = [HMStyle.sh colorNamed:C_VIDEO_TITLES];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

-(BOOL)shouldPlayPortrait
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    switch (orientation) {
        case UIDeviceOrientationFaceUp:
            return YES;
            break;
        case UIDeviceOrientationFaceDown:
            return YES;
            break;
        case UIDeviceOrientationPortrait:
            return YES;
        case UIDeviceOrientationPortraitUpsideDown:
            return YES;
            break;
        default:
            return NO;
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self done];
    self.videoPlayer = nil;
    [self removeObservers];
    self.videoView.guiPlayPauseButton.selected = NO;
    if (self.isFullscreen) {
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self setFullScreen:NO animated:NO forOrientation:currentOrientation];
    }
    
    if (self.shouldDisplayVideoLabel) self.videoView.guiVideoLabelContainer.hidden = NO;
    
    self.videoView.guiPlayButton.hidden = NO;
    self.videoView.guiLoadActivity.alpha = 1;
    [self videoPlaybackControlsShouldBeVisible:NO];
    [self.videoView.guiLoadActivity stopAnimating];
    self.videoView.guiLoadActivity.hidden = YES;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.videoPlayer.view.alpha = 0;
        self.videoView.guiVideoThumb.alpha = 1;
        self.videoView.guiPlayButton.alpha = 1;
        if (self.shouldDisplayVideoLabel) self.videoView.guiVideoLabelContainer.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
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
    
    [nc addUniqueObserver:self
                 selector:@selector(onMovieDurationAvailable:)
                     name:MPMovieDurationAvailableNotification
                   object:self.videoPlayer];
    
    if (self.rotationSensitive)
    {
        [nc addUniqueObserver:self
                     selector:@selector(onDeviceOrientationChanged)
                         name:UIDeviceOrientationDidChangeNotification
                       object:nil];
    }

}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:self.videoPlayer];
    [nc removeObserver:self name:MPMovieDurationAvailableNotification object:self.videoPlayer];
    if (self.rotationSensitive)
    {
        [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    }
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
    
    NSString *playbackTimeString = [NSString stringWithFormat:@"%f" , self.currentPlaybackTime];
    if (self.videoPlayer.duration != 0 && self.currentPlaybackTime >= (self.videoPlayer.duration - 1))
    {
        //the user watched the movie almost all the way
        if ([self.delegate respondsToSelector:@selector(videoPlayerDidFinishPlaying)])
        {
            [self.delegate videoPlayerDidFinishPlaying];
        }
        
        if (self.entityType && self.entityID && self.originatingScreen) {
            [[Mixpanel sharedInstance] track:@"finish_playing_video" properties:@{@"playing_entity":self.entityType , @"entity_id":self.entityID , @"total_duration":[NSString stringWithFormat:@"%f" ,self.videoPlayer.duration], @"originating_screen":self.originatingScreen}];
        }
        if (self.resetStateWhenVideoEnds) [self done];
        
    } else {
         //the user stopped the movie in the middle
        if (self.entityType && self.entityID ) {
            [[Mixpanel sharedInstance] track:@"stop_playing_video" properties:@{@"playing_entity":self.entityType , @"entity_id":self.entityID , @"playing_time":playbackTimeString , @"total_duration":[NSString stringWithFormat:@"%f" ,self.videoPlayer.duration], @"originating_screen":self.originatingScreen}];
        }
        
        if ([self.delegate respondsToSelector:@selector(videoPlayerDidStop)])
        {
            [self.delegate videoPlayerDidStop];
        }
    }
    
    NSNumber *playbackTime = [NSNumber numberWithDouble:self.currentPlaybackTime];
    NSNumber *totalDuration = [NSNumber numberWithDouble:self.videoPlayer.duration];
    
    if (self.viewID && self.entityID && self.entityType && self.originatingScreen) {
        [HMServer.sh reportVideoStopWithViewID:self.viewID forEntity:self.entityType withID:self.entityID forUserID:[User current].userID forDuration:playbackTime outOfTotalDuration:totalDuration fromOriginatingScreen:self.originatingScreen];
        self.reportedMovieStartedPlaying = NO;
    }
    
    self.currentPlaybackTime = 0;
}

-(void)onMoviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        
        // If get notification about video playing,
        // but video player already marked to be in the "done" state
        // don't play the video.
        if (self.markedAsDone) {
            [self.videoPlayer stop];
            return;
        }
        
        // Change UI to playing state.
        self.videoPlayer.view.alpha = 1;
        [self.videoView.guiLoadActivity stopAnimating];
        self.videoView.guiLoadActivity.hidden = YES;
        self.videoView.guiPlayPauseButton.selected = YES;
        self.videoView.guiVideoSlider.hidden = YES;
        
        if (!self.reportedMovieStartedPlaying) {
            if (self.entityID && self.entityType && self.originatingScreen != nil) {
                [[Mixpanel sharedInstance] track:@"start_play_video" properties:@{@"playing_entity":self.entityType, @"entity_id":self.entityID, @"originating_screen":self.originatingScreen}];
                self.viewID = [HMServer.sh generateBSONID];
                [HMServer.sh reportVideoStartWithViewID:self.viewID forEntity:self.entityType withID:self.entityID forUserID:[User current].userID fromOriginatingScreen:self.originatingScreen];
            }
            self.reportedMovieStartedPlaying = YES;
        }
        
    } else if (self.videoPlayer.playbackState == MPMoviePlaybackStatePaused) {

        if (!self.userPaused)
        {
            self.videoView.guiLoadActivity.hidden = NO;
            [self.videoView.guiLoadActivity startAnimating];
        }         
        self.userPaused = NO;
        
        self.videoView.guiPlayPauseButton.selected = NO;
        self.videoView.guiVideoSlider.hidden = NO;
        self.videoView.guiVideoSlider.value = self.videoPlayer.currentPlaybackTime / self.videoPlayer.duration;
        
    } else {
        
        [self.videoView.guiLoadActivity stopAnimating];
        self.videoView.guiLoadActivity.hidden = YES;
        self.videoView.guiPlayPauseButton.selected = NO;
        self.videoView.guiVideoSlider.hidden = NO;
        self.videoView.guiVideoSlider.value = self.videoPlayer.currentPlaybackTime / self.videoPlayer.duration;
        
    }
    
    self.currentPlaybackTime = self.videoPlayer.currentPlaybackTime;
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
    if (self.waitingToStartPlayingTheFile == NO)
    {
        return;
    }
    NSTimeInterval animationDuration = 0.4;
    [UIView animateWithDuration:animationDuration animations:^{
        self.videoView.guiVideoThumb.alpha = 0;
        [self.videoView.guiLoadActivity stopAnimating];
        self.videoView.guiLoadActivity.hidden = YES;
        self.videoView.backgroundColor = [UIColor clearColor];
        self.videoPlayer.backgroundView.backgroundColor = [UIColor clearColor];
        self.videoView.alpha = 1;
    } completion:^(BOOL finished) {
        if (self.waitingToStartPlayingTheFile == YES)
        {
            [self.videoPlayer play];
            HMGLogDebug(@"============== Video player: starting to play video ============");
            self.waitingToStartPlayingTheFile = NO;
        }
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

-(void)setThumbURL:(NSURL *)thumbURL
{
    self.videoView.guiVideoThumb.alpha = 0;
    [self.videoView.guiVideoThumb sd_setImageWithURL:thumbURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [self setVideoImage:image];
        if (cacheType == SDImageCacheTypeNone) {
            // Reveal with animation
            [UIView animateWithDuration:0.2 animations:^{
                self.videoView.guiVideoThumb.alpha = 1;
            }];
        } else {
            // Reveal with no animation.
            self.videoView.guiVideoThumb.alpha = 1;
        }
    }];
}

-(NSString *)videoLabelText
{
    return self.videoView.guiVideoLabel.text;
}

-(void)setVideoLabelText:(NSString *)videoLabelText
{
    self.videoView.guiVideoLabel.text = videoLabelText;
    self.videoView.guiVideoLabel.textColor = [HMStyle.sh colorNamed:C_VIDEO_TITLES];
}

-(void)updateUIToPlayVideoState
{
    self.videoView.guiLoadActivity.hidden = NO;
    [self.videoView.guiLoadActivity startAnimating];
    self.videoView.guiPlayPauseButton.selected = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.videoView.guiPlayButton.alpha = 0;
        self.videoView.guiVideoLabelContainer.alpha = 0;
        self.videoView.guiVideoLabel.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        self.videoView.guiVideoLabelContainer.hidden = YES;
        self.videoView.guiPlayButton.hidden = YES;
        self.videoView.guiVideoLabel.transform = CGAffineTransformIdentity;

    }];
}

#pragma mark - The video player
-(MPMoviePlayerController *)videoPlayer
{
    if (_videoPlayer) return _videoPlayer;
    _videoPlayer =[[MPMoviePlayerController alloc] init];
    _videoPlayer.view.frame = self.videoView.guiVideoContainer.bounds;
    _videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
    _videoPlayer.controlStyle = MPMovieControlStyleNone;
    _videoPlayer.shouldAutoplay = NO;
    _videoPlayer.view.alpha = 1;
    _videoPlayer.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth |
                                            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [self.videoView.guiVideoContainer addSubview:self.videoPlayer.view];
    return _videoPlayer;
}

-(void)extractThumbFromVideo
{
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

-(void)play
{
    if (![HMServer.sh isReachable])
    {
        return;
    }
    
    
    if ([self.delegate respondsToSelector:@selector(videoPlayerWasFired)]) [self.delegate videoPlayerWasFired];
    self.waitingToStartPlayingTheFile = YES;
    self.markedAsDone = NO;
    self.videoPlayer.shouldAutoplay = YES;
    [self updateUIToPlayVideoState];
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
    _timePressedPlay = [NSDate date];
    HMGLogDebug(@"Trying to play video at:%@", [[NSURL URLWithString:self.videoURL] description]);
    [self.videoView.guiVideoContainer addSubview:self.videoPlayer.view];
    [self.videoPlayer prepareToPlay];
    //if (!self.videoPlayer.contentURL) self.videoPlayer.contentURL = [NSURL URLWithString:self.videoURL];
    self.videoPlayer.contentURL = [NSURL URLWithString:self.videoURL];
    if ([self.delegate respondsToSelector:@selector(videoPlayerWillPlay)]) [self.delegate videoPlayerWillPlay];
    self.isPlaying = YES;
}

-(void)done
{
    self.markedAsDone = YES;
    self.isPlaying = NO;
    self.waitingToStartPlayingTheFile = NO;
    [self.videoPlayer stop];
    self.videoView.guiPlayPauseButton.selected = NO;
    if (self.isFullscreen) {
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        [self setFullScreen:NO animated:NO forOrientation:currentOrientation];
    }

    if (self.shouldDisplayVideoLabel) self.videoView.guiVideoLabelContainer.hidden = NO;
    
    self.videoView.guiPlayButton.hidden = NO;
    self.videoView.guiLoadActivity.alpha = 1;
    [self videoPlaybackControlsShouldBeVisible:NO];
    [self.videoView.guiLoadActivity stopAnimating];
    self.videoView.guiLoadActivity.hidden = YES;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.videoPlayer.view.alpha = 0;
        self.videoView.guiVideoThumb.alpha = 1;
        self.videoView.guiPlayButton.alpha = 1;
        if (self.shouldDisplayVideoLabel) self.videoView.guiVideoLabelContainer.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.shouldAllowStatusBar = YES;
    [self setNeedsStatusBarAppearanceUpdate];

    
    if ([self.delegate respondsToSelector:@selector(videoPlayerIsDone)]) {
        [self.delegate performSelector:@selector(videoPlayerIsDone)];
    }

}




-(void)hideVideoLabel
{
    [self hideVideoLabelAnimated:NO];
}

-(void)hideVideoLabelAnimated:(BOOL)animated
{
    _shouldDisplayVideoLabel = NO;
    
    if (!animated) {
        self.videoView.guiVideoLabelContainer.hidden = YES;
        return;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.videoView.guiVideoLabelContainer.alpha = 0;
    } completion:^(BOOL finished) {
        self.videoView.guiVideoLabelContainer.alpha = 0;
        self.videoView.guiVideoLabelContainer.hidden = YES;
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
        self.videoView.guiVideoLabelContainer.hidden = NO;
        return;
    }
    
    self.videoView.guiVideoLabelContainer.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.videoView.guiVideoLabelContainer.alpha = 1;
    } completion:^(BOOL finished) {
        self.videoView.guiVideoLabelContainer.alpha = 1;
    }];
}

-(void)setFullScreen
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self setFullScreenForOrientation:orientation];
}

-(void)setFullScreenForOrientation:(UIInterfaceOrientation)orientation
{
    [self setFullScreen:YES animated:NO forOrientation:orientation];
}

- (void)setFullScreen:(BOOL)fullscreen animated:(BOOL)animated forOrientation:(UIInterfaceOrientation)orientation {
    _isFullscreen = fullscreen;
    CGFloat fullscreenAnimationDuration = 0.1;
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
        
        //self.movieTempFullscreenBackgroundView.alpha = 0.f;
        [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.view.alpha = 0.f;
            self.movieTempFullscreenBackgroundView.alpha = 1.f;
        } completion:^(BOOL finished) {
            //HMGLogDebug(@" ===================== printing view properties ======================== ");
            //[self printViewProperties:self.movieTempFullscreenBackgroundView name:@"movieTempFullscreenBackgroundView"];
            //[self printViewProperties:self.view name:@"self.view"];
            [self.movieTempFullscreenBackgroundView addSubview:self.view];
            //UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            UIInterfaceOrientation currentOrientation = orientation;
            [self rotateMoviePlayerForOrientation:currentOrientation animated:NO completion:^{
                self.videoView.frame = self.movieTempFullscreenBackgroundView.bounds;
                self.videoView.guiVideoContainer.frame = self.videoView.bounds;
                self.videoPlayer.view.frame = self.movieTempFullscreenBackgroundView.bounds;
                [UIView animateWithDuration:animated ? fullscreenAnimationDuration : 0.0 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.view.alpha = 1.f;
                } completion:^(BOOL finished) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerDidEnterFullscreenNotification object:nil];

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
    //[self displayRectBounds:self.view.frame Name:@"view.frame"];
    self.view.frame = self.containerView.bounds;
    self.videoView.frame = self.containerView.bounds;
    //TODO: verify with aviv if this is the correct fix
    //if (self.videoView.guiVideoContainer.bounds.size.width != 0 && self.videoView.guiVideoContainer.bounds.size.height != 0)
    self.videoPlayer.view.frame = self.containerView.bounds;
    
}

-(void)setFrame:(CGRect)frame
{
    self.containerView.frame = frame;
    self.containerView.layer.borderColor = [UIColor redColor].CGColor;
    self.containerView.layer.borderWidth = 2.0;
    //[self fixLayout];
}

- (void)moviePlayerWillMoveFromWindow {
    
    if (CGRectEqualToRect(self.containerView.frame , CGRectZero))
    {
       [self done]; 
    }
    
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

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    double delayInSeconds = duration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self updateScalingModeForOrientation:toInterfaceOrientation];
    });
}

-(void)onDeviceOrientationChanged
{
    if (!self.waitingToStartPlayingTheFile && !self.isPlaying) return;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    HMGLogDebug(@"device orientation is now: %ld" , (long)[[UIDevice currentDevice] orientation]);

    switch (orientation) {
        case UIDeviceOrientationLandscapeLeft:
            [self setFullScreenForOrientation:UIInterfaceOrientationLandscapeRight];
            break;
        
        case UIDeviceOrientationLandscapeRight:
            [self setFullScreenForOrientation:UIInterfaceOrientationLandscapeLeft];
            break;
        
        case UIDeviceOrientationPortrait:
            if (CGRectEqualToRect(self.containerView.frame , CGRectZero)) {
                [self setFullScreen:YES animated:YES forOrientation:UIInterfaceOrientationPortrait];
            } else {
                [self setFullScreen:NO animated:YES forOrientation:UIInterfaceOrientationPortrait];
            }
            break;
        default:
            break;
    }

    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.shouldAllowStatusBar = !UIDeviceOrientationIsLandscape(orientation) && orientation != UIDeviceOrientationFaceUp;
    [self setNeedsStatusBarAppearanceUpdate];
}


-(void)updateScalingModeForOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        _videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
    } else {
        _videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
    }
}

- (void)rotateMoviePlayerForOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated completion:(void (^)(void))completion {
    CGFloat angle;
    CGSize windowSize = [UIApplication sizeInOrientation:orientation];
    CGRect backgroundFrame;
    CGRect movieFrame;
    
    CGFloat movieBackgroundPadding = 0;
    
    [self updateScalingModeForOrientation:orientation];
    
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
            movieFrame = CGRectMake(movieBackgroundPadding, movieBackgroundPadding, windowSize.height - movieBackgroundPadding*2, windowSize.width - movieBackgroundPadding*2);
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
    return (self.isPlaying || self.waitingToStartPlayingTheFile);
}

-(void)pause
{
    if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        self.userPaused = YES;
        [self.videoPlayer pause];
        self.videoView.guiPlayPauseButton.selected = NO;
    }
}

-(void)setScalingMode:(NSString *)scale
{
    
    if ([scale isEqualToString:@"aspect fit"])
    {
         _videoPlayer.scalingMode = MPMovieScalingModeAspectFit;
    }
}

#pragma mark - Show/Hide controls
-(void)videoPlaybackControlsShouldBeVisible:(BOOL)shouldBeVisible
{
    self.videoView.guiControlsContainer.hidden = !shouldBeVisible;
    if ([self.delegate respondsToSelector:@selector(videoPlayerIsShowingPlaybackControls:)]) {
        [self.delegate performSelector:@selector(videoPlayerIsShowingPlaybackControls:) withObject:@(shouldBeVisible)];
    }
}

#pragma mark - Cached videos
-(NSString *)videoURL
{
    if (self.cachedVideoURL) return _cachedVideoURL;
    return _videoURL;
}

-(void)setVideoURL:(NSString *)videoURL
{
    _videoURL = videoURL;
}

-(void)determineIfPlayedFromCache
{
    [self videoURL];
    _isPlayedFromCache = _cachedVideoURL ? YES : NO;
}

-(NSString *)cachedVideoURL
{
    // Use cached video url if already set.
    if (_cachedVideoURL) return _cachedVideoURL;

    NSString *videoFile = [_videoURL lastPathComponent];
    NSArray *comp = [videoFile componentsSeparatedByString:@"."];
    NSString *fileName;
    NSString *extension;
    if (comp.count == 2) {
        fileName = comp[0];
        extension = comp[1];
    }
    if (!fileName || !extension) return nil;
    
    // Check if bundled video exists.
    NSURL *bundledURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
    if (bundledURL) {
        _cachedVideoURL = [bundledURL description];
        return _cachedVideoURL;
    }
    
    // Check if video cached in one of the caches folder.
    NSURL *cachedURL;
    HMCacheManager *cm = HMCacheManager.sh;
    
    // Cached stories
    if (!cachedURL) cachedURL = [cm urlForCachedResource:_videoURL cachePath:cm.storiesCachePath];
    
    // Cached remakes
    if (!cachedURL) cachedURL = [cm urlForCachedResource:_videoURL cachePath:cm.remakesCachePath];
    
    // If found in cache, return it.
    if (cachedURL) {
        _cachedVideoURL = [cachedURL description];
        return _cachedVideoURL;
    }
    
    // Not cached.
    return nil;
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
    MPMoviePlaybackState state = self.videoPlayer.playbackState;
    
    if (state == MPMoviePlaybackStateStopped || state == MPMoviePlaybackStatePaused) {
        [self.videoPlayer play];
        self.videoView.guiPlayPauseButton.selected = YES;
    } else if (self.videoPlayer.playbackState == MPMoviePlaybackStatePlaying) {
        self.userPaused = YES;
        [self.videoPlayer pause];
        self.videoView.guiPlayPauseButton.selected = NO;
    }
}

- (IBAction)onPressedFullScreenButton:(id)sender
{
    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    [self setFullScreen:!self.isFullscreen animated:NO forOrientation:currentOrientation];
}

- (IBAction)onPressedToggleControls:(id)sender
{
    [self videoPlaybackControlsShouldBeVisible:self.videoView.guiControlsContainer.hidden];
}


- (IBAction)onMovedSlider:(UISlider *)sender
{
    [self.videoPlayer setCurrentPlaybackTime:sender.value * self.videoPlayer.duration];
}

-(void)onMovieDurationAvailable:(NSNotification *)notification
{
    HMGLogDebug(@"duration for movie receicved: %f" , self.videoPlayer.duration);
}


@end
