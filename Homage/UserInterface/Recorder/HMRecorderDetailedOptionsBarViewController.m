//
//  HMRecorderDetailedOptionsBarViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderDetailedOptionsBarViewController.h"
#import "DB.h"
#import "HMSceneCell.h"
#import "HMNotificationCenter.h"

@interface HMRecorderDetailedOptionsBarViewController ()

@property (weak, nonatomic) IBOutlet UITableView *guiTableView;
@property (weak, nonatomic) IBOutlet UIView *guiRoundViewCoveringButton;
@property (nonatomic) NSArray *scenes;

@end

@implementation HMRecorderDetailedOptionsBarViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initObservers];
    
    Remake *remake = [self.remakerDelegate remake];
    self.scenes = [remake.story.scenes allObjects];
}

#pragma mark - Obesrvers
-(void)initObservers
{
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRecorderDetailedOptionsClosing:)
                                                       name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSING
                                                     object:nil];
    
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRecorderDetailedOptionsClosed:)
                                                       name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED
                                                     object:nil];
    
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRecorderDetailedOptionsOpening:)
                                                       name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENING
                                                     object:nil];
    
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRecorderDetailedOptionsOpened:)
                                                       name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENED
                                                     object:nil];
}

#pragma mark - Observers handlers
-(void)onRecorderDetailedOptionsClosed:(NSNotification *)notification
{
    self.guiRoundViewCoveringButton.hidden = NO;
    self.guiRoundViewCoveringButton.alpha = 0;
    self.guiRoundViewCoveringButton.transform = CGAffineTransformMakeScale(0.0, 0.0);
    [UIView animateWithDuration:0.3 animations:^{
        self.guiRoundViewCoveringButton.transform = CGAffineTransformIdentity;
        self.guiRoundViewCoveringButton.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)onRecorderDetailedOptionsClosing:(NSNotification *)notification
{

}

-(void)onRecorderDetailedOptionsOpened:(NSNotification *)notification
{
    self.guiRoundViewCoveringButton.alpha = 1;
    [UIView animateWithDuration:0.4 animations:^{
        self.guiRoundViewCoveringButton.alpha = 0;
        self.guiRoundViewCoveringButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    } completion:^(BOOL finished) {
        self.guiRoundViewCoveringButton.hidden = YES;
    }];
}
-(void)onRecorderDetailedOptionsOpening:(NSNotification *)notification
{

}

#pragma mark - Table Data Source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.scenes.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"scene cell";
    HMSceneCell *cell = [self.guiTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(HMSceneCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSInteger sceneNumber = self.scenes.count - indexPath.row;
    cell.guiSceneLabel.text = [NSString stringWithFormat:@"SCENE %02ld", (long)sceneNumber];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedCloseButton:(UIButton *)sender
{
    [self.remakerDelegate toggleOptions];
}


@end
