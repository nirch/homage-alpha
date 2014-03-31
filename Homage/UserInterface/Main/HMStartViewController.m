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
#import "HMFontLabel.h"
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
#import "HMDinFontLabel.h"
#import "HMVideoPlayerVC.h"
#import "HMVideoPlayerDelegate.h"
#import <CrashReporter/PLCrashReporter.h>
#import <CrashReporter/PLCrashReport.h>
#import "HMAppDelegate.h"
#import "HMServer+Users.h"
#import <InAppSettingsKit/IASKAppSettingsViewController.h>
#import "HMLoginMainViewController.h"

@interface HMStartViewController () <HMsideBarNavigatorDelegate,HMRenderingViewControllerDelegate,HMLoginDelegate,UINavigationControllerDelegate,HMVideoPlayerDelegate>

typedef NS_ENUM(NSInteger, HMAppTab) {
    HMStoriesTab,
    HMMeTab,
    HMSettingsTab,
};

@property (weak, nonatomic) IBOutlet UIView *appWrapperView;
@property (weak, nonatomic) IBOutlet UIView *renderingContainerView;
@property (weak, nonatomic) IBOutlet UIView *sideBarContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
@property (weak,nonatomic) UITabBarController *appTabBarController;
@property (weak,nonatomic) HMRenderingViewController *renderingVC;
@property (weak,nonatomic) HMsideBarViewController *sideBarVC;
@property (weak,nonatomic) HMLoginMainViewController *loginVC;
@property (atomic, readonly) NSDate *launchDateTime;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiTabNameLabel;
@property (weak,nonatomic) Story *loginStory;
@property (weak, nonatomic) IBOutlet UIView *guiNoConnectivityView;
@property (weak, nonatomic) IBOutlet UIView *guiAppContainerView;
@property (weak, nonatomic) IBOutlet HMDinFontLabel *guiNoConnectivityLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiNavButton;
@property (nonatomic, strong) HMVideoPlayerVC *moviePlayer;
@property (nonatomic) NSInteger selectedTab;
@property (nonatomic) BOOL justStarted;


#define SETTING_TAG 1
#define BACK_TAG 2

@end

@implementation HMStartViewController

- (void)viewDidLoad
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
    
}

-(void)viewDidAppear:(BOOL)animated
{
    // Prepare local storage and start the App.
    if (!self.justStarted) return;
    
    [DB.sh useDocumentWithSuccessHandler:^{
        [self startApplication];
        self.justStarted = NO;
    } failHandler:^{
        [self failedStartingApplication];
    }];
    
    /*HMAppDelegate *appDelegate = (HMAppDelegate*)[[UIApplication sharedApplication] delegate];
    if (appDelegate.pushNotificationFromBG)
    {
        [self initGUI];
        [self initObservers];
        [DB.sh useDocumentWithSuccessHandler:^{
            [self startApplication];
        } failHandler:^{
            [self failedStartingApplication];
        }];
        [self meButtonPushed];
    }*/

}

-(void)viewWillDisappear:(BOOL)animated
{
    
}

-(void)initGUI
{
    self.sideBarContainerView.hidden = YES;
    self.renderingContainerView.hidden = YES;
    self.loginContainerView.hidden = YES;
    self.loginContainerView.alpha = 0;
    
    self.guiNoConnectivityView.hidden = YES;
    self.guiNoConnectivityLabel.textColor = [HMColor.sh textImpact];
    
    self.selectedTab = HMStoriesTab;
    
    //debug
    //[self.guiAppContainerView.layer setBorderColor:[UIColor yellowColor].CGColor];
    //[self.guiAppContainerView.layer setBorderWidth:2.0f];
    //[self displayRectBounds:self.guiAppContainerView.frame Name:@"self.guiAppContainerView.frame"];
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
                                                   selector:@selector(onUserPreferencesUpdate:)
                                                       name:HM_NOTIFICATION_SERVER_USER_PREFERENCES_UPDATE
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserJoin:)
                                                       name:HM_NOTIFICATION_USER_JOIN
                                                     object:nil];

    
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
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"SIGN_UP_NOW", nil) message:NSLocalizedString(@"ONLY_SIGN_IN_USERS_CAN_PUBLISH_REMAKES", nil) delegate:self cancelButtonTitle:LS(@"OK_GOT_IT") otherButtonTitles:nil];
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
    self.guiTextLabel1.alpha = 0;
    self.guiTextLabel1.transform = CGAffineTransformMakeTranslation(40, 0);
    self.guiTextLabel2.alpha = 0;
    self.guiTextLabel2.transform = CGAffineTransformMakeTranslation(60, 0);
}

