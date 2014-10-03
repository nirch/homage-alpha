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
#import "HMsideBarViewController.h"
#import "HMAvenirBookFontLabel.h"
#import "HMColor.h"
#import "HMRenderingViewController.h"
#import "HMRenderingViewControllerDelegate.h"
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
//#import <CrashReporter/PLCrashReporter.h>
//#import <CrashReporter/PLCrashReport.h>
#import "HMAppDelegate.h"
#import "IASKAppSettingsViewController.h"
#import "HMLoginMainViewController.h"
#import "HMServer+Users.h"
#import <Crashlytics/Crashlytics.h>
#import <AVFoundation/AVAudioPlayer.h>
#import "UIImage+ImageEffects.h"
#import "AMBlurView.h"
#import "HMSimpleVideoViewController.h"
#import "HMServer+Stories.h"
#import "HMServer+analytics.h"


@interface HMStartViewController () <HMsideBarNavigatorDelegate,HMRenderingViewControllerDelegate,HMLoginDelegate,UINavigationControllerDelegate,HMVideoPlayerDelegate,HMSimpleVideoPlayerDelegate,UIGestureRecognizerDelegate>

// Navigation bar
@property (weak, nonatomic) IBOutlet UIView *guiTopNavContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiNavButton;
@property (weak, nonatomic) IBOutlet UILabel *guiTabNameLabel;


@property (weak, nonatomic) IBOutlet UIView *appWrapperView;
@property (weak, nonatomic) IBOutlet UIView *guiAppWrapperHideView;
@property (weak, nonatomic) IBOutlet UIImageView *guiAppBGImageView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;
@property (weak, nonatomic) IBOutlet UIView *guiAppHideView;
@property (weak, nonatomic) IBOutlet UIView *guiVideoContainer;

@property (weak, nonatomic) IBOutlet UIView *renderingContainerView;
@property (weak, nonatomic) IBOutlet UIView *sideBarContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
@property (weak,nonatomic) UITabBarController *appTabBarController;
@property (weak,nonatomic) HMRenderingViewController *renderingVC;
@property (weak,nonatomic) HMsideBarViewController *sideBarVC;
@property (weak,nonatomic) HMLoginMainViewController *loginVC;
@property (atomic, readonly) NSDate *launchDateTime;

@property (weak,nonatomic) Story *loginStory;
@property (weak, nonatomic) IBOutlet UIView *guiNoConnectivityView;
@property (weak, nonatomic) IBOutlet UIView *guiAppMainView;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiNoConnectivityLabel;

@property (weak, nonatomic) IBOutlet UIView *guiDarkOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiBlurryOverlay;

@property (nonatomic) NSInteger selectedTab;
@property (nonatomic) BOOL justStarted;
@property (nonatomic) NSInteger appEnabled;

@property (nonatomic) CGFloat startPanX;
@property (nonatomic) CGFloat startPanY;
@property (nonatomic) BOOL sideBarVisible;


@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *guiAppMainPanGestureRecognizer;


#define SETTING_TAG 1
#define BACK_TAG    2

@end

@implementation HMStartViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    // Launch time
    _launchDateTime = [NSDate date];
    self.justStarted = YES;
    
    // Init look
    [self initGUI];
    [self initObservers];
    
    // Splash screen.
    [self prepareSplashView];
    [self startSplashView];
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Prepare local storage and start the App.
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
}

