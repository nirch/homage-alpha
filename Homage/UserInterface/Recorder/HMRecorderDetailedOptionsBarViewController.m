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

@interface HMRecorderDetailedOptionsBarViewController ()

@property (weak, nonatomic) IBOutlet UITableView *guiTableView;
@property (nonatomic) NSArray *scenes;

@end

@implementation HMRecorderDetailedOptionsBarViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    Remake *remake = [self.remakerDelegate remake];
    self.scenes = [remake.story.scenes allObjects];
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
    cell.guiSceneLabel.text = [NSString stringWithFormat:@"SCENE %02d", sceneNumber];
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
