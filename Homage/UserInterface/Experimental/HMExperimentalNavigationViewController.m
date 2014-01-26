//
//  HMExperimentalNavigationViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMExperimentalNavigationViewController.h"

@interface HMExperimentalNavigationViewController ()

@end

@implementation HMExperimentalNavigationViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
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