-(void)initGUI
{
    // Make the top navigation bar blurry
    [[AMBlurView new] insertIntoView:self.guiTopNavContainer];
    [[AMBlurView new] insertIntoView:self.guiBlurryOverlay];
    self.guiAppWrapperHideView.hidden = YES;
    self.renderingContainerView.hidden = YES;
    //self.loginContainerView.hidden = YES;
    self.loginContainerView.alpha = 0;
    
    self.guiNoConnectivityView.hidden = YES;
    //self.guiNoConnectivityLabel.textColor = [HMColor.sh textImpact];
    self.guiTabNameLabel.textColor = [HMColor.sh textImpact];
    
    self.selectedTab = HMStoriesTab;
    [self changeTitleByIndex:self.selectedTab];
    
    self.appEnabled = 0; // counter. if == 0, app should be enabled
    self.guiAppHideView.hidden = YES;
    
    UIPanGestureRecognizer *panRecognizer = self.guiAppMainPanGestureRecognizer;
    [panRecognizer setMinimumNumberOfTouches:1];
	[panRecognizer setMaximumNumberOfTouches:1];
	[panRecognizer setDelegate:self];
    
    //debug
    //[self.guiAppContainerView.layer setBorderColor:[UIColor yellowColor].CGColor];
    //[self.guiAppContainerView.layer setBorderWidth:2.0f];
    
}

-(void)initObservers
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
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self selector:@selector(settingsDidChange:) name:kIASKAppSettingChanged object:nil];

    
}

-(void)updateUserPreferences
{
    NSString *userID = [User current].userID;
    if (!userID) return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL shareRemakes = [defaults boolForKey:@"remakesArePublic"];
    if (shareRemakes && [[User current] isGuestUser])
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"remakesArePublic"];
        shareRemakes = NO;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"SIGN_UP_NOW") message:LS(@"ONLY_SIGN_IN_USERS_CAN_PUBLISH_REMAKES") delegate:self cancelButtonTitle:LS(@"OK_GOT_IT") otherButtonTitles:nil];
        //alertView.tag = SHARE_ALERT_VIEW_TAG;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    }
    
    NSString *shareValue = shareRemakes ? @"YES" : @"NO";
    [HMServer.sh updateUserPreferences:@{@"user_id" : userID , @"is_public" : shareValue}];
}

#pragma mark - Splash View
-(void)prepareSplashView
{
    // Splash view initial state.
}

-(void)startSplashView
{
    // Show the splash screen animations.
    // TODO: add some animations here
    
    // Show activity.
    [self.guiActivity startAnimating];
}

-(void)dismissSplashScreen
{
    // Don't dismiss splash too quickly after launch.
    // Will allow the splash screen to animate for about a second or two.
    NSTimeInterval timeIntervalSinceLaunch = [[NSDate date] timeIntervalSinceDate:self.launchDateTime];
    double delayInSeconds = timeIntervalSinceLaunch > 2.5 ? 0 : 2.5 - timeIntervalSinceLaunch;

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.3 animations:^{
            self.guiSplashView.alpha = 0;
        } completion:^(BOOL finished) {
            self.guiSplashView.hidden = YES;
        }];
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


-(void)hideMainApp
{
    if ([self isMainAppHidden]) return;
    
    self.guiAppHideView.alpha = 0;
    self.guiAppHideView.hidden = NO;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.guiAppHideView.alpha = 1;
    } completion:nil];
    
}

-(void)showMainApp
{
    if (![self isMainAppHidden]) return;

    [UIView animateWithDuration:0.1 animations:^{
        self.guiAppHideView.alpha = 0;
    } completion:^(BOOL finished){
        if (finished)
        {
            self.guiAppHideView.hidden = YES;
        }}];
}

-(BOOL)isMainAppHidden
{
    return !self.guiAppHideView.hidden;
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
        //CGFloat sideBarWidth = self.sideBarContainerView.frame.size.width;
        [self.appWrapperView setFrame:CGRectMake(0, 0, self.appWrapperView.frame.size.width, self.appWrapperView.frame.size.height)];
        //self.appWrapperView.transform = CGAffineTransformMakeTranslation(0,0);
    } completion:nil];
    
    self.guiAppWrapperHideView.hidden = YES;
    self.sideBarVisible = NO;
}

