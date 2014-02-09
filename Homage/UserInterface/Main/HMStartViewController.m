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
#import "HMLoginViewController.h"
#import "HMGMeTabVC.h"
#import "HMStoriesViewController.h"

@interface HMStartViewController () <HMsideBarNavigatorDelegate,HMRenderingViewControllerDelegate,HMLoginDelegate>

@property (weak, nonatomic) IBOutlet UIView *appContainerView;
@property (weak, nonatomic) IBOutlet UIView *renderingContainerView;
@property (weak, nonatomic) IBOutlet UIView *sideBarContainerView;
@property (weak, nonatomic) IBOutlet UIView *loginContainerView;
@property (weak,nonatomic) UITabBarController *appTabBarController;
@property (weak,nonatomic) HMRenderingViewController *renderingVC;
@property (atomic, readonly) NSDate *launchDateTime;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiTabNameLabel;
@property (weak,nonatomic) Story *loginStory;

@end

@implementation HMStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Launch time
    _launchDateTime = [NSDate date];

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
    [DB.sh useDocumentWithSuccessHandler:^{
        [self startApplication];
    } failHandler:^{
        [self failedStartingApplication];
    }];
}

-(void)initGUI
{
    self.sideBarContainerView.hidden = YES;
    CGFloat renderingBarHeight = self.renderingContainerView.frame.size.height;
    HMGLogDebug(@"renderingBarHeight is %f" , renderingBarHeight);
    //self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,49);
    self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,renderingBarHeight);
    self.renderingContainerView.hidden = YES;
    self.guiTabNameLabel.textColor = [HMColor.sh textImpact];
    self.loginContainerView.hidden = YES;
    self.loginContainerView.alpha = 0;
}

-(void)initObservers
{
    // Observe rendering begining
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onServerStartRendering:)
                                                       name:HM_NOTIFICATION_SERVER_RENDER
                                                     object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRecorderFinished:)
                                                       name:HM_NOTIFICATION_RECORDER_FINISHED
                                                     object:nil];
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
    if (self.sideBarContainerView.hidden == YES) {
        //need to show the sideBar
        [self showSideBar];
        
    } else {
        //need to hide the side bar
        [self hideSideBar];
    }
}

-(void)showSideBar
{
    self.sideBarContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat sideBarWidth = self.sideBarContainerView.frame.size.width;
        self.appContainerView.transform = CGAffineTransformMakeTranslation(sideBarWidth,0);
    } completion:nil];

}

-(void)hideSideBar
{
     [UIView animateWithDuration:0.3 animations:^{
        self.appContainerView.transform = CGAffineTransformMakeTranslation(0,0);
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
        
    } else if ([segue.identifier isEqualToString:@"sideBarSegue"])
    {
        HMsideBarViewController *vc = (HMsideBarViewController *)segue.destinationViewController;
        vc.delegate = self;
    } else if ([segue.identifier isEqualToString:@"renderSegue"])
    {
        self.renderingVC = segue.destinationViewController;
        self.renderingVC.delegate = self;
    } else if ([segue.identifier isEqualToString:@"loginSegue"])
    {
        HMLoginViewController *vc = (HMLoginViewController *)segue.destinationViewController;
        vc.delegate = self;
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
        [mixpanel track:@"userlogin" properties:@{
                                                  @"useremail" : [User current].userID}];
    }
    
    // The upload manager with # workers of a specific type.
    // You can always replace to another implementation of upload workers,
    // as long as the workers conform to the HMUploadWorkerProtocol.
    [HMUploadManager.sh addWorkers:[HMUploadS3Worker instantiateWorkers:5]];
}

-(void)presentLoginScreen
{
    [UIView animateWithDuration:0.3 animations:^{
        self.loginContainerView.hidden = NO;
        self.loginContainerView.alpha = 1;
    } completion:nil];
}


-(void)debug
{
    // Hardcoded user for development (until LOGIN screens are implemented)
    
    if (![User current])
    {
        NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"useremail"];
        if (!userName)
        {
            userName = @"yoav@homage.it";
            [[NSUserDefaults standardUserDefaults] setValue:userName forKey:@"useremail"];
        }
        User *user = [User userWithID:userName inContext:DB.sh.context];
        [user loginInContext:DB.sh.context];
        [DB.sh save];
    }
}

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
    HMGLogDebug(@"selected index is: %d" , self.appTabBarController.selectedIndex);
    
    [self switchToTab:0];
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
    HMGLogDebug(@"selected index is: %d" , self.appTabBarController.selectedIndex);
    if (self.appTabBarController.selectedIndex != 1)
        [self switchToTab:1];
    [self closeSideBar];
    
}

-(void)settingsButtonPushed
{
    HMGLogDebug(@"selected index is: %d" , self.appTabBarController.selectedIndex);
    if (self.appTabBarController.selectedIndex != 2)
        [self switchToTab:2];
    [self closeSideBar];
}

-(void)switchToTab:(NSUInteger)toIndex
{
    UIViewController *fromVC = self.appTabBarController.selectedViewController;
    UIView *fromView = fromVC.view;
    
    self.appTabBarController.selectedIndex = toIndex;
    
    UIViewController *toVC = self.appTabBarController.selectedViewController;
    UIView *toView = toVC.view;
    
    self.guiTabNameLabel.text = self.appTabBarController.selectedViewController.title;
    
    if ( toVC != fromVC )[UIView transitionFromView:fromView toView:toView duration:0.3 options:UIViewAnimationOptionTransitionNone completion:nil];
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

-(void)onServerStartRendering:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *remakeID = info[@"remakeID"];
    
    [self.renderingVC renderStartedWithRemakeID:remakeID];
    [self showRenderingView];

}

-(void)showRenderingView
{
    self.renderingContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,0);
        //self.appContainerView.transform = CGAffineTransformMakeTranslation(0,0);
    } completion:nil];
}

-(void)hideRenderingView
{
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat renderingBarHeight = self.renderingContainerView.frame.size.height;
        HMGLogDebug(@"renderingBarHeight is %f" , renderingBarHeight);
        //self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,49);
        self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,renderingBarHeight);
    } completion:^(BOOL finished){
        if (finished)
        self.renderingContainerView.hidden = YES;
    }];
}

- (void)renderDoneClicked
{
    //todo: switch to me tab
    [self switchToTab:1];
    if ([self.appTabBarController.selectedViewController isKindOfClass: [HMGMeTabVC class]])
    {
        HMGMeTabVC *vc = (HMGMeTabVC *)self.appTabBarController.selectedViewController;
        [vc refreshFromLocalStorage];
        [vc refetchRemakesFromServer];
    }
    [self hideRenderingView];
}

-(void)onLoginPressedSkip
{
    [self.loginContainerView removeFromSuperview];
}

/*-(void)onLoginPressedShootWithRemake:(Remake *)remake
{
    [UIView animateWithDuration:0.3 animations:^{
        self.loginContainerView.alpha = 0;
    } completion:^(BOOL finished) {
        self.loginContainerView.hidden = YES;
        HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
        if (recorderVC) [self presentViewController:recorderVC animated:YES completion:nil];
    }];
}*/

-(void)onLoginPressedShootFirstStory
{
    [self showIntroStory];
    [UIView animateWithDuration:0.3 animations:^{
        self.loginContainerView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.loginContainerView removeFromSuperview];
    }];
}

-(void)onRecorderFinished:(NSNotification *)notification
{
    [self storiesButtonPushed];
}

@end
