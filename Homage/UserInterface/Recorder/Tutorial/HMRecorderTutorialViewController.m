//
//  HMRecorderTutorialViewController.m
//  Homage
//
//  Created by Aviv Wolf on 3/2/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderTutorialViewController.h"

#import "DB.h"

@interface HMRecorderTutorialViewController ()

@property (weak, nonatomic) IBOutlet UILabel *guiSceneDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *guiSceneDurationPosition;

@property (weak, nonatomic) IBOutlet UILabel *guiGetInspiredLabel;
@property (weak, nonatomic) IBOutlet UIView *guiGetInspiredPosition;

@property (weak, nonatomic) IBOutlet UILabel *guiFigureLabel;
@property (weak, nonatomic) IBOutlet UIView *guiFigurePosition;

@property (weak, nonatomic) IBOutlet UILabel *guiWallLabel;
@property (weak, nonatomic) IBOutlet UIView *guiWallPosition;

@property (nonatomic) NSArray *labels;
@property (nonatomic) NSArray *positions;
@property (nonatomic) NSInteger index;
@property (nonatomic) NSArray *tutorials;

@end

@implementation HMRecorderTutorialViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.index = 0;
    
    self.tutorials = @[
                       @[@0,@1],
                       @[@2,@3]
                       ];
    
    [self showTutorialAtIndex:self.index];
}

-(void)initGUI
{
    self.labels = @[self.guiSceneDurationLabel,
                    self.guiGetInspiredLabel,
                    self.guiFigureLabel,
                    self.guiWallLabel];
    
    self.positions = @[self.guiSceneDurationPosition,
                       self.guiGetInspiredPosition,
                       self.guiFigurePosition,
                       self.guiWallPosition];
    
    
    [self hideAllAnimated:NO];

}

-(void)hideAllAnimated:(BOOL)animated
{
    if (!animated) {
        for (UIView *view in self.positions) view.hidden = YES;
        for (UILabel *label in self.labels) label.alpha = 0;
        return;
    }
    
    [UIView animateWithDuration:0.7 animations:^{
        [self hideAllAnimated:NO];
    }];
}

#pragma mark - Flow
-(void)next
{
    self.index++;
    [self showTutorialAtIndex:self.index];
}

-(void)done
{
    [self.remakerDelegate dismissOverlayAdvancingState:YES info:@{@"dismissing help screen":@YES}];
    
    User *user = [User current];
    user.skipRecorderTutorial = @YES;
}

#pragma mark - Showing tutorial messages
-(void)showTutorialAtIndex:(NSInteger)index
{
    [self hideAllAnimated:YES];

    if (self.index >= self.tutorials.count) {
        [self done];
        return;
    }
    
    NSArray *indexesToReveal = self.tutorials[index];
    [UIView animateWithDuration:1.0 animations:^{
        for (NSNumber *indexNumber in indexesToReveal) {
            NSInteger index = indexNumber.integerValue;
            UILabel *label = self.labels[index];
            label.alpha = 1;
        };
    }];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNextButton:(id)sender
{
    [self next];
}


@end
