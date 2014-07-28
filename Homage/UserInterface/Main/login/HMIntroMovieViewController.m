//
//  HMIntroMovieViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMIntroMovieViewController.h"
#import "HMAvenirBookFontLabel.h"
#import "HMAvenirBookFontButton.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import "HMServer+Users.h"
#import "HMServer+Remakes.h"
#import "HMRecorderViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "Mixpanel.h"
#import "HMColor.h"
#import "HMSimpleVideoViewController.h"
#import "HMServer+analytics.h"
@import MediaPlayer;
@import AVFoundation;



@interface HMIntroMovieViewController () <UITextFieldDelegate,HMSimpleVideoPlayerDelegate>


@property (weak, nonatomic) IBOutlet UIButton *guiIntroSkipButton;
@property (weak, nonatomic) IBOutlet UIButton *guiShootFirstStoryButton;
@property (weak, nonatomic) IBOutlet UIView *guiIntroMovieContainer;
@property (strong,nonatomic) HMSimpleVideoViewController *moviePlayerVC;

@property (strong, nonatomic) IBOutletCollection(HMAvenirBookFontButton) NSArray *buttonCollection;


@end

@implementation HMIntroMovieViewController

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    [self initGUI];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(void)viewWillDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    //when switching movieplayer to full screen, viewWillDisappear is also called
    [self.moviePlayerVC done];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}

-(void)viewDidDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}


-(void)initGUI
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)initIntroMoviePlayer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);

    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMSimpleVideoViewController *vc;
    self.moviePlayerVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiIntroMovieContainer rotationSensitive:YES];
    self.moviePlayerVC.videoURL = [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]] absoluteString];
    [self.moviePlayerVC hideVideoLabel];
    [self.moviePlayerVC hideMediaControls];
    self.moviePlayerVC.videoImage = [UIImage imageNamed:@"introMovieThumbnail"];
    self.moviePlayerVC.delegate = self;
    self.moviePlayerVC.resetStateWhenVideoEnds = YES;
    self.moviePlayerVC.originatingScreen = @"intro_screen";
    self.moviePlayerVC.entityType = HMIntroMovie;
    self.moviePlayerVC.entityID = @"none";
    [self.moviePlayerVC play];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


- (IBAction)onPressedSkipButton:(UIButton *)sender {
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [[Mixpanel sharedInstance] track:@"HitSkipButton"];
    [self.moviePlayerVC done];
    [self.delegate onLoginPressedSkip];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (IBAction)onPressedShootFirstMovie:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [[Mixpanel sharedInstance] track:@"pushed lets create"];
    [self.moviePlayerVC done];
    [self.delegate onLoginPressedShootFirstStory];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}

- (void)didReceiveMemoryWarning
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
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
