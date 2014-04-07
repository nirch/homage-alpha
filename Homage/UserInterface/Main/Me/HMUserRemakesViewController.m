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
#import "HMRecorderViewController.h"

@interface HMUserRemakesViewController ()

@property (weak, nonatomic) IBOutlet UIPickerView *guiPicker;
@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIButton *guiRefreshButton;
@property (atomic, readonly) NSArray *remakes;

@end

@implementation HMUserRemakesViewController

@synthesize remakes = _remakes;

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initObservers];
    [self refetchUserRemakesFromServer];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refreshRemakes];
    [self.guiPicker reloadAllComponents];
}

-(void)refetchUserRemakesFromServer
{
    [self.guiActivity startAnimating];
    self.guiLabel.text = @"Loading remakes...";
    self.guiRefreshButton.hidden = YES;
    [HMServer.sh refetchRemakesForUserID:User.current.userID];
}

-(NSArray *)remakes
{
    if (!_remakes) _remakes = User.current.remakes.allObjects;
    return _remakes;
}

-(void)refreshRemakes
{
    _remakes = nil;
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onFetchedUserRemakes:)
                                                       name:HM_NOTIFICATION_SERVER_USER_REMAKES
                                                     object:nil];
}

#pragma mark - notifications handler
-(void)onFetchedUserRemakes:(NSNotification *)notification
{
    //NSLog(@"notification info : %@", notification.userInfo);
    [self.guiActivity stopAnimating];
    self.guiRefreshButton.hidden = NO;
    self.guiLabel.text = @"Fetched.";
    [self refreshRemakes];
    [self.guiPicker reloadAllComponents];
}

#pragma mark - Picker data source
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return User.current.remakes.count;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    Remake *remake = self.remakes[row];
    NSString *title = [NSString stringWithFormat:@"%@ : ...%@", remake.story.name, [remake.sID substringFromIndex:18]];
    return title;
}

#pragma mark - Edit & Delete
-(void)deleteRemakeAtIndex:(NSInteger)index
{
    // Validate index.
    if (self.remakes.count==0 || index>=self.remakes.count) return;
    
    // Delete from server & local storage.
    Remake *remake = self.remakes[index];
    [HMServer.sh deleteRemakeWithID:remake.sID];
    [DB.sh.context deleteObject:remake];

    // Refresh UI
    [self refreshRemakes];
    [self.guiPicker reloadAllComponents];
}

-(void)editRemakeAtIndex:(NSInteger)index
{
    // Validate index.
    if (self.remakes.count==0 || index>=self.remakes.count) return;

    // Open recorder for the selected remake.
    Remake *remake = self.remakes[index];
    if (!remake) return;
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:nil];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRefreshButton:(UIButton *)sender
{
    [self refetchUserRemakesFromServer];
}

- (IBAction)onPressedEditButton:(UIButton *)sender
{
    NSInteger index = [self.guiPicker selectedRowInComponent:0];
    [self editRemakeAtIndex:index];
}

- (IBAction)onPressedDeleteButton:(UIButton *)sender
{
    NSInteger index = [self.guiPicker selectedRowInComponent:0];
    [self deleteRemakeAtIndex:index];
}


@end
