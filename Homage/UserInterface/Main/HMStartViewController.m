 //
//  HMStartViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStartViewController.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import "HMRemakerProtocol.h"
#import "HMRecorderViewController.h"
#import "HMServer+Remakes.h"
#import "HMsideBarNavigatorDelegate.h"
#import "HMSideBarViewController.h"
#import "HMRegularFontLabel.h"
#import "HMStyle.h"
#import "HMRenderingViewController.h"
#import "HMRenderingViewControllerDelegate.h"
#import "HMSplashViewController.h"
#import "Mixpanel.h"
#import "HMUploadManager.h"
#import "HMUploadS3Worker.h"
#import "HMLoginDelegate.h"
#import "HMIntroMovieViewController.h"
#import "HMGMeTabVC.h"
#import "HMStoriesViewController.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMBoldFontLabel.h"
#import "HMVideoPlayerDelegate.h"
#import "HMAppDelegate.h"
#import "IASKAppSettingsViewController.h"
#import "HMLoginMainViewController.h"
#import "HMServer+Users.h"
#import "HMServer+AppConfig.h"
#import <AVFoundation/AVAudioPlayer.h>
#import "UIImage+ImageEffects.h"
#import "AMBlurView.h"
#import "HMSimpleVideoViewController.h"
#import "HMServer+Stories.h"
#import "HMServer+analytics.h"
#import <SDWebImage/SDWebImageDownloader.h>

@import MediaPlayer;

#define SONG_LOOP_VOLUME 0.15;

#define HIDDEN_SIDE_BAR_TRANSFORM CGAffineTransformMakeScale(0.95, 0.95)


@interface HMStartViewController () <
    HMSideBarNavigatorDelegate,
    HMRenderingViewControllerDelegate,
    HMLoginDelegate,
    UINavigationControllerDelegate,
    HMVideoPlayerDelegate,
    HMSimpleVideoPlayerDelegate,
    UIGestureRecognizerDelegate
>

// Navigation bar
@property (weak, nonatomic) IBOutlet UIView *guiTopNavContainer;

@property (weak, nonatomic) IBOutlet UIView *guiStatusBarBG;

@property (weak, nonatomic) IBOutlet UIButton *guiNavButton;
@property (weak, nonatomic) IBOutlet UILabel *guiNavTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *guiNavBackground;
@property (weak, nonatomic) IBOutlet UIView *guiNavCover;
@property (weak, nonatomic) IBOutlet UIView *guiNavBarSeparator;

@property (weak, nonatomic) IBOutlet UIView *appWrapperView;
@property (weak, nonatomic) IBOutlet UIView *guiAppWrapperHideView;
@property (weak, nonatomic) IBOutlet UIImageView *guiAppBGImageView;
@property (weak, nonatomic) IBOutlet UIView *guiAppHideView;

@property (weak, nonatomic) IBOutlet UIView *renderingContainerView;
@property (weak, nonatomic) IBOutlet UIView *sideBarContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;

@property (weak, nonatomic) IBOutlet UIView *guiNoConnectivityView;
@property (weak, nonatomic) IBOutlet UIView *guiAppMainView;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiNoConnectivityLabel;

@property (weak, nonatomic) IBOutlet UIView *guiDarkOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiBlurryOverlay;

// Splash screen
@property (weak, nonatomic) IBOutlet UIView *guiSplashView;
@property (weak,nonatomic) HMSplashViewController *splashVC;

// loop song player
@property (weak, nonatomic) IBOutlet UIButton *guiPlayMuteSongLoopButton;
@property (nonatomic) AVAudioPlayer *songLoopPlayer;

@property (weak, nonatomic) UIView *guiVideoContainer;
@property (nonatomic) BOOL isVideoPlaying;
@property (weak,nonatomic) UITabBarController *appTabBarController;
@property (weak,nonatomic) HMRenderingViewController *renderingVC;
@property (weak,nonatomic) HMSideBarViewController *sideBarVC;
@property (weak,nonatomic) HMLoginMainViewController *loginVC;
@property (atomic, readonly) NSDate *launchDateTime;
@property (weak,nonatomic) Story *loginStory;

@property (nonatomic) NSInteger selectedTab;
@property (nonatomic) BOOL justStarted;
@property (nonatomic) NSInteger appEnabled;

@property (nonatomic) CGFloat startPanX;
@property (nonatomic) CGFloat startPanY;
@property (nonatomic) BOOL sideBarVisible;

@property (nonatomic) NSInteger retryFetchCFGWaitTime;


@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *guiAppMainPanGestureRecognizer;


#define SETTING_TAG 1
#define BACK_TAG    2

@end

