//
//  HMRecorderBottomBarViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderBottomBarViewController.h"
#import "AMBlurView.h"

@interface HMRecorderBottomBarViewController ()

@end

@implementation HMRecorderBottomBarViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewDidAppear:(BOOL)animated
{
    [self initGUI];
}

-(void)initGUI
{
    [self updateSceneLabel];
}

#pragma mark - Scenes
-(void)updateSceneLabel
{
    //NSNumber *s
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onTappedClosedBottomBar:(UITapGestureRecognizer *)sender
{
    [self.remakerDelegate toggleOptions];
}


@end
