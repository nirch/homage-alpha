//
//  HMStoryDetailsViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryDetailsViewController.h"

#import "DB.h"
#import "HMNotificationCenter.h"
#import "HMServer+Remakes.h"

#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMRecorderViewController.h"

@interface HMStoryDetailsViewController ()

@end

@implementation HMStoryDetailsViewController

@synthesize story = _story;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initObservers];
	[self initGUI];
}

-(void)initGUI
{
    self.title = self.story.name;
    self.guiThumbnailImage.image = self.story.thumbnail;
    self.guiBGImageView.image = [self.story.thumbnail applyBlurWithRadius:2.0 tintColor:nil saturationDeltaFactor:0.3 maskImage:nil];
    [self.guiBGImageView addMotionEffectWithAmount:-30];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeCreation:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_CREATION
                                                     object:nil];
}

#pragma mark - Observers handlers
-(void)onRemakeCreation:(NSNotification *)notification
{
    // Update UI
    self.guiRemakeButton.enabled = YES;
    [self.guiRemakeActivity stopAnimating];
    
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (notification.isReportingError || !remake) {
        [self remakeCreationFailMessage];
        return;
    }
    
    // Present the recorder for the newly created remake.
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:nil];
}

#pragma mark - Alerts
-(void)remakeCreationFailMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"Failed creating remake.\n\nTry again later."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRemakeButton:(UIButton *)sender
{
    self.guiRemakeButton.enabled = NO;
    [self.guiRemakeActivity startAnimating];
    [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID];
}


@end
