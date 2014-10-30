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

@interface HMRemakeScreenViewController ()

@property (nonatomic) BOOL markedAsDone;

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
@property (nonatomic) HMSharing *currentSharer;

// Remake
@property (nonatomic) Remake *remake;


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
}

-(void)prepareForRemake:(Remake *)remake animateFromRect:(CGRect)s fromCenter:(CGPoint)fromCenter
{
    // Keep a reference to the remake
    self.remake = remake;
    
    // Initialize video player.
    [self initVideoPlayerWithRemake:remake];
    
    // Update remake info
    [self updateInfoForRemake];
    
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
    if ([self.remake isLikedByCurrentUser]) {
        [self.guiLikeButton setTitle:LS(@"UNLIKE_BUTTON_LABEL") forState:UIControlStateNormal];
    } else {
        [self.guiLikeButton setTitle:LS(@"LIKE_BUTTON_LABEL") forState:UIControlStateNormal];
    }
    [UIView animateWithDuration:1.0 animations:^{
        self.guiLikeButton.alpha = 1;
    } completion:^(BOOL finished) {
        self.guiLikeButton.userInteractionEnabled = YES;
    }];
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
    
}

-(void)removeObservers
{
    
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_LIKED_REMAKE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_UNLIKED_REMAKE object:nil];
    
}

#pragma mark - Observers handlers
-(void)onLikeStatusUpdated:(NSNotification *)notification
{
    [self updateInfoForRemake];
}

#pragma mark - Tearing down
-(void)done
{
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
    self.remakeMoviePlayer = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiRemakeVideoContainer rotationSensitive:YES];
    self.remakeMoviePlayer.videoURL = remake.videoURL;
    self.remakeMoviePlayer.videoImage = remake.thumbnail;
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
    [HMServer.sh likeRemakeWithID:self.remake.sID userID:User.current.userID];
}

-(void)unlikeRemake
{
    [HMServer.sh unlikeRemakeWithID:self.remake.sID userID:User.current.userID];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedLikeToggleButton:(UIButton *)likeButton
{
    likeButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        likeButton.alpha = 0;
    } completion:^(BOOL finished) {
        likeButton.userInteractionEnabled = YES;
    }];

    if ([self.remake isLikedByCurrentUser]) {
        [self unlikeRemake];
    } else {
        [self likeRemake];
    }
}


- (IBAction)onPressedShareButton:(id)sender
{
    self.currentSharer = [HMSharing new];
    [self.currentSharer shareRemake:self.remake parentVC:self trackEventName:@"SDShareRemake"];
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

@end