-(void)showSideBar
{
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat sideBarWidth = self.sideBarContainerView.frame.size.width;
        //self.appWrapperView.transform = CGAffineTransformMakeTranslation(sideBarWidth-currentAppWrapperCenterX,0);
        [self.appWrapperView setFrame:CGRectMake(sideBarWidth, 0, self.appWrapperView.frame.size.width, self.appWrapperView.frame.size.height)];
    } completion:nil];
    
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
        self.guiTabNameLabel.hidden = NO;
        self.appTabBarController.tabBar.hidden = YES;
        [self setNavControllersDelegate];
        //[self setSettingsVCdelegate];
        
    } else if ([segue.identifier isEqualToString:@"sideBarSegue"])
    {
        self.sideBarVC = (HMsideBarViewController *)segue.destinationViewController;
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
    
    // Dismiss the splash screen.
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"appLaunch"];
    [self dismissSplashScreen];
    
    //
    // If no current logged in user, present the login screen.
    //
    if (![User current])
    {
        [self presentLoginScreen];
        return;
    }
    
    //
    // A current logged in user found.
    //
    
    //make sure login screen is hidden
    [self hideLoginScreen];
    
    //Mixpanel analytics
    User *user = [User current];
    [HMServer.sh updateServerWithCurrentUser:user.userID];
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
    
    //[self reportCrashesIfExist];
    
    // The upload manager with # workers of a specific type.
    // You can always replace to another implementation of upload workers,
    // as long as the workers conform to the HMUploadWorkerProtocol.
    [HMUploadManager.sh addWorkers:[HMUploadS3Worker instantiateWorkers:5]];
    [HMUploadManager.sh startMonitoring];
    
    //DEBUG
    //[self showRenderingView];
    //[self.renderingVC renderStartedWithRemakeID:@"52d7fd79db25451694000001"];
}

//#pragma mark crash reports
//-(void)reportCrashesIfExist
//{
//    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
//    NSError *error;
//    
//    // Check if we previously crashed
//    if ([crashReporter hasPendingCrashReport])
//        [self handleCrashReport];
//    
//    // Enable the Crash Reporter
//    if (![crashReporter enableCrashReporterAndReturnError: &error])
//        HMGLogWarning(@"Warning: Could not enable crash reporter: %@", error);
//}
//
//- (void)handleCrashReport {
//    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
//    NSData *crashData;
//    NSError *error;
//    
//    // Try loading the crash report
//    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
//    if (crashData == nil) {
//        HMGLogWarning(@"Could not load crash report: %@", error);
//    } else {
//        PLCrashReport *report = [[PLCrashReport alloc] initWithData: crashData error: &error];
//        if (report == nil)
//        {
//            HMGLogWarning(@"could not parse crash report");
//        } else
//        {
//            HMGLogInfo(@"app crashed on %@", report.systemInfo.timestamp);
//            HMGLogInfo(@"Crashed with signal %@ (code %@, address=0x%" PRIx64 ")", report.signalInfo.name,
//                       report.signalInfo.code, report.signalInfo.address);
//            HMGLogInfo(@"crashed with exception: %@ reason: %@ stack: %@" , report.exceptionInfo.exceptionName , report.exceptionInfo.exceptionReason , report.exceptionInfo.stackFrames);
//            
//            Mixpanel *mixpanel = [Mixpanel sharedInstance];
//            
//            NSDictionary *crashDict = @{};
//            
//            if (report.signalInfo)
//            {
//                NSString *signalName = report.signalInfo.name ? report.signalInfo.name : @"not available";
//                NSString *signalCode = report.signalInfo.code ? report.signalInfo.code : @"not available";
//                NSNumber *address = report.signalInfo.address ? [NSNumber numberWithLongLong:report.signalInfo.address] : @0 ;
//                
//                crashDict = @{@"signal_name" : signalName , @"signal_code" : signalCode , @"signal_address" : address};
//            }
//            
//            if (report.exceptionInfo)
//            {
//                NSString *exceptionName = report.exceptionInfo.exceptionName ? report.exceptionInfo.exceptionName : @"not available";
//                NSString *exceptionReason = report.exceptionInfo.exceptionReason ? report.exceptionInfo.exceptionReason : @"not available";
//                NSArray  *stackFrames = report.exceptionInfo.stackFrames ? report.exceptionInfo.stackFrames : @[];
//                
//                NSMutableDictionary *temp = [crashDict mutableCopy];
//                [temp setValue:exceptionName forKey:@"exceptionName"];
//                [temp setValue:exceptionReason forKey:@"exceptionReason"];
//                [temp setValue:stackFrames forKey:@"stackFrames"];
//                crashDict = [NSDictionary dictionaryWithDictionary:temp];
//            }
//    
//            [mixpanel track:@"AppCrash" properties:crashDict];
//        }
//    }
//    
//    // Purge the report
//    [crashReporter purgePendingCrashReport];
//    return;
//}

