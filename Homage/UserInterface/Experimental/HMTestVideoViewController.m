//
//  HMTestVideoViewController.m
//  Homage
//
//  Created by Yoav Caspin on 5/11/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMTestVideoViewController.h"
#import "HMSimpleVideoViewController.h"
#import "HMSimpleVideoPlayerDelegate.h"

@interface HMTestVideoViewController () <HMSimpleVideoPlayerDelegate>

@property (strong,nonatomic) HMSimpleVideoViewController *moviePlayerVC;
@property (weak, nonatomic) IBOutlet UIView *guiVideoContainer;
@property (nonatomic) CGRect defaultFrame;

@end

@implementation HMTestVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* code for almovieplayer
    //create a player
    self.moviePlayer = [[ALMoviePlayerController alloc] initWithFrame:self.guiVideoContainer.bounds];
    [self displayRect:@"self.moviePlayer.view.frame" BoundsOf:self.moviePlayer.view.frame];
    self.moviePlayer.view.alpha = 0.f;
    self.moviePlayer.delegate = self; //IMPORTANT!
    
    //create the controls
    ALMoviePlayerControls *movieControls = [[ALMoviePlayerControls alloc] initWithMoviePlayer:self.moviePlayer style:ALMoviePlayerControlsStyleEmbedded];
    //[movieControls setAdjustsFullscreenImage:NO];
    [movieControls setBarColor:[UIColor colorWithRed:195/255.0 green:29/255.0 blue:29/255.0 alpha:0.5]];
    [movieControls setTimeRemainingDecrements:YES];
    //[movieControls setFadeDelay:2.0];
    //[movieControls setBarHeight:100.f];
    //[movieControls setSeekRate:2.f];
    
    //assign controls
    [self.moviePlayer setControls:movieControls];
    [self.view addSubview:self.moviePlayer.view];
    
    //THEN set contentURL
    [self.moviePlayer setContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]]];
    
    //delay initial load so statusBarOrientation returns correct value
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self configureViewForOrientation:[[UIDevice currentDevice] orientation]];
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
            self.moviePlayer.view.alpha = 1.f;
        } completion:^(BOOL finished) {
            self.navigationItem.leftBarButtonItem.enabled = YES;
            self.navigationItem.rightBarButtonItem.enabled = YES;
        }];
    });
    
    
    // Do any additional setup after loading the view.*/
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initMoviePlayer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initMoviePlayer
{
    HMSimpleVideoViewController *vc;
    self.moviePlayerVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiVideoContainer rotationSensitive:YES];
    self.moviePlayerVC.videoURL = [[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]] absoluteString];
    //[self.videoView hideVideoLabel];
    //[self.videoView hideMediaControls];
    
    self.moviePlayerVC.videoImage = [UIImage imageNamed:@"missingThumbnail"];
    self.moviePlayerVC.delegate = self;
    self.moviePlayerVC.resetStateWhenVideoEnds = YES;
}

#pragma mark - Orientations
-(BOOL)shouldAutorotate
{
    return YES;
}


-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    //[self configureViewForOrientation:toInterfaceOrientation];
}


-(void)displayRect:(NSString *)name BoundsOf:(CGRect)rect
{
    CGSize size = rect.size;
    CGPoint origin = rect.origin;
    NSLog(@"%@ bounds: origin:(%f,%f) size(%f %f)" , name , origin.x , origin.y , size.width , size.height);
}

@end