@implementation HMStartViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Store a reference to the start view controller in app delefate.
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.mainVC = self;
    
    // Launch time
    _launchDateTime = [NSDate date];
    self.justStarted = YES;
    
    // Starting information
    self.retryFetchCFGWaitTime = 5;
    
    // Init look
    [self initGUI];
    [self initPermanentObservers];
    
    // Splash screen.
    [self prepareSplashView];
    [self startSplashView];
    
    // Setup the image downloader
    [[SDWebImageDownloader sharedDownloader] setMaxConcurrentDownloads:6];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self initObservers];
    
    // Prepare local storage and start the App.
    [self playAccordingToUserPreference];
    
    if (!self.justStarted) return;
    
    [DB.sh useDocumentWithSuccessHandler:^{
        [self startApplication];
        self.justStarted = NO;
    } failHandler:^{
        [self failedStartingApplication];
    }];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.songLoopPlayer pause];
    [self removeObservers];
}

-(void)initGUI
{
    self.isVideoPlaying = NO;
    
    // Make the top navigation bar blurry
    [[AMBlurView new] insertIntoView:self.guiTopNavContainer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AMBlurView new] insertIntoView:self.guiBlurryOverlay];
    });
    self.guiAppWrapperHideView.hidden = YES;
    self.renderingContainerView.hidden = YES;
    self.loginContainerView.alpha = 0;
    self.guiNoConnectivityView.hidden = YES;
    
    self.selectedTab = HMStoriesTab;
    [self changeTitleByIndex:self.selectedTab];
    
    self.appEnabled = 0; // counter. if == 0, app should be enabled
    self.guiAppHideView.alpha = 0;
    self.guiNavCover.alpha = 0;

    
    UIPanGestureRecognizer *panRecognizer = self.guiAppMainPanGestureRecognizer;
    [panRecognizer setMinimumNumberOfTouches:1];
	[panRecognizer setMaximumNumberOfTouches:1];
	[panRecognizer setDelegate:self];

    // Sidebar is hidden when app starts
    self.sideBarVC.view.transform = HIDDEN_SIDE_BAR_TRANSFORM;
    
    // ************
    // *  STYLES  *
    // ************
    self.guiNavBackground.backgroundColor = [HMStyle.sh colorNamed:C_NAV_BAR_BACKGROUND];
    self.guiNavBarSeparator.backgroundColor = [HMStyle.sh colorNamed:C_NAV_BAR_SEPARATOR];
    self.guiNavTitleLabel.textColor = [HMStyle.sh colorNamed:C_NAV_BAR_TITLE];
    self.guiStatusBarBG.backgroundColor = [HMStyle.sh colorNamed:C_STATUS_BAR_BG];
}

#pragma mark - Observers
-(void)initObservers
{
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onMoviePlayerPlaybackStateDidChange:)
                                                       name:MPMoviePlayerPlaybackStateDidChangeNotification
                                                     object:nil];

}

-(void)initPermanentObservers
{
    // Observe rendering begining
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeFinishedSuccesfuly:)
                                                       name:HM_NOTIFICATION_RECORDER_FINISHED
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:HMServer.sh];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserMovieFinishedRendering:)
                                                       name:HM_NOTIFICATION_PUSH_NOTIFICATION_MOVIE_STATUS
                                                     object:[[UIApplication sharedApplication] delegate]];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onNewStoryAvailable:)
                                                       name:HM_NOTIFICATION_PUSH_NOTIFICATION_NEW_STORY
                                                     object:[[UIApplication sharedApplication] delegate]];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onNewStoryFetched:)
                                                       name:HM_NOTIFICATION_SERVER_NEW_STORY_FETCHED
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onGeneralMessageReceived:)
                                                       name:HM_NOTIFICATION_PUSH_NOTIFICATION_GENERAL_MESSAGE
                                                     object:[[UIApplication sharedApplication] delegate]];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserPreferencesUpdate:)
                                                       name:HM_NOTIFICATION_SERVER_USER_PREFERENCES_UPDATE
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserJoin:)
                                                       name:HM_NOTIFICATION_USER_JOIN
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserCreated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_CREATION
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onConfigurationDataAvailable:)
                                                       name:HM_NOTIFICATION_SERVER_CONFIG
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRequestToShowSideBar:)
                                                       name:HM_NOTIFICATION_UI_REQUEST_TO_SHOW_SIDE_BAR
                                                     object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onSettingsDidChange:)
                                                       name:kIASKAppSettingChanged
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserWantsToRetryLoginAsGuest:)
                                                       name:HM_NOTIFICATION_UI_USER_RETRIES_LOGIN_AS_GUEST
                                                     object:nil];
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
}

#pragma mark - Observers handlers
-(void)onMoviePlayerPlaybackStateDidChange:(NSNotification *)notification
{
    if (self.songLoopPlayer == nil) return;
    
    __weak MPMoviePlayerController *mp = notification.object;
    if (mp.playbackState == MPMoviePlaybackStatePlaying) {
        [self.songLoopPlayer pause];
        self.isVideoPlaying = YES;
    } else {
        self.isVideoPlaying = NO;
        [self playAccordingToUserPreference];
    }
}

