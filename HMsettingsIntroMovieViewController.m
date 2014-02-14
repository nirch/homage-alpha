//
//  HMsettingsIntroMovieViewController.m
//  Homage
//
//  Created by Yoav Caspin on 2/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMsettingsIntroMovieViewController.h"
@import MediaPlayer;
@import AVFoundation;

@interface HMsettingsIntroMovieViewController ()

@property (strong,nonatomic) MPMoviePlayerController *moviePlayer;

@end

@implementation HMsettingsIntroMovieViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
	
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.moviePlayer stop];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initMoviePlayer];
}

-(void)initMoviePlayer
{
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]]];
    [self.moviePlayer.view setFrame:self.guiMoviePlaceHolder.frame];
    [self.moviePlayer play];
    [self.view addSubview:self.moviePlayer.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
