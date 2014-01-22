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

@interface HMTestSliceViewController ()

@property (weak, nonatomic) IBOutlet HMRoundCountdownLabel *guiCountDownLabel;

@end

@implementation HMTestSliceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSliceWithCurrentValue];
    [self.guiBGImage addMotionEffectWithAmount:-20];
}

-(void)updateSliceWithCurrentValue
{
    self.guiSlice.value = self.guiSlider.value;
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


@end