-(void)startSplashView
{
    // Show the splash screen animations.
    [UIView animateWithDuration:0.3 animations:^{
        self.guiTextLabel1.alpha = 1;
        self.guiTextLabel1.transform = CGAffineTransformIdentity;
        self.guiTextLabel2.alpha = 1;
        self.guiTextLabel2.transform = CGAffineTransformIdentity;
    }];
    
    [UIView animateWithDuration:4.0 delay:0 options:(UIViewAnimationOptionCurveLinear) animations:^{
        self.guiBGImage.transform = CGAffineTransformMakeTranslation(-20, 0);
    } completion:^(BOOL finished) {
    }];
    
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
    [[Mixpanel sharedInstance] track:@"SideBarPushed"];
    if (sender.tag == SETTING_TAG) {
        if (self.sideBarContainerView.hidden == YES) {
            //need to show the sideBar
            [self showSideBar];
            
        } else {
            //need to hide the side bar
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

-(void)showSideBar
{
    self.sideBarContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat sideBarWidth = self.sideBarContainerView.frame.size.width;
        self.appWrapperView.transform = CGAffineTransformMakeTranslation(sideBarWidth,0);
    } completion:nil];

}

-(void)hideSideBar
{
    [UIView animateWithDuration:0.3 animations:^{
        self.appWrapperView.transform = CGAffineTransformMakeTranslation(0,0);
        } completion:^(BOOL finished){
            if (finished) self.sideBarContainerView.hidden = YES;
        }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"appSegue"]) {
        self.appTabBarController = segue.destinationViewController;
        self.guiTabNameLabel.text = self.appTabBarController.selectedViewController.title;
        self.appTabBarController.tabBar.hidden = YES;
        if (!self.guiTabNameLabel.text)
        {
            self.guiTabNameLabel.text = NSLocalizedString(@"STORIES_TAB_HEADLINE_TITLE", nil);
        }
        [self setNavControllersDelegate];
        
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
        [self.guiNavButton setBackgroundImage:[UIImage imageNamed:@"backButtonBlack"] forState:UIControlStateNormal];
        self.guiNavButton.tag = BACK_TAG;
    } else
    {
        [self.guiNavButton setBackgroundImage:[UIImage imageNamed:@"settingsBlack"] forState:UIControlStateNormal];
        self.guiNavButton.tag = SETTING_TAG;
    }
}

-(void)showIntroStory
{
    UINavigationController *navVC;
    UIViewController *vc = self.appTabBarController.selectedViewController;
    if ([vc isKindOfClass:[UINavigationController class]])
    {
        navVC = (UINavigationController *)vc;
    }
    
    HMStoriesViewController *storyVC = (HMStoriesViewController *)[navVC.viewControllers objectAtIndex:0];
    [storyVC prepareToShootIntroStory];
    

}

#pragma mark - Application start
-(void)startApplication
{
    // Notify that the app has started (it already has the local storage available).
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    
    // Dismiss the splash screen.
    [self dismissSplashScreen];
    
    if (![User current])
    {
        [self presentLoginScreen];
    } else {
        //Mixpanel analytics
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        User *user = [User current];
        [mixpanel identify:user.userID];
    
        if (user.email) {
            [mixpanel registerSuperProperties:@{@"email": user.email}];
            [mixpanel.people set:@{@"user" : user.email}];
        }
        
        [mixpanel track:@"userLogin"];
        
        [self onUserLoginStateChange:user];
        
        HMAppDelegate *myDelegate = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (myDelegate.pushNotificationFromBG)
        {
            //NSDictionary *info = myDelegate.pushNotificationFromBG;
            [self switchToTab:HMMeTab];
        }
        
        /*
        // TODO: REMOVE!!!!! Ran's hack - always using the Test environment
        if ([[User current].userID isEqualToString:@"ranpeer@gmail.com"])
        {
            [[HMServer sh] ranHack];
        }
        */
    }
    
    [self reportCrashesIfExist];
    
    // The upload manager with # workers of a specific type.
    // You can always replace to another implementation of upload workers,
    // as long as the workers conform to the HMUploadWorkerProtocol.
    [HMUploadManager.sh addWorkers:[HMUploadS3Worker instantiateWorkers:5]];
    [HMUploadManager.sh startMonitoring];
    
    //DEBUG
    //[self showRenderingView];
    //[self.renderingVC renderStartedWithRemakeID:@"52d7fd79db25451694000001"];
}

