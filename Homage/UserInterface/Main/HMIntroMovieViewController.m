//
//  HMIntroMovieViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMIntroMovieViewController.h"
#import "HMFontLabel.h"
#import "HMFontButton.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import "HMServer+Users.h"
#import "HMServer+Remakes.h"
#import "HMRecorderViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "Mixpanel.h"
#import "HMColor.h"
@import MediaPlayer;
@import AVFoundation;



@interface HMIntroMovieViewController () <UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UIButton *guiIntroSkipButton;
@property (weak, nonatomic) IBOutlet UIButton *guiShootFirstStoryButton;
@property (weak, nonatomic) IBOutlet UIView *guiIntroMovieContainer;
@property (strong,nonatomic) MPMoviePlayerController *moviePlayer;

@property (strong, nonatomic) IBOutletCollection(HMFontButton) NSArray *buttonCollection;


@end

@implementation HMIntroMovieViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
   
}

-(void)viewWillAppear:(BOOL)animated
{
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    
}


-(void)initGUI
{
    for (HMFontButton *button in self.buttonCollection)
    {
        [button setTitleColor:[HMColor.sh textImpact] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"DINOT-regular" size:button.titleLabel.font.pointSize];
    }
}

-(void)initStoryMoviePlayer
{
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]]];
    [self.moviePlayer.view setFrame:self.guiIntroMovieContainer.frame];
    [self.moviePlayer play];
    [self.view addSubview:self.moviePlayer.view];
}

- (IBAction)onPressedSkipButton:(UIButton *)sender {
    [self.moviePlayer stop];
    [[Mixpanel sharedInstance] track:@"HitSkipButton"];
    [self.delegate onLoginPressedSkip];
}

- (IBAction)onPressedShootFirstMovie:(UIButton *)sender
{
    [self.moviePlayer stop];
    [[Mixpanel sharedInstance] track:@"HitShootFirst"];
    [self.delegate onLoginPressedShootFirstStory];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
    
}

@end