-(void)onRemakeFinishedSuccesfuly:(NSNotification *)notification
{
    [self storiesButtonPushed];
    NSDictionary *info = notification.userInfo;
    NSString *remakeID = info[@"remakeID"];
    [UIView animateWithDuration:0.3 animations:^{
        [self storiesButtonPushed];
    } completion:^(BOOL finished) {
        [self showRenderingView];
        [self.renderingVC renderStartedWithRemakeID:remakeID];
    }];
}

-(void)onReachabilityStatusChange:(NSNotification *)notification
{
    if (!HMServer.sh.isReachable) {
        [self showNoConnectivity];
    } else {
        [self hideNoConnectivity];
    }
}

-(void)onUserPreferencesUpdate:(NSNotification *)notification
{
    
    if (notification.isReportingError && HMServer.sh.isReachable)
    {
        HMGLogError(@"error details is: %@" , notification.reportedError.localizedDescription);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"Failed updating preferences.\n\nTry again in a few moments."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        NSError *error = notification.userInfo[@"error"];
        HMGLogError(@"error: %@" , [error localizedDescription]);
    }
}

-(void)onUserLoginStateChange:(User *)user
{
    NSString *userName;
    NSString *fbProfileID;
    if (user.firstName) {
        userName = user.firstName;
    } else if (user.email)
    {
        userName = [self getLoginName:user.email];
        
    } else {
        userName = LS(@"NAV_USER_NAME_GUEST");
    }
    
    if (user.fbID)
    {
        fbProfileID = user.fbID;
    } else {
        fbProfileID = nil;
    }
    
    [self.sideBarVC updateSideBarGUIWithName:userName FBProfile:fbProfileID];
    
}

-(void)onConfigurationDataAvailable:(NSNotification *)notification
{
    if (notification.isReportingError) {
        // Wait for a few seconds and retry fetching configuration from server.
        HMGLogDebug(@"CFG fetch from server failed. Refetch configurations from server in %@ seconds.", @(self.retryFetchCFGWaitTime));
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.retryFetchCFGWaitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //
            // Loading client configurations set on the server side.
            //
            [HMServer.sh loadAdditionalConfig];
        });
        self.retryFetchCFGWaitTime *= 2;
        return;
    }
    
    // Store the config values fetched from the server.
    // (the values fetched from the server override the default
    // values that are configured in the app bundle).
    [HMServer.sh storeFetchedConfiguration:notification.userInfo];
}


-(void)onUserWantsToRetryLoginAsGuest:(NSNotificationCenter *)notification
{
    [self.loginVC loginAsGuest];
}

-(void)onRequestToShowSideBar:(NSNotificationCenter *)notification
{
    [self showSideBar];
}

-(void)onSettingsDidChange:(NSNotification *)notification
{
    [self updateUserPreferences];
}

#pragma mark - Preferences
-(void)updateUserPreferences
{
    NSString *userID = [User current].userID;
    if (!userID) return;
    
    // Get current user preferences.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shareRemakes = [defaults boolForKey:@"remakesArePublic"];
    
    // Special handling for guest users.
    if (shareRemakes && [[User current] isGuestUser])
    {
        // The user is a guest user.
        // Allow guest users to be public, only if allowed for this app/label.
        BOOL allowPublicGuest = [HMServer.sh.configurationInfo[@"guest_allow_public"] boolValue];
        if (!allowPublicGuest) {
            // Public guest is not allowed.
            
            // Set public to NO.
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"remakesArePublic"];
            shareRemakes = NO;

            // Frown at the user!
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"SIGN_UP_NOW") message:LS(@"ONLY_SIGN_IN_USERS_CAN_PUBLISH_REMAKES") delegate:self cancelButtonTitle:LS(@"OK_GOT_IT") otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertView show];
            });
        }
    }
    
    // TODO: ask why is this set as string values? "YES" and "NO"? Why not send a boolean or number?
    NSString *shareValue = shareRemakes ? @"YES" : @"NO";
    [HMServer.sh updateUserPreferences:@{
                                         @"user_id":userID,
                                         @"is_public":shareValue
                                         }];
}

#pragma mark - HMMainGUIProtocol
-(BOOL)isRenderingViewShowing
{
    if (self.renderingContainerView.hidden) return NO;
    return YES;
}

-(CGFloat)renderingViewHeight
{
    return self.renderingContainerView.bounds.size.height;
}

-(void)showStoriesTab
{
    // TODO: fix Yoav's naming conventions. seperate between IB Actions handlers names and other VC methods.
    [self storiesButtonPushed];
}

