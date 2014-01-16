//
//  HMStoryDetailsViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryDetailsViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "DB.h"
#import "HMServer+Remakes.h"

@interface HMStoryDetailsViewController ()

@end

@implementation HMStoryDetailsViewController

@synthesize story = _story;

-(void)viewDidLoad
{
    [super viewDidLoad];
	[self initGUI];
}


-(void)initGUI
{
    self.title = self.story.name;
    self.guiThumbnailImage.image = self.story.thumbnail;
    self.guiBGImageView.image = [self.story.thumbnail applyBlurWithRadius:2.0 tintColor:nil saturationDeltaFactor:0.3 maskImage:nil];
    [self.guiBGImageView addMotionEffectWithAmount:-30];
}

-(void)remakeStory
{
    [HMServer.sh remakeStoryWithID:self.story.sID forUserID:User.current.userID];
}

#pragma mark - Navigation
-(void)navigateToRecorderForRemake:(Remake *)remake
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"RecorderStoryboard" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Recorder"];
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRemakeButton:(UIButton *)sender
{
    self.guiRemakeButton.enabled = NO;
    [self.guiRemakeActivity startAnimating];
    [self remakeStory];
}


@end
