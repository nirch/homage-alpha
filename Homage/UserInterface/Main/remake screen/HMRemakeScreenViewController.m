//
//  HMRemakeScreenViewController.m
//  Homage
//
//  Created by Aviv Wolf on 10/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakeScreenViewController.h"
#import "DB.h"
#import "HMSimpleVideoViewController.h"
#import "HMServer+analytics.h"
#import "HMServer+Likes.h"
#import "HMNotificationCenter.h"
#import "HMSharing.h"
#import "Mixpanel.h"
#import "HMServer+Remakes.h"
#import "HMRegularFontLabel.h"
#import "HMRegularFontLabel.h"
#import "HMStyle.h"
#import "HMServer+AppConfig.h"

#define ALERT_VIEW_TAG_SHARE_FAILED 100

@interface HMRemakeScreenViewController ()

@property (nonatomic) BOOL markedAsDone;

// Remake button
@property (weak, nonatomic) IBOutlet UIButton *guiRemakeButton;

// More remakes headline
@property (weak, nonatomic) IBOutlet UIView *guiMoreRemakesHeadlineContainer;
@property (weak, nonatomic) IBOutlet UIView *guiMoreRemakesHeadlineBG;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiMoreRemakesHeadlineLabel;


// Movie player & transitions
@property (weak, nonatomic) IBOutlet UIScrollView *guiScrollView;
@property (nonatomic) HMSimpleVideoViewController *remakeMoviePlayer;
@property (weak, nonatomic) IBOutlet UIView *guiDismissOnTouchBG;
@property (weak, nonatomic) IBOutlet UIView *guiRemakeContainer;
@property (weak, nonatomic) IBOutlet UIView *guiRemakeVideoContainer;
@property (nonatomic) CGAffineTransform dismissTransform;
@property (nonatomic) CGFloat scale;

// Remake Controls Containers
@property (weak, nonatomic) IBOutlet UIView *guiRemakeControlsConatinerTop;
@property (weak, nonatomic) IBOutlet UIView *guiRemakeControlsConatinerBottom;
@property (nonatomic) CGPoint bottomControlsCenter;
@property (weak, nonatomic) IBOutlet UIButton *guiOverlayPlayButton;

// User, Likes and views
@property (weak, nonatomic) IBOutlet UIImageView *guiUserIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiUserFullName;
@property (weak, nonatomic) IBOutlet UIImageView *guiLikesIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiLikesCounterLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiViewsIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiViewsCounterLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiLikeButton;

// Sharing
@property (weak, nonatomic) IBOutlet UIButton *guiShareButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiShareActivity;

@property (nonatomic) HMSharing *currentSharer;

// Remake
@property (nonatomic) Remake *remake;

// More options overlay
@property (weak, nonatomic) IBOutlet UIView *guiMoreOptionsContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiReportFlagButton;


@end

@implementation HMRemakeScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.bottomControlsCenter = self.guiRemakeControlsConatinerBottom.center;
    [self initGUI];
    [self initObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeObservers];
    self.remakeMoviePlayer.delegate = nil;
    self.guiScrollView.delegate = nil;
}

#pragma mark - Initializations
-(void)initGUI
{
    // Delegates
    self.remakeMoviePlayer.delegate = self;
    self.guiScrollView.delegate = self;
    
    // ************
    // *  STYLES  *
    // ************
    
    // More remakes label
    self.guiMoreRemakesHeadlineContainer.backgroundColor = [HMStyle.sh colorNamed:C_SD_MORE_REMAKES_TITLE_BG];
    self.guiMoreRemakesHeadlineLabel.textColor = [HMStyle.sh colorNamed:C_SD_MORE_REMAKES_TITLE_TEXT];

    // Make your own button
    self.guiRemakeButton.backgroundColor = [HMStyle.sh colorNamed:C_SD_REMAKE_BUTTON_BG];
    [self.guiRemakeButton setTitleColor:[HMStyle.sh colorNamed:C_SD_REMAKE_BUTTON_TEXT] forState:UIControlStateNormal];
    
    // Text labels with info overlaying the remake.
    UIColor *textColor = [HMStyle.sh colorNamed:C_SD_REMAKE_INFO_TEXT];
    [self.guiLikeButton setTitleColor:textColor forState:UIControlStateNormal];
    self.guiViewsCounterLabel.textColor = textColor;
    self.guiLikesCounterLabel.textColor = textColor;
    self.guiUserFullName.textColor = textColor;
}