-(void)updateTitle:(NSString *)title
{
    [self setTitle:title];
}

#pragma mark - Splash View
-(void)prepareSplashView
{
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isKindOfClass:[HMSplashViewController class]]) {
            self.splashVC = (HMSplashViewController *)vc;
        }
    }
    [self.splashVC prepare];
}

-(void)startSplashView
{
    [self.splashVC start];
}

-(void)dismissSplashScreenAfterAShortAnimation
{
    CGFloat animationTime = 0.3;
    CGFloat delayTime = 0.7;
    
    [UIView animateWithDuration:animationTime
                          delay:delayTime
                        options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowAnimatedContent
                     animations:^{
                         self.guiSplashView.alpha = 0;
                     } completion:nil];
    
    CGFloat timeTillHiding = animationTime + delayTime + 0.1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeTillHiding * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.guiSplashView.hidden = YES;
        [self.splashVC done];
    });
}

- (IBAction)sideBarButtonPushed:(UIButton *)sender
{

    //[[Mixpanel sharedInstance] track:@"SideBarPushed"];
    if (sender.tag == SETTING_TAG) {
        if (!self.sideBarVisible)
        {
            [self showSideBar];
        } else {
            [self hideSideBar];
        }
    } else if (sender.tag == BACK_TAG)
    {
        UIViewController *vc = self.appTabBarController.selectedViewController;
        if ([vc isKindOfClass:[UINavigationController class]])
        {
            UINavigationController *navVC = (UINavigationController *)vc;
            [navVC popViewControllerAnimated:YES];
        }
    }
}

-(IBAction)debugButtonPushed:(UIButton *)sender
{
    if (self.renderingContainerView.hidden) {
        [self showRenderingView];
    } else {
        [self hideRenderingView];
    }
}


-(void)hideMainApp
{
    if ([self isMainAppHidden]) return;
    
    self.guiAppHideView.alpha = 0;
    self.guiNavCover.alpha = 0;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.guiAppHideView.alpha = 1;
        self.guiNavCover.alpha = 1;
    } completion:nil];
    
}

-(void)showMainApp
{
    if (![self isMainAppHidden]) return;

    [UIView animateWithDuration:0.1 animations:^{
        self.guiAppHideView.alpha = 0;
        self.guiNavCover.alpha = 0;

    } completion:nil];
}

-(BOOL)isMainAppHidden
{
    return !self.guiAppHideView.alpha==0;
}

-(BOOL)isSideBarHidden
{
    return self.sideBarContainerView.hidden;
}

-(BOOL)isNoConnectivityViewHidden
{
    return self.guiNoConnectivityView.hidden;
}


-(void)showNoConnectivity
{
    if (!self.guiNoConnectivityView.hidden) return;
    self.guiNoConnectivityView.hidden = NO;
    CGFloat offset = self.guiNoConnectivityView.frame.size.height;
    CGRect newAppContainerViewFrame = self.guiAppMainView.frame;
    newAppContainerViewFrame.size.height -= offset;
    newAppContainerViewFrame.origin.y += offset;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.guiAppMainView.frame = newAppContainerViewFrame;
        [self hideMainApp];
    } completion:nil];
}

-(void)hideNoConnectivity
{
    if (self.guiNoConnectivityView.hidden) return;
    
    CGFloat offset = self.guiNoConnectivityView.frame.size.height;
    CGRect newAppContainerViewFrame = self.guiAppMainView.frame;
    newAppContainerViewFrame.size.height += offset;
    newAppContainerViewFrame.origin.y -= offset;

    [UIView animateWithDuration:0.3 animations:^{
        self.guiAppMainView.frame = newAppContainerViewFrame;
        [self showMainApp];
    } completion:^(BOOL finished){
        if (finished)
        {
            self.guiNoConnectivityView.hidden = YES;
        }
    }];
}


- (IBAction)onAppPan:(id)sender
{
    [[[(UITapGestureRecognizer*)sender view] layer] removeAllAnimations];
    
    UIView *panningView = [sender view];
    
    CGPoint translatedPoint = [(UIPanGestureRecognizer*)sender translationInView:self.view];
    
    //NSLog(@"translated point in self.view is (%f,%f)" , translatedPoint.x , translatedPoint.y);

    if ([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan)
    {
		self.startPanX = panningView.frame.origin.x;
		self.startPanY = panningView.frame.origin.y;
        //NSLog(@"start XY: (%f,%f)" , self.startPanX , self.startPanY);
	}
    
    translatedPoint = CGPointMake(self.startPanX+translatedPoint.x, self.startPanY);
    //NSLog(@"translated point after pan delta in self.view is (%f,%f)" , translatedPoint.x , translatedPoint.y);
    
    if (translatedPoint.x < 0)
    {
        //do nothing
    } else if (translatedPoint.x >= 0 && translatedPoint.x <= self.sideBarContainerView.frame.size.width)
    {
        [panningView setFrame:CGRectMake(translatedPoint.x, translatedPoint.y, panningView.frame.size.width, panningView.frame.size.height)];
    } else
    {
        //do nothing
    }
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
        if (panningView.frame.origin.x < ceilf((self.sideBarContainerView.frame.size.width / 2)))
        {
            [self showMainAppView];
        } else {
            [self showSideBar];
        }
    }
}


