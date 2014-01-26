//
//  HMSimpleStoriesViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSimpleDataViewController.h"
#import "DB.h"
#import "HMServer+Remakes.h"
#import "HMServer+Stories.h"
#import "HMRecorderViewController.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMNotificationCenter.h"
#import "HMRecorderViewController.h"

@interface HMSimpleDataViewController ()
@property (weak, nonatomic) IBOutlet UIPickerView *guiPickerView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *guiSegmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *guiCreateButton;
@property (weak, nonatomic) IBOutlet UIButton *guiEditButton;
@property (weak, nonatomic) IBOutlet UIButton *guiDeleteButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiReachabilityImage;

@property (nonatomic) NSArray *stories;
@property (nonatomic) NSArray *remakes;

@end

@implementation HMSimpleDataViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.guiReachabilityImage.hidden = HMServer.sh.isReachable;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initObservers];
    [self refreshUI];
    [self updateReachabilityUI];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe reachability status changes
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:HMServer.sh];

}

-(void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:HMServer.sh];
}

#pragma mark - Observers handlers
-(void)onReachabilityStatusChange:(NSNotification *)notification
{
    [self updateReachabilityUI];
}

#pragma mark - Picker data source
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (self.guiSegmentedControl.selectedSegmentIndex == 0) {
        return self.stories.count;
    } else {
        return self.remakes.count;
    }
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (self.guiSegmentedControl.selectedSegmentIndex == 0) {
        Story *story = self.stories[row];
        NSString *title = [NSString stringWithFormat:@"%@", story.name];
        return title;
    } else {
        Remake *remake = self.remakes[row];
        NSString *title = [NSString stringWithFormat:@"%@ : ...%@", remake.story.name, [remake.sID substringFromIndex:18]];
        return title;
    }
}

#pragma mark - UI
-(void)deleteRemakeAtIndex:(NSInteger)index
{
    // Validate index.
    if (self.remakes.count==0 || index>=self.remakes.count) return;
    
    // Delete from server & local storage.
    Remake *remake = self.remakes[index];
    [HMServer.sh deleteRemakeWithID:remake.sID];
    [DB.sh.context deleteObject:remake];
    [self.guiPickerView reloadAllComponents];
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


-(void)updateSelection:(NSInteger)index
{
    if (index==0) {
        self.guiCreateButton.enabled = YES;
        self.guiEditButton.enabled = NO;
        self.guiDeleteButton.enabled = NO;
    } else {
        self.guiCreateButton.enabled = NO;
        self.guiEditButton.enabled = YES;
        self.guiDeleteButton.enabled = YES;
    }
}

-(void)refreshUI
{
    [self updateSelection:self.guiSegmentedControl.selectedSegmentIndex];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HM_STORY];
    request.sortDescriptors = @[];
    NSError *error;
    self.stories = [DB.sh.context executeFetchRequest:request error:&error];
    self.remakes = User.current.remakes.allObjects;
    [self.guiPickerView reloadAllComponents];
}

-(void)updateReachabilityUI
{
    self.guiReachabilityImage.hidden = HMServer.sh.isReachable;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onChangedDateToSee:(UISegmentedControl *)sender {
    [self refreshUI];
}

- (IBAction)onRefresh:(id)sender {
    if (!HMServer.sh.isReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Server unreachable" message:@":-(" delegate:nil cancelButtonTitle:@"Darn, OK." otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [HMServer.sh refetchStories];
    [HMServer.sh refetchRemakesForUserID:User.current.userID];
}

- (IBAction)onRefreshUI:(id)sender {
    [self refreshUI];
}

- (IBAction)onPressedEditRemakeButton:(UIButton *)sender
{
    NSInteger index = [self.guiPickerView selectedRowInComponent:0];
    Remake *remake = self.remakes[index];

    UIViewController *vc = [HMRecorderViewController recorderForRemake:remake];
    if (vc) [self presentViewController:vc animated:YES completion:nil];
}

-(IBAction)onPressedDeleteRemakeButton:(UIButton *)sender
{
    NSInteger index = [self.guiPickerView selectedRowInComponent:0];
    Remake *remake = self.remakes[index];
    [HMServer.sh deleteRemakeWithID:remake.sID];
    [DB.sh.context deleteObject:remake];
    [DB.sh save];
    [self refreshUI];
}

- (IBAction)onPressedCreateRemakeForStoryButton:(UIButton *)sender
{
    NSInteger index = [self.guiPickerView selectedRowInComponent:0];
    Story *story = self.stories[index];
    [HMServer.sh createRemakeForStoryWithID:story.sID forUserID:User.current.userID];
}

- (IBAction)onPressedDebug:(id)sender {
    for (Story *story in self.stories) {
        NSLog(@"story %@, %@", story.isSelfie?@"YES":@"NOPE", story.name);
    }
}

@end
