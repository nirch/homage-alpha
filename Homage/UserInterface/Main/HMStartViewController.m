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

@interface HMStartViewController () <HMsideBarNavigatorDelegate,HMRenderingViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *appContainerView;
@property (weak, nonatomic) IBOutlet UIView *renderingContainerView;
@property (weak, nonatomic) IBOutlet UIView *sideBarContainerView;
@property (weak,nonatomic) UITabBarController *appTabBarController;
@property (weak,nonatomic) HMRenderingViewController *renderingVC;
@property (atomic, readonly) NSDate *launchDateTime;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiTabNameLabel;

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

    // Prepare local storage and start the App.
    [DB.sh useDocumentWithSuccessHandler:^{
        [self startApplication];
    } failHandler:^{
        [self failedStartingApplication];
    }];
}

-(void)initGUI
{
    //self.sideBarContainerView.transform = CGAffineTransformMakeTranslation(-150,0);
    self.sideBarContainerView.hidden = YES;
    CGFloat renderingBarHeight = self.renderingContainerView.frame.size.height;
    self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,49);
    self.renderingContainerView.hidden = YES;
    self.guiTabNameLabel.textColor = [HMColor.sh textImpact];
}

-(void)initObservers
{
    // Observe rendering begining
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onServerStartRendering:)
                                                       name:HM_NOTIFICATION_SERVER_RENDER
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
        self.sideBarContainerView.transform = CGAffineTransformMakeTranslation(0,0);
        CGFloat sideBarWidth = self.sideBarContainerView.frame.size.width;
        self.appContainerView.transform = CGAffineTransformMakeTranslation(sideBarWidth,0);
    } completion:nil];

}

-(void)hideSideBar
{
     [UIView animateWithDuration:0.3 animations:^{
        //self.sideBarContainerView.transform = CGAffineTransformMakeTranslation(-150,0);
        self.appContainerView.transform = CGAffineTransformMakeTranslation(0,0);
        } completion:^(BOOL finished){
            if (finished) self.sideBarContainerView.hidden = YES;
        }];
}

#pragma mark - HMRecorderDelegate Example
-(void)recorderAsksDismissalWithReaon:(HMRecorderDismissReason)reason
                             remakeID:(NSString *)remakeID
                               sender:(HMRecorderViewController *)sender
{
    HMGLogDebug(@"This is the remake ID the recorder used:%@", remakeID);
    
    // Handle reasons
    if (reason == HMRecorderDismissReasonUserAbortedPressingX) {
        // Some logic for this reason...
    } else if (reason == HMRecorderDismissReasonFinishedRemake) {
        // Some other logic for another reason...
    }
    
    // Dismiss modal
    [self dismissViewControllerAnimated:YES completion:^{
        // Code here when the dismissal is done.
    }];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"appSegue"]) {
        self.appTabBarController = segue.destinationViewController;
        self.guiTabNameLabel.text = self.appTabBarController.selectedViewController.title;
    } else if ([segue.identifier isEqualToString:@"sideBarSegue"])
    {
        HMsideBarViewController *vc = (HMsideBarViewController *)segue.destinationViewController;
        vc.delegate = self;
    } else if ([segue.identifier isEqualToString:@"renderSegue"])
    {
        self.renderingVC = segue.destinationViewController;
        self.renderingVC.delegate = self;
    }
}

#pragma mark - Application start
-(void)startApplication
{
    // Notify that the app has started (it already has the local storage available).
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    
    // Dismiss the splash screen.
    [self dismissSplashScreen];
    
    // In development stuff
    [self debug];
    
    //Mixpanel analytics
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"userlogin" properties:@{
                                             @"useremail" : [User current].userID}];
}

-(void)debug
{
    // Hardcoded user for development (until LOGIN screens are implemented)
    
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"useremail"];
    if (!userName)
    {
        userName = @"yoav@homage.it";
        [[NSUserDefaults standardUserDefaults] setValue:userName forKey:@"useremail"];
    }
    User *user = [User userWithID:userName inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    [DB.sh save];
    
    
////    [HMServer.sh refetchRemakesForUserID:user.userID];
//    
//    for (Remake *remake in User.current.remakes) {
//        NSLog(@"%@ %@",remake.sID, remake.story.name);
//    }
//    // 52e24f2fdb254514b0000018 Star Wars
//    // 52e24c42db254514b0000017 Birthday
//    
//    Remake *remake = [Remake findWithID:@"52e24c42db254514b0000017" inContext:DB.sh.context];
//    if (remake) {
//        HMRecorderViewController *vc = [HMRecorderViewController recorderForRemake:remake];
//        vc.delegate = self;
//        [self presentViewController:vc animated:YES completion:nil];
//    }
}

-(void)failedStartingApplication
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Critical error"
                                                    message:@"Failed launching application."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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
    if (self.appTabBarController.selectedIndex != 0)
        [self switchToTab:0];
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
    UIView *fromView = self.appTabBarController.selectedViewController.view;
    UIView *toView = [[self.appTabBarController.viewControllers objectAtIndex:toIndex] view];
    [UIView transitionFromView:fromView toView:toView duration:0.3 options:UIViewAnimationOptionTransitionNone completion:^(BOOL finished) {
        if (finished)
        {
            self.appTabBarController.selectedIndex = toIndex;
            HMGLogDebug(@"label should display %@" , self.appTabBarController.selectedViewController.title);
            self.guiTabNameLabel.text = self.appTabBarController.selectedViewController.title;
        }
    }];
}

-(void)closeSideBar
{
    if (self.sideBarContainerView.hidden == NO)
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
        self.renderingContainerView.transform = CGAffineTransformMakeTranslation(0,49);
        //self.appContainerView.transform = CGAffineTransformMakeTranslation(0,0);
    } completion:^(BOOL finished){
        if (finished)
        self.renderingContainerView.hidden = YES;
    }];
}

- (void)renderDoneClicked
{
    //todo: switch to me tab
    [self switchToTab:1];
    [self hideRenderingView];
}

@end