-(void)showMainAppView
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.appWrapperView setFrame:CGRectMake(0, 0, self.appWrapperView.frame.size.width, self.appWrapperView.frame.size.height)];
        self.guiAppHideView.alpha = 0;
        self.guiNavCover.alpha = 0;
        self.sideBarVC.view.transform = HIDDEN_SIDE_BAR_TRANSFORM;
    } completion:nil];    
    self.guiAppWrapperHideView.hidden = YES;
    self.sideBarVisible = NO;
}

-(void)showSideBar
{
    [UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.5 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        CGFloat sideBarWidth = self.sideBarContainerView.frame.size.width;
        //self.appWrapperView.transform = CGAffineTransformMakeTranslation(sideBarWidth-currentAppWrapperCenterX,0);
        [self.appWrapperView setFrame:CGRectMake(sideBarWidth, 0, self.appWrapperView.frame.size.width, self.appWrapperView.frame.size.height)];
        self.guiAppHideView.alpha = 1;
        self.guiNavCover.alpha = 1;
        self.sideBarVC.view.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UI_SIDE_BAR_SHOWN object:nil];
    }];
    
    self.guiAppWrapperHideView.hidden = NO;
    self.sideBarVisible = YES;
}

-(void)hideSideBar
{
    if (!self.sideBarVisible) return;
    [self showMainAppView];
}


- (IBAction)onMainAppViewTappedWhileHidden:(id)sender
{
    [self showMainAppView];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"appSegue"]) {
        self.appTabBarController = segue.destinationViewController;
        self.guiNavTitleLabel.hidden = NO;
        self.appTabBarController.tabBar.hidden = YES;
        [self setNavControllersDelegate];
        //[self setSettingsVCdelegate];
        
    } else if ([segue.identifier isEqualToString:@"sideBarSegue"])
    {
        self.sideBarVC = (HMSideBarViewController *)segue.destinationViewController;
        self.sideBarVC.delegate = self;
        
    } else if ([segue.identifier isEqualToString:@"renderSegue"])
    {
        self.renderingVC = segue.destinationViewController;
        self.renderingVC.delegate = self;
    } else if ([segue.identifier isEqualToString:@"loginSegue"])
    {
        self.loginVC = (HMLoginMainViewController *)segue.destinationViewController;
        self.loginVC.delegate = self;
    }
}

-(void)setNavControllersDelegate
{
   
    for (UIViewController *vc in self.appTabBarController.viewControllers)
   {
       if ([vc isKindOfClass:[UINavigationController class]])
       {
           UINavigationController *navVC = (UINavigationController *)vc;
           navVC.delegate = self;
       }
   }

}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self updateNavButtonForNavController:navigationController];
}

-(void)updateNavButtonForNavController:(UINavigationController *)navVC
{
    if ([navVC.viewControllers count] > 1)
    {
        [self.guiNavButton setImage:[UIImage imageNamed:@"backNavIcon"] forState:UIControlStateNormal];
        self.guiNavButton.tag = BACK_TAG;
    } else
    {
        [self.guiNavButton setImage:[UIImage imageNamed:@"more"] forState:UIControlStateNormal];
        self.guiNavButton.tag = SETTING_TAG;
    }
}

-(void)_showStoryDetailsScreenForStoryID:(NSString *)storyID
{
    UINavigationController *navVC;
    UIViewController *vc = self.appTabBarController.selectedViewController;
    if ([vc isKindOfClass:[UINavigationController class]])
    {
        navVC = (UINavigationController *)vc;
    }
    
    HMStoriesViewController *storyVC = (HMStoriesViewController *)[navVC.viewControllers objectAtIndex:0];
    [storyVC refreshFromLocalStorage];
    [storyVC showStoryDetailedScreenForStory:storyID];
}

