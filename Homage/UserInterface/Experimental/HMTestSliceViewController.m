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
    User *user = [User userWithID:@"someTest@homage.it" inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    [DB.sh save];
    
    //
    [self performSegueWithIdentifier:@"start" sender:nil];
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
