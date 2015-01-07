//
//  HMParentalControlViewController.m
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMParentalControlViewController.h"
#import "AMBlurView.h"
#import "HMStyle.h"
#import <AVFoundation/AVFoundation.h>
#import "HMRegularFontLabel.h"
#import "HMBoldFontLabel.h"

#define MAX_LENGTH 3

@interface HMParentalControlViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurredBG;

// Titles
@property (weak, nonatomic) IBOutlet HMBoldFontLabel *guiTitle;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiInstructions;
@property (weak, nonatomic) IBOutlet HMBoldFontLabel *guiRequiredNumbersLabel;

// Input
@property (weak, nonatomic) IBOutlet UIView *guiStretchableContainer;
@property (weak, nonatomic) IBOutlet UIView *guiNumbersContainer;
@property (weak, nonatomic) IBOutlet UILabel *guiNumbersLabel;

// Numpad
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *guiNumKeys;

// The number
@property (strong, nonatomic) NSMutableString *requiredNumberString;
@property (strong, nonatomic) NSMutableArray *requiredDigitsArray;
@property (strong, nonatomic) NSMutableArray *requiredDigitsAsWordsArray;
@property (strong, nonatomic) NSMutableString *enteredNumberString;
@property (strong, nonatomic) NSArray *numbersNames;

@end

@implementation HMParentalControlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
    [self initRNG];
    [self updateNumbersLabel];
}

-(void)initGUI
{
    // Blurry background
    [[AMBlurView new] insertIntoView:self.guiBlurredBG];
    
    // Buttons
    for (UIButton *button in self.guiNumKeys) {
        CGFloat s = button.bounds.size.height;
        CALayer *bl = button.layer;
        bl.cornerRadius = s/2;
        bl.borderWidth = 2;
        bl.shadowColor = [UIColor blackColor].CGColor;
        bl.shadowRadius = 3;
        bl.shadowOffset = CGSizeMake(2, 2);
    }
    
    // The containers of the entered numbers
    self.guiNumbersContainer.backgroundColor = [UIColor clearColor];
    self.guiNumbersContainer.layer.borderColor = [UIColor whiteColor].CGColor;
    self.guiNumbersContainer.layer.borderWidth = 3;
    self.guiNumbersContainer.layer.cornerRadius = 5;
    
    // ************
    // *  STYLES  *
    // ************

    // Titles
    self.guiTitle.textColor = [HMStyle.sh colorNamed:C_STORE_PC_TITLE];
    self.guiInstructions.textColor = [HMStyle.sh colorNamed:C_STORE_PC_INPUT_TEXT];
    self.guiRequiredNumbersLabel.textColor = [HMStyle.sh colorNamed:C_STORE_PC_INPUT_TEXT];
    self.guiNumbersLabel.textColor = [HMStyle.sh colorNamed:C_STORE_PC_INPUT_TEXT];
    self.guiNumbersContainer.layer.borderColor = [HMStyle.sh colorNamed:C_STORE_PC_INPUT_BORDER].CGColor;
    
    // Num pad keys
    for (UIButton *button in self.guiNumKeys) {
        button.backgroundColor = [HMStyle.sh colorNamed:C_STORE_PC_NUM_KEY_BG];
        [button setTitleColor:[HMStyle.sh colorNamed:C_STORE_PC_NUM_KEY_TEXT] forState:UIControlStateNormal];
        button.layer.borderColor = [HMStyle.sh colorNamed:C_STORE_PC_NUM_KEY_STROKE].CGColor;
    }
    
}

-(void)initRNG
{
    self.numbersNames = @[
                          @"zero",
                          @"one",
                          @"two",
                          @"three",
                          @"four",
                          @"five",
                          @"six",
                          @"seven",
                          @"eight",
                          @"nine",
                          @"ten"
                          ];
    
    [self initRandomDigitsStringOfLength:MAX_LENGTH];
    self.enteredNumberString = [NSMutableString new];
    self.guiRequiredNumbersLabel.text = [self.requiredDigitsAsWordsArray componentsJoinedByString:@", "];
}

-(void)initRandomDigitsStringOfLength:(NSInteger)length
{
    self.requiredDigitsArray = [NSMutableArray new];
    self.requiredDigitsAsWordsArray = [NSMutableArray new];
    self.requiredNumberString = [NSMutableString new];

    // Create the random sequence of digits.
    for (NSInteger i=0;i<length;i++) {
        NSInteger num = arc4random() %10;
        [self.requiredNumberString appendFormat:@"%ld", (long)num];
        [self.requiredDigitsArray addObject:@(num)];
        [self.requiredDigitsAsWordsArray addObject:self.numbersNames[num]];
    }
}

#pragma mark - Numbers input
// Input
-(void)addNumber:(long)number
{
    if (self.enteredNumberString.length < MAX_LENGTH) {
        [self.enteredNumberString appendFormat:@"%ld",number];
    }
    [self updateNumbersLabel];
}

-(void)removeLastNumber
{
    if (self.enteredNumberString.length > 0) {
        [self.enteredNumberString deleteCharactersInRange:NSMakeRange([self.enteredNumberString length]-1, 1)];
    }
    [self updateNumbersLabel];
}

-(void)updateNumbersLabel
{
    self.guiNumbersLabel.text = self.enteredNumberString;
}

-(void)animateKeyPress:(UIButton *)sender
{
    sender.transform = CGAffineTransformMakeScale(0.9, 0.9);
    sender.alpha = 0.9;
    [UIView animateWithDuration:1.0
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         sender.transform = CGAffineTransformIdentity;
                         sender.alpha = 1;
    } completion:nil];
}

-(void)validateNumber
{
    // Validate what was entered.
    if ([self.enteredNumberString isEqualToString:self.requiredNumberString]) {
        [self.delegate parentalControlValidatedSuccessfully];
        return;
    }

    // The entered number is wrong.
    // Notify user (but only if he already entered max number of digits)
    if (self.enteredNumberString.length >= MAX_LENGTH) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);

        // Shake the wrong number
        CAKeyframeAnimation * anim = [ CAKeyframeAnimation animationWithKeyPath:@"transform" ] ;
        anim.values = @[ [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(-5.0f, 0.0f, 0.0f) ], [ NSValue valueWithCATransform3D:CATransform3DMakeTranslation(5.0f, 0.0f, 0.0f) ] ] ;
        anim.autoreverses = YES ;
        anim.repeatCount = 2.0f ;
        anim.duration = 0.07f ;
        [self.guiNumbersContainer.layer addAnimation:anim forKey:nil] ;
    }
    
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNumKey:(UIButton *)sender
{
    NSInteger n = sender.tag;
    [self addNumber:n];
    [self animateKeyPress:sender];
    [self validateNumber];
}

- (IBAction)onPressedBackButton:(UIButton *)sender
{
    [self removeLastNumber];
    [self animateKeyPress:sender];
}

@end
