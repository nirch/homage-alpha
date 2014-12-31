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
#import "HMRegularFontLabel.h"
#import "HMBoldFontButton.h"
#import "HMNotificationCenter.h"

@interface HMSplashViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;
@property (weak, nonatomic) IBOutlet HMToonBGView *guiBGView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiFailedToConnectLabel;
@property (weak, nonatomic) IBOutlet HMBoldFontButton *guiTryAgainButton;




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

-(void)showFailedToConnectMessage
{
    [self.guiActivity stopAnimating];
    self.guiFailedToConnectLabel.hidden = NO;
    self.guiTryAgainButton.hidden = NO;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedTryAgain:(id)sender
{
    self.guiTryAgainButton.hidden = YES;
    self.guiFailedToConnectLabel.hidden = YES;
    [self.guiActivity startAnimating];
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UI_USER_RETRIES_LOGIN_AS_GUEST
                                                        object:nil
                                                      userInfo:nil];
}


@end
