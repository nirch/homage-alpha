//
//  HMRenderingViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRenderingViewController.h"

@interface HMRenderingViewController ()

@end

@implementation HMRenderingViewController

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
    self.guiProgressBarView.delegate = self;
    [self initGUI];
    self.guiProgressBarView.duration = 5;
    [self.guiProgressBarView start];
	// Do any additional setup after loading the view.
}

-(void)initGUI
{
    UIColor *homageColor = [UIColor colorWithRed:255 green:125 blue:95 alpha:1];
    [self.view sendSubviewToBack:self.guiDoneRenderingView];
    [self.view addSubview:self.guiInProgressView];
    self.guiInProgressLabel.textColor = homageColor;
    self.guiDoneLabel.textColor = homageColor;
    self.guiProgressBar.backgroundColor = homageColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)timeProgressDidStartAtTime:(NSDate *)time forDuration:(NSTimeInterval)duration
{
    
}
-(void)timeProgressWasCancelledAfterDuration:(NSTimeInterval)duration
{
    
}
-(void)timeProgressDidFinishAfterDuration:(NSTimeInterval)duration
{
    [UIView transitionFromView:self.guiInProgressView
                        toView:self.guiDoneRenderingView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished){
                        [self.guiInProgressView removeFromSuperview];
                    }];
}

- (IBAction)movieDoneTapped:(UITapGestureRecognizer *)sender {
    //TODO: go to me tab
    
}


@end
