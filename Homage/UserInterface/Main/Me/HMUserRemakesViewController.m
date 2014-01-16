//
//  HMUserRemakesViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUserRemakesViewController.h"

#import "HMServer+Remakes.h"
#import "DB.h"
#import "HMNotificationCenter.h"

@interface HMUserRemakesViewController ()

@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIButton *guiRefreshButton;

@end

@implementation HMUserRemakesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initObservers];
    [self refetchUserRemakes];
}

-(void)refetchUserRemakes
{
    [self.guiActivity startAnimating];
    self.guiLabel.text = @"Loading remakes...";
    self.guiRefreshButton.hidden = YES;
    [HMServer.sh refetchRemakesForUserID:User.current.sID];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onFetchedUserRemakes:)
                                                       name:HM_NOTIFICATION_SERVER_FETCHED_USER_REMAKES
                                                     object:nil];
}

#pragma mark - notifications handler
-(void)onFetchedUserRemakes:(NSNotification *)notification
{
    NSLog(@"notification info : %@", notification.userInfo);
    [self.guiActivity stopAnimating];
    self.guiRefreshButton.hidden = NO;
    self.guiLabel.text = @"Fetched.";
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRefreshButton:(UIButton *)sender
{
    [self refetchUserRemakes];
}


@end
