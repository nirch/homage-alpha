//
//  HMIntroMovieViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMIntroMovieViewController.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import "HMRegularFontButton.h"
#import "HMServer+Users.h"
#import "HMServer+Remakes.h"
#import "HMRecorderViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "Mixpanel.h"
#import "HMStyle.h"
#import "HMSimpleVideoViewController.h"
#import "HMServer+analytics.h"
@import MediaPlayer;
@import AVFoundation;



@interface HMIntroMovieViewController () <UITextFieldDelegate,HMSimpleVideoPlayerDelegate>


@property (weak, nonatomic) IBOutlet UIButton *guiIntroSkipButton;
@property (weak, nonatomic) IBOutlet UIButton *guiShootFirstStoryButton;
@property (weak, nonatomic) IBOutlet UIView *guiIntroMovieContainer;
@property (strong,nonatomic) HMSimpleVideoViewController *moviePlayerVC;

@property (strong, nonatomic) IBOutletCollection(HMRegularFontButton) NSArray *buttonCollection;


@end

@implementation HMIntroMovieViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //when switching movieplayer to full screen, viewWillDisappear is also called
    [self.moviePlayerVC done];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}


-(void)initGUI
{
}

-(void)initIntroMoviePlayer
{
    HMSimpleVideoViewController *vc;
    self.moviePlayerVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiIntroMovieContainer rotationSensitive:YES];
    self.moviePlayerVC.videoURL = [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]] absoluteString];
    [self.moviePlayerVC hideVideoLabel];
    [self.moviePlayerVC hideMediaControls];
    self.moviePlayerVC.videoImage = [UIImage imageNamed:@"introMovieThumbnail"];
    self.moviePlayerVC.delegate = self;
    self.moviePlayerVC.resetStateWhenVideoEnds = YES;
    self.moviePlayerVC.originatingScreen = [NSNumber numberWithInteger:HMWelcomeScreen];
    self.moviePlayerVC.entityType = [NSNumber numberWithInteger:HMIntroMovie];
    self.moviePlayerVC.entityID = @"none";
    [self.moviePlayerVC play];
}


- (IBAction)onPressedSkipButton:(UIButton *)sender {
    // Deprecated event
    //[[Mixpanel sharedInstance] track:@"HitSkipButton"];
    [self.moviePlayerVC done];
    [self.delegate onLoginPressedSkip];
}

- (IBAction)onPressedShootFirstMovie:(UIButton *)sender
{
    [[Mixpanel sharedInstance] track:@"pushed lets create"];
    [self.moviePlayerVC done];
    [self.delegate onLoginPressedShootFirstStory];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
    
}

#pragma mark HMSimpleVideoViewController delegate
-(void)stopMoviePlayer
{
    [self.moviePlayerVC done];
}


@end