#pragma mark crash reports
-(void)reportCrashesIfExist
{
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSError *error;
    
    // Check if we previously crashed
    if ([crashReporter hasPendingCrashReport])
        [self handleCrashReport];
    
    // Enable the Crash Reporter
    if (![crashReporter enableCrashReporterAndReturnError: &error])
        HMGLogWarning(@"Warning: Could not enable crash reporter: %@", error);
}

- (void)handleCrashReport {
    PLCrashReporter *crashReporter = [PLCrashReporter sharedReporter];
    NSData *crashData;
    NSError *error;
    
    // Try loading the crash report
    crashData = [crashReporter loadPendingCrashReportDataAndReturnError: &error];
    if (crashData == nil) {
        HMGLogWarning(@"Could not load crash report: %@", error);
    } else {
        PLCrashReport *report = [[PLCrashReport alloc] initWithData: crashData error: &error];
        if (report == nil)
        {
            HMGLogWarning(@"could not parse crash report");
        } else
        {
            HMGLogInfo(@"app crashed on %@", report.systemInfo.timestamp);
            HMGLogInfo(@"Crashed with signal %@ (code %@, address=0x%" PRIx64 ")", report.signalInfo.name,
                       report.signalInfo.code, report.signalInfo.address);
            HMGLogInfo(@"crashed with exception: %@ reason: %@ stack: %@" , report.exceptionInfo.exceptionName , report.exceptionInfo.exceptionReason , report.exceptionInfo.stackFrames);
            
            NSNumber *address = [NSNumber numberWithLongLong:report.signalInfo.address];
            [[Mixpanel sharedInstance] track:@"AppCrash" properties:@{@"signal" : report.signalInfo.name , @"code" : report.signalInfo.code , @"address" : address , @"exceptionName" : report.exceptionInfo.exceptionName , @"exceptionReason" : report.exceptionInfo.exceptionReason , @"stackFrames" : report.exceptionInfo.stackFrames}];            
        }
    }
    
    // Purge the report
    [crashReporter purgePendingCrashReport];
    return;
}

-(void)presentLoginScreen
{
    self.appWrapperView.hidden = YES;
    self.loginContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.loginContainerView.alpha = 1;
    } completion:nil];
    
}

-(void)hideLoginScreen
{
    self.appWrapperView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.loginContainerView.alpha = 0;
    } completion:^(BOOL finished)
     {
         self.loginContainerView.hidden = NO;
     }];
}


/*-(void)debug
{
    // Hardcoded user for development (until LOGIN screens are implemented)
    
    if (![User current])
    {
        //NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"useremail"];
        if (!userName)
        {
            userName = @"yoav@homage.it";
            //[[NSUserDefaults standardUserDefaults] setValue:userName forKey:@"useremail"];
        }
        User *user = [User userWithID:userName inContext:DB.sh.context];
        [user loginInContext:DB.sh.context];
        [DB.sh save];
    }
}*/

-(void)failedStartingApplication
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Critical error"
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
    [[Mixpanel sharedInstance] track:@"SBPressStories"];
    
    [self switchToTab:HMStoriesTab];
    UIViewController *VC = self.appTabBarController.selectedViewController;
    if ([VC isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navVC = (UINavigationController *)VC;
        if ([navVC.viewControllers count] > 1)
        {
            [navVC popToRootViewControllerAnimated:YES];
        }
    }
  
    [self closeSideBar];
    
}

-(void)meButtonPushed
{
    [[Mixpanel sharedInstance] track:@"SBPressMe"];
    if (self.appTabBarController.selectedIndex != 1)
        [self switchToTab:HMMeTab];
    [self closeSideBar];
    
}

-(void)settingsButtonPushed
{
    [[Mixpanel sharedInstance] track:@"SBPressSettings"];
    if (self.appTabBarController.selectedIndex != 2)
        [self switchToTab:HMSettingsTab];
    [self closeSideBar];
}

-(void)howToButtonPushed
{
    [[Mixpanel sharedInstance] track:@"playIntroStory "];
    [self initIntroMoviePlayer];
    [self closeSideBar];
}