-(void)prepareForRemake:(Remake *)remake animateFromRect:(CGRect)s fromCenter:(CGPoint)fromCenter
{
    // Keep a reference to the remake
    self.remake = remake;
    
    // Initialize video player.
    [self initVideoPlayerWithRemake:remake];
    
    // Update remake info
    [self updateInfoForRemake];
    
    // Update the make your own button (opened or locked?)
    [self updateMakeYourOwnButton];

    
    // Init the transform for the reveal animation
    CGRect t = self.guiRemakeContainer.frame;
    CGPoint toCenter = self.guiScrollView.center;
    
    // Calc the values (no need to calculate more than once).
    if (self.scale == 0) {
        self.scale = s.size.width / t.size.width;
    }
    CGFloat deltaX = fromCenter.x - toCenter.x;
    CGFloat deltaY = fromCenter.y - toCenter.y;

    // Start position transform
    CGAffineTransform transform = CGAffineTransformMakeTranslation(deltaX, deltaY);
    transform = CGAffineTransformScale(transform, self.scale, self.scale);
    self.guiRemakeContainer.transform = transform;
    self.dismissTransform = transform;
    
    // Enable buttons
    self.guiLikeButton.userInteractionEnabled = YES;
    
    [self resetRemakeVideoPlayer];
    
    // Animate to the target position defined by layout.
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.75 initialSpringVelocity:0.3 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.guiRemakeContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
    
}

-(void)updateInfoForRemake
{
    // User full name
    if (self.remake.userFullName && self.remake.userFullName.length > 0) {
        self.guiUserFullName.text = self.remake.userFullName;
        self.guiUserIcon.hidden = NO;
    } else {
        self.guiUserFullName.text = @"";
        self.guiUserIcon.hidden = YES;
    }
    
    // Likes counter
    if (self.remake.likesCount && self.remake.likesCount.integerValue > 0) {
        self.guiLikesCounterLabel.text = [NSString stringWithFormat:@"%@", self.remake.likesCount];
        self.guiLikesCounterLabel.alpha = 1.0;
        self.guiLikesIcon.alpha = 1.0;
    } else {
        self.guiLikesCounterLabel.text = @"0";
        self.guiLikesCounterLabel.alpha = 0.3;
        self.guiLikesIcon.alpha = 0.3;
    }
    
    // Views counter
    if (self.remake.viewsCount && self.remake.viewsCount.integerValue > 0) {
        self.guiViewsCounterLabel.text = [NSString stringWithFormat:@"%@", self.remake.viewsCount];
        self.guiViewsCounterLabel.alpha = 1.0;
        self.guiViewsIcon.alpha = 1.0;
    } else {
        self.guiViewsCounterLabel.text = @"0";
        self.guiViewsCounterLabel.alpha = 0.3;
        self.guiViewsIcon.alpha = 0.3;
    }
    
    // Update Like Button
    [self updateLikeButtonToState:[self.remake isLikedByCurrentUser]];
}

-(void)updateLikeButtonToState:(BOOL)liked
{
    if (liked) {
        [self.guiLikeButton setTitle:LS(@"UNLIKE_BUTTON_LABEL") forState:UIControlStateNormal];
        [self.guiLikeButton setImage:[UIImage imageNamed:@"likedIcon"] forState:UIControlStateNormal];
    } else {
        [self.guiLikeButton setTitle:LS(@"LIKE_BUTTON_LABEL") forState:UIControlStateNormal];
        [self.guiLikeButton setImage:[UIImage imageNamed:@"likesIcon"] forState:UIControlStateNormal];
    }
}

#pragma mark - Observers
-(void)initObservers
{
    
    // Observe remake creation
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onLikeStatusUpdated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_LIKED_REMAKE
                                                     object:nil];
    
    // Observe refetching of remakes for StoryID
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onLikeStatusUpdated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_UNLIKED_REMAKE
                                                     object:nil];
    
    // Observe share request
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onShareRemakeRequest:)
                                                       name:HM_NOTIFICATION_SERVER_SHARE_REMAKE_REQUEST
                                                     object:nil];
    
}

-(void)removeObservers
{
    
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_LIKED_REMAKE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_UNLIKED_REMAKE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SHARE_REMAKE_REQUEST object:nil];
}