#pragma mark - Application start
-(void)startApplication
{
    // Notify that the app has started (it already has the local storage available).
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    
    //update correct version number in settings
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:@"version"];
    
    
    // App launched event.
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"appLaunch"];
 
    // The upload manager with # workers of a specific type.
    // You can always replace to another implementation of upload workers,
    // as long as the workers conform to the HMUploadWorkerProtocol.
    [HMUploadManager.sh addWorkers:[HMUploadS3Worker instantiateWorkers:3]];
    [HMUploadManager.sh startMonitoring];
    
    //
    // Loading client configurations set on the server side.
    //
    [HMServer.sh loadAdditionalConfig];
    
    //
    // If no current logged in user, present the login screen.
    //
    if (![User current])
    {
        // No current user. Present login screen or auto login,
        // depending on login flow determind in app settings.
        [self handleLoginFlow];
        return;
    }
    
    // Dismiss the splash screen after a short animation.
    [self dismissSplashScreenAfterAShortAnimation];

    //
    // A current logged in user found.
    //
    
    //make sure login screen is hidden
    [self hideLoginScreen];
    
    //Mixpanel analytics
    User *user = [User current];
    [HMServer.sh chooseCurrentUserID:user.userID];
    [self.loginVC registerLoginAnalyticsForUser:user];
    [self onUserLoginStateChange:user];
    
    //handle push notification from background
    HMAppDelegate *myDelegate = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (myDelegate.pushNotificationFromBG)
    {
        NSDictionary *info = myDelegate.pushNotificationFromBG;
        NSNumber *notificationType = info[@"type"];
        
        if ( notificationType.integerValue == HMPushMovieReady )
        {
          [self switchToTab:HMMeTab];
        } else if ( notificationType.integerValue == HMPushNewStory)
        {
            NSString *storyID = info[@"story_id"];
            [HMServer.sh refetchStoryWithStoryID:storyID];
            [self switchToTab:HMStoriesTab];
        } else {
            [self switchToTab:HMStoriesTab];
        }
    }
    
    if (!myDelegate.sessionStartFlag)
    {
        myDelegate.currentSessionHomageID = [HMServer.sh generateBSONID];
        [HMServer.sh reportSession:myDelegate.currentSessionHomageID beginForUser:user.userID];
        myDelegate.sessionStartFlag = YES;
    }
}

-(void)handleLoginFlow
{
    if ([User current]) {
        // Critical error
        HMGLogError(@"Critical error. Entered handle login flow, but current user already exist");
        return;
    }
    
    // Check what flow to use.
    HMLoginFlowType loginFlowType = [HMServer.sh loginFlowType];

    // Normal login flow. Present login screen to the user.
    if (loginFlowType == HMLoginFlowTypeNormal) {
        [self dismissSplashScreenAfterAShortAnimation];
        [self presentLoginScreen];
        return;
    }
    
    // Auto Login
    if (loginFlowType == HMLoginFlowTypeAutoGuestLogin) {
        self.loginVC.skipIntroVideo = YES;
        [self.loginVC loginAsGuest];
    }
}


-(void)presentLoginScreen
{
    [self.loginVC onPresentLoginCalled];
    [UIView animateWithDuration:2.0 animations:^{
        self.loginContainerView.alpha = 1;
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.guiBlurryOverlay.alpha = 1;
        self.guiDarkOverlay.alpha = 1;
    } ];
}

-(void)hideLoginScreen
{
    self.appWrapperView.hidden = NO;
    
    [self switchToTab:HMStoriesTab];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.loginContainerView.alpha = 0;
    }];
    
    [UIView animateWithDuration:2.0 animations:^{
        self.guiBlurryOverlay.alpha = 0;
        self.guiDarkOverlay.alpha = 0;
    }];
    
    // After hiding login screen, Play song loop if required.
    // (depending on label settings)
    [self playSongLoopIfRequired];
}

-(void)playSongLoopIfRequired
{
    if (self.songLoopPlayer) {
        return;
    }
    
    // Need to initialize player.
    NSString *songLoop = HMServer.sh.configurationInfo[@"song_loop"];
    if (songLoop) {
        NSArray *components = [songLoop componentsSeparatedByString:@"."];
        if (components.count == 2) {
            NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:components[0] ofType:components[1]];
            NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            NSError *error;
            self.songLoopPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
            self.songLoopPlayer.numberOfLoops = -1; // Repeat forever.
            [self playAccordingToUserPreference];
        }
    }
}

-(void)playAccordingToUserPreference
{
    if (self.songLoopPlayer == nil) return;
    
    // Play if user didn't prefer loop to be muted.
    // But only if video is not currently playing.
    if ([self userPrefersMusicPlayback]) {
        self.songLoopPlayer.volume = SONG_LOOP_VOLUME;
        
        if (!self.isVideoPlaying)
            [self.songLoopPlayer play];
    } else {
            [self.songLoopPlayer pause];
    }
    
    // Update the button
    [self updatePlayMuteSongLoopButton];
}

-(BOOL)userPrefersMusicPlayback
{
    NSNumber *userPreference = [[NSUserDefaults standardUserDefaults] objectForKey:@"loopPlaying"];
    return (userPreference == nil || [userPreference boolValue]);
}