-(void)presentLoginScreen
{
    //if (self.loginContainerView.hidden == NO) return;
    
    //self.appWrapperView.hidden = YES;
    //self.loginContainerView.hidden = NO;
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
    //if (self.loginContainerView.hidden == YES) return;
    
    self.appWrapperView.hidden = NO;
    
    [self switchToTab:HMStoriesTab];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.loginContainerView.alpha = 0;
    }];
    
    [UIView animateWithDuration:2.0 animations:^{
        self.guiBlurryOverlay.alpha = 0;
        self.guiDarkOverlay.alpha = 0;
    }];
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
    vc.entityType = [NSNumber numberWithInteger:HMIntroMovie];
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
            self.title = LS(@"STORIES_TAB_HEADLINE_TITLE");
            break;
        case HMMeTab:
            self.title = LS(@"ME_TAB_HEADLINE_TITLE");
            break;
        case HMSettingsTab:
            self.title = LS(@"SETTINGS_TAB_HEADLINE TITLE");
            break;
        default:
            self.title = LS(@"STORIES_TAB_HEADLINE_TITLE");
            break;
    }
}

-(void)setTitle:(NSString *)title
{
    [super setTitle:title];
    self.guiTabNameLabel.text = title;
}

-(void)showRenderingView
{
    if (!self.renderingContainerView.hidden) return;
    
    self.renderingContainerView.hidden = NO;
    CGFloat renderingBarHeight = self.renderingContainerView.frame.size.height;
    CGRect newAppContainerViewFrame = self.appWrapperView.frame;
    
    newAppContainerViewFrame.size.height -= renderingBarHeight;
    self.renderingContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.appWrapperView.frame = newAppContainerViewFrame;
        self.renderingContainerView.alpha = 1;
        //self.appWrapperView.layer.borderColor = [[UIColor yellowColor] CGColor];
        //self.appWrapperView.layer.borderWidth = 3.0f;
    } completion:nil];
}

-(void)hideRenderingView
{
    if (self.renderingContainerView.hidden) return;
    
    CGFloat renderingBarHeight = self.renderingContainerView.frame.size.height;
    CGRect newAppContainerViewFrame = self.appWrapperView.frame;
    
    newAppContainerViewFrame.size.height += renderingBarHeight;
    [UIView animateWithDuration:0.3 animations:^{
        self.appWrapperView.frame = newAppContainerViewFrame;
        self.renderingContainerView.alpha = 0;
    } completion:^(BOOL finished){
        if (finished)
        self.renderingContainerView.hidden = YES;
    }];
}

-(BOOL)isRenderingViewShowing
{
    if (self.renderingContainerView.hidden) return NO;
    return YES;
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



#pragma mark push notifications handler
-(void)onUserMovieFinishedRendering:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *storyID = info[@"story_id"];
    NSNumber *appState = info[@"app_state"];
    NSNumber *success = info[@"success"];
    
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
        userName = @"Guest";
    }
    
    if (user.fbID)
    {
        fbProfileID = user.fbID;
    } else {
        fbProfileID = nil;
    }
    
    [self.sideBarVC updateSideBarGUIWithName:userName FBProfile:fbProfileID];
    
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

-(void)settingsDidChange:(NSNotification *)notification
{
    [self updateUserPreferences];
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

@end