#pragma mark - Observers handlers
-(void)onLikeStatusUpdated:(NSNotification *)notification
{
    self.guiLikeButton.userInteractionEnabled = YES;
    NSDictionary *info = notification.userInfo;
    NSString *remakeID = info[@"remake_id"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (remake != nil && info[@"liked_remake"] != nil) {
        NSString *eventName = [info[@"liked_remake"] boolValue] ? @"UserLikedRemake" : @"UserUnlikedRemake";
        NSString *userID = info[@"user_id"];
        NSString *storyID = remake.story.sID;
        if (userID != nil && storyID != nil) {
            NSDictionary *properties = @{
                                         @"user_id":userID,
                                         @"story_id":storyID,
                                         @"remake_id":remakeID
                                         };
            [[Mixpanel sharedInstance] track:eventName properties:properties];
        }
    }
    [self updateInfoForRemake];
}

-(void)onShareRemakeRequest:(NSNotification *)notification
{
    if (notification.isReportingError) {
        // Failed to request a share remake object from the server.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LS(@"SHARE_REMAKE_FAILED_TITLE")
                                                            message:LS(@"SHARE_REMAKE_FAILED_BODY")
                                                           delegate:self
                                                  cancelButtonTitle:LS(@"CANCEL_BUTTON")
                                                  otherButtonTitles:LS(@"TRY_AGAIN_BUTTON"), nil];
        alertView.tag = ALERT_VIEW_TAG_SHARE_FAILED;
        [alertView show];
        return;
    }
    
    // No error reported.
    // The share bundle is ready for sharing.
    // Open the ui for the user.
    NSDictionary *shareBundle = notification.userInfo[@"share_bundle"];
    [self.currentSharer shareRemakeBundle:shareBundle
                                 parentVC:self
                           trackEventName:@"SDShareRemake"
                                thumbnail:self.remakeMoviePlayer.videoImage
                               sourceView:self.guiShareButton];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.guiShareButton.hidden = NO;
        [self.guiShareActivity stopAnimating];
        self.currentSharer = nil;
    });
}

#pragma mark - Make your own button
-(void)updateMakeYourOwnButton
{
    if (self.remake.story.isPremiumAndLocked && [HMServer.sh supportsInAppPurchases]) {
        [self.guiRemakeButton setImage:[UIImage imageNamed:@"storyLockedIconSmall"] forState:UIControlStateNormal];
    } else {
        [self.guiRemakeButton setImage:[UIImage imageNamed:@"remakeInverseBGButton"] forState:UIControlStateNormal];
    }
}


#pragma mark - Alert view delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger tag = alertView.tag;
    if (tag == ALERT_VIEW_TAG_SHARE_FAILED) {
        if (buttonIndex == 0) return;

        // Retry share remake request
        [self shareRemakeRequest];
    }
}

#pragma mark - Tearing down
-(void)done
{
    if (self.guiShareActivity.isAnimating) return;
    
    // Mark as done
    self.markedAsDone = YES;
    
    // Stop movie player if currently playing
    [self.remakeMoviePlayer done];
    
    // Dismiss transform
    [UIView animateWithDuration:0.3 animations:^{
        self.guiRemakeContainer.transform = self.dismissTransform;
    }];
    
    // Clear remake
    self.remake = nil;
    
    // Tell parent view controller to hide this screen
    [self.delegate dismissPresentedRemake];
}

#pragma mark - Video player
-(void)initVideoPlayerWithRemake:(Remake *)remake
{
    // More options container/overlay
    self.guiMoreOptionsContainer.hidden = YES;
    
    if (self.remakeMoviePlayer) {
        // hide and try to remove older movie player.
        self.remakeMoviePlayer.view.hidden = YES;
        [self.remakeMoviePlayer removeFromParentViewController];
        [self.remakeMoviePlayer.view removeFromSuperview];
    }
    
    self.remakeMoviePlayer = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiRemakeVideoContainer rotationSensitive:YES];
    
    if (self.debugForcedVideoURL) {
        //
        // Used for debugging in development. Forces a specific url of the video to play.
        //
        self.remakeMoviePlayer.videoURL = self.debugForcedVideoURL;
    } else {
        //
        // The video of the remake.
        //
        self.remakeMoviePlayer.videoURL = remake.videoURL;
    }
    
    
    NSURL *thumbURL = [NSURL URLWithString:remake.thumbnailURL];
    [self.remakeMoviePlayer setVideoImage:nil];
    [self.remakeMoviePlayer setThumbURL:thumbURL];    
    
    [self.remakeMoviePlayer hideVideoLabel];
    [self.remakeMoviePlayer hideMediaControls];

    self.remakeMoviePlayer.delegate = self;
    self.remakeMoviePlayer.originatingScreen = @(HMStoryDetails);
    self.remakeMoviePlayer.entityType = @(HMRemake);
    self.remakeMoviePlayer.entityID = remake.sID;
    self.remakeMoviePlayer.resetStateWhenVideoEnds = YES;
}

