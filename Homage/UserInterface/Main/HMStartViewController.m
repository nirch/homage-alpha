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

@interface HMStartViewController ()

@property (atomic, readonly) NSDate *launchDateTime;

@end

@implementation HMStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Launch time
    _launchDateTime = [NSDate date];

    // Init look
    [self initGUI];
    
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
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background2"]];
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

#pragma mark - Application start
-(void)startApplication
{
    // Notify that the app has started (it already has the local storage available).
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    
    // Dismiss the splash screen.
    [self dismissSplashScreen];
    
    // In development stuff
    [self debug];
}

-(void)debug
{
    // Hardcoded user for development (until LOGIN screens are implemented)
    
    NSString *userName = [[NSUserDefaults standardUserDefaults] objectForKey:@"useremail"];
    if (!userName)
    {
        userName = @"rafi@homage.it";
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

@end