-(void)initIntroMoviePlayer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMVideoPlayerVC *videoPlayerController = [[HMVideoPlayerVC alloc] init];
    videoPlayerController.delegate = self;
    NSURL *videoURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]];
    videoPlayerController.videoURL = videoURL;
    self.moviePlayer = videoPlayerController;
    [self presentViewController:videoPlayerController animated:YES completion:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(void)switchToTab:(NSInteger)toIndex
{
    //check is user changes prepferences in Settings
    if (self.selectedTab == HMSettingsTab) [self updateUserPreferences];
    
    self.appTabBarController.selectedIndex = toIndex;
    self.guiTabNameLabel.text = self.appTabBarController.selectedViewController.title;
    self.selectedTab = toIndex;
}

-(void)closeSideBar
{
    if (self.sideBarContainerView.hidden == NO)
        [self hideSideBar];
}


- (IBAction)onSwipeToShowSideBar:(UISwipeGestureRecognizer *)sender
{
    if (self.sideBarContainerView.hidden == YES) [self showSideBar];
}

- (IBAction)onSwipeToHideSideBar:(UISwipeGestureRecognizer *)sender
{
    [self hideSideBar];
}

-(void)showRenderingView
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    
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
    
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)hideRenderingView
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    
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
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
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
        [self switchToTab:HMMeTab];
        if ([self.appTabBarController.selectedViewController isKindOfClass: [HMGMeTabVC class]])
        {
            HMGMeTabVC *vc = (HMGMeTabVC *)self.appTabBarController.selectedViewController;
            [vc refreshFromLocalStorage];
            [vc refetchRemakesFromServer];
        }
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
    
    if (notification.isReportingError)
    {
        HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
        HMGLogError(@"error details is: %@" , notification.reportedError.localizedDescription);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"Failed updating preferences.\n\nTry again later."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        NSError *error = notification.userInfo[@"error"];
        NSLog(@"error: %@" , [error localizedDescription]);
    }
}


-(void)showNoConnectivity
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (!self.guiNoConnectivityView.hidden) return;
    
    [self displayRectBounds:self.guiAppContainerView.frame Name:@"self.guiAppContainerView.frame"];
    self.guiNoConnectivityView.hidden = NO;
    CGFloat offset = self.guiNoConnectivityView.frame.size.height;
    CGRect newAppContainerViewFrame = self.guiAppContainerView.frame;
    [self displayRectBounds:newAppContainerViewFrame Name:@"newAppContainerViewFrame"];
    newAppContainerViewFrame.size.height -= offset;
    newAppContainerViewFrame.origin.y += offset;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiAppContainerView.frame = newAppContainerViewFrame;
    } completion:nil];
    [self displayRectBounds:self.guiAppContainerView.frame Name:@"self.guiAppContainerView.frame"];
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
}

-(void)hideNoConnectivity
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (self.guiNoConnectivityView.hidden) return;
    
    [self displayRectBounds:self.guiAppContainerView.frame Name:@"self.guiAppContainerView.frame"];
    CGFloat offset = self.guiNoConnectivityView.frame.size.height;
    CGRect newAppContainerViewFrame = self.guiAppContainerView.frame;
    [self displayRectBounds:newAppContainerViewFrame Name:@"newAppContainerViewFrame"];
    newAppContainerViewFrame.size.height += offset;
    newAppContainerViewFrame.origin.y -= offset;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiAppContainerView.frame = newAppContainerViewFrame;
    } completion:^(BOOL finished){
        if (finished)
            self.guiNoConnectivityView.hidden = YES;
    }];
    [self displayRectBounds:self.guiAppContainerView.frame Name:@"self.guiAppContainerView.frame"];
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
}

-(void)displayRectBounds:(CGRect)rect Name: name
{
    NSLog(@"displaying size of: %@: origin: (%f,%f) size: (%f,%f)" , name , rect.origin.x , rect.origin.y , rect.size.height , rect.size.width);
}

#pragma mark HMVideoPlayerVC delegate
-(void)videoPlayerStopped
{
    [self.moviePlayer dismissViewControllerAnimated:YES completion:nil];
    [[Mixpanel sharedInstance] track:@"stopIntroStory"];
}

-(void)videoPlayerFinishedPlaying
{
    [self.moviePlayer dismissViewControllerAnimated:YES completion:nil]
    ;
    [[Mixpanel sharedInstance] track:@"finishIntroStory "];
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

-(void)onUserLoginStateChange:(User *)user
{
    NSString *userName;
    NSString *fbProfileID;
    if (user.firstName) {
        userName = user.firstName;
    } else if (user.email)
    {
        userName = user.email;
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
    [[User current] logoutInContext:DB.sh.context];
    [self presentLoginScreen];
    [self hideSideBar];
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
    [self hideSideBar];
}

-(void)dismissLoginScreen
{
    [self hideLoginScreen];
}

-(void)dismissRenderingView
{
    [self hideRenderingView];
}

/*#pragma mark iask buttons delegate
- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
	if ([specifier.key isEqualToString:@"loginStateButton"]) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"loginStateButton" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
    }
}*/

@end
