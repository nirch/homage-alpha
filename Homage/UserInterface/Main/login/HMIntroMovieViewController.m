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
    if (!self.moviePlayer.isFullscreen) [self stopStoryMoviePlayer];
    
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

    for (HMFontButton *button in self.buttonCollection)
    {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"DINOT-regular" size:button.titleLabel.font.pointSize];
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)initStoryMoviePlayer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);

    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]]];
    [self.moviePlayer.view setFrame:self.guiIntroMovieContainer.frame];
    [self.moviePlayer play];
    [self.view addSubview:self.moviePlayer.view];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)stopStoryMoviePlayer
{
    [self.moviePlayer stop];
}

- (IBAction)onPressedSkipButton:(UIButton *)sender {
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);

    [self.moviePlayer stop];
    [[Mixpanel sharedInstance] track:@"HitSkipButton"];
    [self.delegate onLoginPressedSkip];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (IBAction)onPressedShootFirstMovie:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);

    [self.moviePlayer stop];
    [[Mixpanel sharedInstance] track:@"HitShootFirst"];
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

@end
