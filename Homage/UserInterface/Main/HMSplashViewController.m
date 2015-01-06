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
@property (weak, nonatomic) IBOutlet UIImageView *guiTopLogo;

@property (weak, nonatomic) MONActivityIndicatorView *activityView;

@end

@implementation HMSplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self revealAnimations];
}

-(void)initGUI
{
    // ************
    // *  STYLES  *
    // ************

    // The activity view.
    MONActivityIndicatorView *activityView = [[MONActivityIndicatorView alloc] init];
    [self.view addSubview:activityView];
    activityView.numberOfCircles = [HMStyle.sh floatValueForKey:V_SPLASH_ACTIVITY_CIRCLES_COUNT];
    activityView.radius = [HMStyle.sh floatValueForKey:V_SPLASH_ACTIVITY_CIRCLES_RADIUS];
    activityView.internalSpacing = 3;
    activityView.duration = 0.5;
    activityView.delegate = self;
    self.activityView = activityView;

    // Position the activity view.
    CGPoint p = self.view.center;
    p.y = [HMStyle.sh floatValueForKey:V_SPLASH_ACTIVITY_POSITION];
    activityView.center = p;
}

-(void)revealAnimations
{
    [UIView animateWithDuration:0.2
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.7
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.guiTopLogo.transform = CGAffineTransformMakeScale(1.2, 1.1);
                     } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.5 animations:^{
                            self.guiTopLogo.transform = CGAffineTransformIdentity;
                        }];
                     }];
}

-(void)prepare
{
    
}

-(void)start
{
    [self.activityView startAnimating];
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

#pragma mark - MONActivityIndicatorViewDelegate
-(UIColor *)activityIndicatorView:(MONActivityIndicatorView *)activityIndicatorView circleBackgroundColorAtIndex:(NSUInteger)index
{
    UIColor *color;
    color = [HMStyle.sh colorNamed:C_ARRAY_SPLASH_ACTIVITY_INDICATOR
                           atIndex:index];
    return color;
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
