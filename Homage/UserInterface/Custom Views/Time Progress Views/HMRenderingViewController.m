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
    self.guiProgressBar.duration = 30;
    [self.guiProgressBar start];
	// Do any additional setup after loading the view.
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
     
    
}

@end
