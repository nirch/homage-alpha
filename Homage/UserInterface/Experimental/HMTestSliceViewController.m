//
//  HMTestSliceViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#define ARC4RANDOM_MAX      0x100000000

#import "HMTestSliceViewController.h"
#import "AWPieSliceView.h"
#import "UIView+MotionEffect.h"
#import "HMRoundCountdownLabel.h"
#import "DB.h"
#import "HMUploadManager.h"
#import "HMUploadS3Worker.h"
#import "HMServer+ReachabilityMonitor.h"

@interface HMTestSliceViewController ()

@property (weak, nonatomic) IBOutlet HMRoundCountdownLabel *guiCountDownLabel;

@end

@implementation HMTestSliceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSliceWithCurrentValue];
    [self.guiBGImage addMotionEffectWithAmount:-20];
    
    // Prepare local storage and start the App.
    [DB.sh useDocumentWithSuccessHandler:^{
        [self startApplication];
    } failHandler:^{
        [self failedStartingApplication];
    }];
}

-(void)updateSliceWithCurrentValue
{
    self.guiSlice.value = self.guiSlider.value;
}

-(void)startApplication
{
    self.guiStartButton.enabled = YES;
    [self.guiStartActivity stopAnimating];
    
    // Hardcoded user for development (until LOGIN screens are implemented)
    User *user = [User userWithID:@"moreTests@homage.it" inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    [DB.sh save];
    
    //
    [self performSegueWithIdentifier:@"start" sender:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // The upload manager with # workers of a specific type.
        // You can always replace to another implementation of upload workers,
        // as long as the workers conform to the HMUploadWorkerProtocol.
        [HMUploadManager.sh addWorkers:[HMUploadS3Worker instantiateWorkers:5]];
        [HMUploadManager.sh startMonitoring];
        
        //
        // Start monitoring reachability.
        // Observe notification in your UI, if you want to inform the user
        // about reachability changes.
        [HMServer.sh startMonitoringReachability];
    });
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

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onChangedSliderValue:(UISlider *)sender
{
    [self updateSliceWithCurrentValue];
}

- (IBAction)onPressedRandomValueButton:(UIButton *)sender
{
    self.guiSlider.value = ((double)arc4random() / ARC4RANDOM_MAX);
    [self updateSliceWithCurrentValue];
}

- (IBAction)onPressedStartCountdownButton:(id)sender
{
    [self.guiCountDownLabel startTicking];
}

- (IBAction)onPressedStart:(id)sender {
    [self performSegueWithIdentifier:@"start" sender:nil];
}

@end