-(void)toggleSongPlaybackPreference
{
    // Get current user preference.
    BOOL userPreference = [self userPrefersMusicPlayback];

    // Toggle preference
    userPreference = !userPreference;
    
    // Save toggled preference.
    [[NSUserDefaults standardUserDefaults] setObject:@(userPreference)
                                              forKey:@"loopPlaying"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Update the button
    [self updatePlayMuteSongLoopButton];
}

-(void)updatePlayMuteSongLoopButton
{
    UIImage *icon;
    if ([self userPrefersMusicPlayback]) {
        icon = [UIImage imageNamed:@"playMusicIcon"];
    } else {
        icon = [UIImage imageNamed:@"muteMusicIcon"];
    }
    [self.guiPlayMuteSongLoopButton setImage:icon forState:UIControlStateNormal];
}

-(void)failedStartingApplication
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"CRITICAL_ERROR")
                                                    message:@"Failed launching application."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

#pragma mark - Orientations
-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)storiesButtonPushed
{
    [self switchToTab:HMStoriesTab];
    [[Mixpanel sharedInstance] track:@"appMoveToStoriesTab"];
    UIViewController *VC = self.appTabBarController.selectedViewController;
    if ([VC isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navVC = (UINavigationController *)VC;
        if ([navVC.viewControllers count] > 1)
        {
            [navVC popToRootViewControllerAnimated:YES];
        }
        [self updateNavButtonForNavController:navVC];
    }
  
    [self showMainAppView];
    
}

-(void)meButtonPushed
{
    [[Mixpanel sharedInstance] track:@"appMoveToMeTab"];
    if (self.appTabBarController.selectedIndex != 1)
        [self switchToTab:HMMeTab];
    [self showMainAppView];
    
}

-(void)settingsButtonPushed
{
    [[Mixpanel sharedInstance] track:@"appMoveToSettingsTab"];
    if (self.appTabBarController.selectedIndex != 2)
        [self switchToTab:HMSettingsTab];
    [self showMainAppView];
}

-(void)howToButtonPushed
{
    [[Mixpanel sharedInstance] track:@"appWillPlayIntroMovie"];
    [self initHowtoPlayer];
    [self showMainAppView];
}

-(void)initHowtoPlayer
{
    if (![HMServer.sh isReachable])
    {
        return;
    }
    
    UIView *view;
    self.guiVideoContainer = view = [[UIView alloc] initWithFrame:self.view.frame];
    self.guiVideoContainer.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.guiVideoContainer];
    [self.view bringSubviewToFront:self.guiVideoContainer];
    
    HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiVideoContainer rotationSensitive:YES];
    vc.videoURL = [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"howtoVideo" ofType:@"mp4"]] absoluteString];
    [vc hideVideoLabel];
    
    vc.delegate = self;
    vc.originatingScreen = [NSNumber numberWithInteger:HMHowTo];
    vc.entityType = [NSNumber numberWithInteger:HMHowTo];
    vc.entityID = @"none";
    vc.resetStateWhenVideoEnds = YES;
    [vc play];    
}


-(void)switchToTab:(NSInteger)toIndex
{
    self.appTabBarController.selectedIndex = toIndex;
    [self changeTitleByIndex:toIndex];
    self.selectedTab = toIndex;
}

-(void)changeTitleByIndex:(NSInteger)index
{
    switch (index) {
        case HMStoriesTab:
            self.title = LS(@"NAV_STORIES");
            break;
        case HMMeTab:
            self.title = LS(@"NAV_MY_STORIES");
            break;
        case HMSettingsTab:
            self.title = LS(@"NAV_SETTINGS");
            break;
        default:
            self.title = LS(@"NAV_STORIES");
            break;
    }
}

-(void)setTitle:(NSString *)title
{
    [super setTitle:title];    
    [UIView animateWithDuration:0.1 animations:^{
        self.guiNavTitleLabel.alpha = 0;
        self.guiNavTitleLabel.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        self.guiNavTitleLabel.text = title;
        [UIView animateWithDuration:0.1 animations:^{
            self.guiNavTitleLabel.alpha = 1;
            self.guiNavTitleLabel.transform = CGAffineTransformIdentity;
        }];
    }];
    
}

-(void)showRenderingView
{
    if (!self.renderingContainerView.hidden) return;
    
    self.renderingContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.renderingContainerView.alpha = 1;
        self.renderingContainerView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UI_RENDERING_BAR_SHOWN object:self];
        });
    }];
}

-(void)hideRenderingView
{
    if (self.renderingContainerView.hidden) return;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.renderingContainerView.alpha = 0;
        self.renderingContainerView.transform = CGAffineTransformMakeScale(1.3, 1.3);
    } completion:^(BOOL finished){
        if (finished) self.renderingContainerView.hidden = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UI_RENDERING_BAR_HIDDEN object:self];
        });
    }];
}

