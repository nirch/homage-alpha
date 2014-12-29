//
//  HMSplashViewController.m
//  Homage
//
//  Created by Aviv Wolf on 10/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSplashViewController.h"
#import "HMToonBGView.h"
#import "HMStyle.h"

@interface HMSplashViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;
@property (weak, nonatomic) IBOutlet HMToonBGView *guiBGView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@end

@implementation HMSplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)initGUI
{
    // ************
    // *  STYLES  *
    // ************
    self.guiActivity.color = [HMStyle.sh colorNamed:C_SPLASH_ACTIVITY_INDICATOR];
}

-(void)prepare
{
    
}

-(void)start
{
    [self.guiActivity startAnimating];
}

-(void)done
{
    [self.guiActivity stopAnimating];
}

@end