#pragma mark - Video player delegate
-(void)videoPlayerIsShowingPlaybackControls:(NSNumber *)controlsShown
{
    BOOL shown = controlsShown.boolValue;
    if (shown) {
        if (CGAffineTransformIsIdentity(self.guiRemakeControlsConatinerBottom.transform)) {
            [UIView animateWithDuration:0.5 animations:^{
                self.guiRemakeControlsConatinerBottom.alpha = 0;
            }];
        }
    } else {
        if (self.guiRemakeControlsConatinerBottom.alpha == 0) {
            [UIView animateWithDuration:0.5 animations:^{
                self.guiRemakeControlsConatinerBottom.alpha = 1;
            }];
        }
    }
}

-(void)videoPlayerWillPlay
{
    self.guiRemakeControlsConatinerTop.hidden = YES;
}

-(void)videoPlayerDidStop
{
    [self resetRemakeVideoPlayer];
}

-(void)videoPlayerIsDone
{
    [self resetRemakeVideoPlayer];
}

-(void)videoPlayerDidFinishPlaying
{
    [self resetRemakeVideoPlayer];
}

-(void)resetRemakeVideoPlayer
{
    self.guiOverlayPlayButton.userInteractionEnabled = YES;
    self.guiRemakeControlsConatinerTop.hidden = NO;
}


#pragma mark - Scroll view delegate
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    CGFloat offset = fabs(scrollView.contentOffset.y);
    if (offset > 25) [self done];
}

#pragma mark - Dismiss on touch background
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if ([touch.view isEqual:self.guiDismissOnTouchBG]) {
        [self done];
    }
}

#pragma mark - Like / Unlike
-(void)likeRemake
{
    [self updateLikeButtonToState:YES];
    [HMServer.sh likeRemakeWithID:self.remake.sID userID:User.current.userID];
}

-(void)unlikeRemake
{
    [self updateLikeButtonToState:NO];
    [HMServer.sh unlikeRemakeWithID:self.remake.sID userID:User.current.userID];
}

#pragma mark - Share remake
-(void)shareRemakeRequest
{
    self.currentSharer = [HMSharing new];
    NSDictionary *shareBundle = [self.currentSharer generateShareBundleForRemake:self.remake
                                                                  trackEventName:@"SDShareRemake"
                                                               originatingScreen:@(HMStoryDetails)];
    [self.currentSharer requestShareWithBundle:shareBundle];
    [self.guiShareActivity startAnimating];
    [self.guiShareButton setHidden:YES];
}

-(void)showMoreOptions
{
    self.guiMoreOptionsContainer.alpha = 0;
    self.guiMoreOptionsContainer.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.guiMoreOptionsContainer.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

-(void)dismissMoreOptions
{
    [UIView animateWithDuration:0.2 animations:^{
        self.guiMoreOptionsContainer.alpha = 0;
    } completion:^(BOOL finished) {
        self.guiMoreOptionsContainer.hidden = YES;
    }];
}

-(void)reportAsInappropriate
{
    NSString *userID = [User current].userID;
    NSString *remakeID = self.remake.sID;
    [HMServer.sh markRemakeAsInappropriate:@{@"remake_id" : remakeID , @"user_id" : userID}];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedLikeToggleButton:(UIButton *)likeButton
{
    likeButton.userInteractionEnabled = NO;
    likeButton.alpha = 0.8;

    if ([self.remake isLikedByCurrentUser]) {
        [self unlikeRemake];
    } else {
        [self likeRemake];
    }
}


- (IBAction)onPressedShareButton:(id)sender
{
    [self shareRemakeRequest];
}

-(IBAction)onPressedPlayButton:(UIButton *)button
{
    self.guiOverlayPlayButton.userInteractionEnabled = NO;
    if (!self.remakeMoviePlayer.isInAction) {
        [self.remakeMoviePlayer play];
    }
}

- (IBAction)onPressedRemakeButton:(id)sender
{
    [self done];
    if ([self.delegate respondsToSelector:@selector(userWantsToRemakeStory)]) {
        [self.delegate userWantsToRemakeStory];
    }
}

-(IBAction)onPressedMoreOptionsButton:(id)sender
{
    [self showMoreOptions];
}

- (IBAction)onPressedFlagButton:(id)sender
{
    [self dismissMoreOptions];
    [self reportAsInappropriate];
    [self done];
}

- (IBAction)onPressedDismissMoreOptionsButton:(id)sender
{
    [self dismissMoreOptions];
}


@end