- (void)renderDoneClickedWithSuccess:(BOOL)success
{
    if (success)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_MAIN_SWITCHED_TAB object:self userInfo:@{@"tab" : [NSNumber numberWithInt:HMMeTab]}];
        //UINavigationController *tabNavController = (UINavigationController *)self.appTabBarController.selectedViewController;
        //HMGMeTabVC *vc = (HMGMeTabVC *)[tabNavController.viewControllers objectAtIndex:0];
        [self switchToTab:HMMeTab];
        //[vc refetchRemakesFromServer];
    }
    
    [self hideRenderingView];
}

#pragma mark - Push notifications handler
-(void)onUserMovieFinishedRendering:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *storyID = info[@"story_id"];
    NSNumber *appState = info[@"app_state"];
    NSNumber *success = info[@"success"];
    NSString *remakeID = info[@"remake_id"];
    
    //
    // Fetch new movie info
    if (remakeID) {
        [HMServer.sh refetchRemakeWithID:remakeID];
    }
    
    if (appState.intValue == UIApplicationStateActive)
    {
        Story *story = [Story storyWithID:storyID inContext:DB.sh.context];
        [self.renderingVC presentMovieStatus:success.boolValue forStory:story.name];
        [self showRenderingView];
    } else if (appState.intValue == UIApplicationStateInactive)
    {
        [self switchToTab:HMMeTab];
    }
}

-(void)onNewStoryAvailable:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *storyID = info[@"story_id"];
    NSNumber *appState = info[@"app_state"];
    
    if (appState.intValue == UIApplicationStateInactive)
    {
        [HMServer.sh refetchStoryWithStoryID:storyID];
        [self switchToTab:HMStoriesTab];
    }
    
}

-(void)onNewStoryFetched:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *storyID = info[@"story_id"];
    [self _showStoryDetailsScreenForStoryID:storyID];

}



-(void)onGeneralMessageReceived:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *appState = info[@"app_state"];
    
    if (appState.intValue == UIApplicationStateInactive)
    {
        [self switchToTab:HMStoriesTab];
    }
}

-(void)logoutPushed
{
    
    HMAppDelegate *myDelagate = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
    [HMServer.sh reportSession:myDelagate.currentSessionHomageID endForUser:[User current].userID];
    myDelagate.sessionStartFlag = NO;
    [[User current] logoutInContext:DB.sh.context];
    [self presentLoginScreen];
    [self showMainAppView];
    [self hideRenderingView];
    [self switchToTab:HMStoriesTab];
    [self.loginVC onUserLogout];
}

-(void)joinButtonPushed
{
    [self presentJoinUI];
}

-(void)onUserJoin:(NSNotification *)notification
{
    [self presentJoinUI];
}

-(void)onUserCreated:(NSNotification *)notification
{
    HMLoginFlowType loginFlowType = [HMServer.sh loginFlowType];
    if (loginFlowType == HMLoginFlowTypeAutoGuestLogin) {
        if (notification.isReportingError) {
            [self.splashVC showFailedToConnectMessage];
            return;
        }
        [self dismissSplashScreenAfterAShortAnimation];
        [self dismissLoginScreen];
    }
}

-(void)presentJoinUI
{
    [self.loginVC onUserJoin];
    [self presentLoginScreen];
    [self showMainAppView];
}

-(void)dismissLoginScreen
{
    [self hideLoginScreen];
}

-(void)dismissRenderingView
{
    [self hideRenderingView];
}

-(NSString *)getLoginName:(NSString *)mailAddress
{
    NSString *loginName;
    NSString *expression = @"(\\S+)@";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:mailAddress options:0 range:NSMakeRange(0, [mailAddress length])];
    [match rangeAtIndex:1];
    loginName = [mailAddress substringWithRange:[match rangeAtIndex:1]];

    return loginName;
}

#pragma mark HMSimpleVideoViewController delegate
-(void)videoPlayerDidStop
{
    [self.guiVideoContainer removeFromSuperview];
}

-(void)videoPlayerDidFinishPlaying
{
    [self.guiVideoContainer removeFromSuperview];
}


- (BOOL)prefersStatusBarHidden
{
    // Determine if should show the status bar.
    // Will show/hide depending on what the video player allows.
    // Or, if going into the recorder, always hide the status bar.
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    BOOL shouldHide = !app.shouldAllowStatusBar || app.isInRecorderContext;
    return shouldHide;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedMusicLoopToggleButton:(UIButton *)sender
{
    // If no loop to play, hide the button.
    if (!self.songLoopPlayer) {
        self.guiPlayMuteSongLoopButton.hidden = YES;
        return;
    }

    [self toggleSongPlaybackPreference];
    [self playAccordingToUserPreference];

}


@end
