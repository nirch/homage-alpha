//
//  HMRecorderEditTextsViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderEditTextsViewController.h"
#import "DB.h"
#import "HMColor.h"
#import "AMBlurView.h"
#import "HMRecorderEditingTextCell.h"
#import "HMServer+Texts.h"
#import "HMServer+Render.h"
#import "HMNotificationCenter.h"
#import "NSString+Utilities.h"

@interface HMRecorderEditTextsViewController ()

@property (weak, nonatomic) IBOutlet UIButton *guiCreateButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiCreateMovieActivity;
@property (weak, nonatomic) IBOutlet UILabel *guiNoticeMessageLabel;

@property (nonatomic, readonly) NSArray *textsDefinitions;
@property (nonatomic, readonly) Remake *remake;

@end

@implementation HMRecorderEditTextsViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _remake = [self.remakerDelegate remake];
    _textsDefinitions = self.remake.story.textsOrdered;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

#pragma mark - Obesrvers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    // Observe updating server with texts
    [nc addUniqueObserver:self
                 selector:@selector(onTextUpdate:)
                     name:HM_NOTIFICATION_SERVER_TEXT
                   object:nil];

    // Observe telling server to render
    [nc addUniqueObserver:self
                 selector:@selector(onRender:)
                     name:HM_NOTIFICATION_SERVER_RENDER
                   object:nil];

}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_TEXT object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_RENDER object:nil];
}


#pragma mark - Observers handlers
-(void)onTextUpdate:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSInteger index = [info[@"textID"] integerValue] - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    HMRecorderEditingTextCell *cell = (HMRecorderEditingTextCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self validateTextAtIndexPath:indexPath];
    [cell.guiActivity stopAnimating];

    if (notification.isReportingError) {
        cell.guiTextField.textColor = HMColor.sh.recorderEditTextError;
        cell.guiRetryButton.hidden = NO;
        cell.guiTextIsGoodIcon.hidden = YES;
        return;
    }

    cell.guiRetryButton.hidden = YES;
    cell.guiTextField.textColor = HMColor.sh.recorderEditText;
}

-(void)onRender:(NSNotification *)notification
{
    [self.guiCreateMovieActivity stopAnimating];
    self.guiCreateButton.enabled = YES;
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.textsDefinitions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"editing text cell";
    HMRecorderEditingTextCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(HMRecorderEditingTextCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Text *textDefinition = self.textsDefinitions[indexPath.row];
    NSString *textValue = [self.remake textWithID:textDefinition.sID];
    cell.guiTextField.delegate = self;
    cell.guiTextField.text = textValue;
    cell.guiTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textDefinition.descriptionText.uppercaseString
                                                                              attributes:@{NSForegroundColorAttributeName:HMColor.sh.main1}];
    
    [self validateTextAtIndexPath:indexPath];
    cell.guiActivity.tag = indexPath.row;
    cell.guiTextField.tag = indexPath.row;
    cell.guiRetryButton.tag = indexPath.row;
}

-(void)validateTextAtIndexPath:(NSIndexPath *)indexPath
{
    HMRecorderEditingTextCell *cell = (HMRecorderEditingTextCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSString *text = [self.remake textWithID:@(indexPath.row+1)];
    if (text && text.length > 0) {
        cell.guiTextField.text = text;
        cell.guiTextIsGoodIcon.hidden = NO;
        cell.guiRetryButton.hidden = YES;
    } else {
        cell.guiTextField.text = @"";
        cell.guiTextIsGoodIcon.hidden = YES;
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    Text *textDefinition = self.textsDefinitions[textField.tag];
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > textDefinition.maxCharacters.integerValue) ? NO : YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger index = textField.tag;
    HMRecorderEditingTextCell *cell = (HMRecorderEditingTextCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    if (index < self.textsDefinitions.count - 1) {
        HMRecorderEditingTextCell *nextCell = (HMRecorderEditingTextCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index+1 inSection:0]];
        [nextCell.guiTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    // Update server with text, if it was changed.
    NSString *newText = [textField.text stringWithATrim];
    NSString *oldText = [[self.remake textWithID:@(index+1)] stringWithATrim];
    if (![newText isEqualToString:oldText]) {
        [self updateServerWithTextAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        [cell.guiActivity startAnimating];
    }
    return YES;
}

-(void)showMissingTextsMessage
{
    
    [UIView animateWithDuration:0.2 animations:^{
        self.guiCreateButton.alpha = 0;
        self.guiNoticeMessageLabel.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.guiCreateButton.alpha = 1;
            self.guiNoticeMessageLabel.alpha = 0;
        } completion:nil];
    }];
    
    

}

#pragma mark - Remote
-(void)updateServerWithTextAtIndexPath:(NSIndexPath *)indexPath
{
    HMRecorderEditingTextCell *cell = (HMRecorderEditingTextCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    NSString *text = [cell.guiTextField.text stringWithATrim];
    cell.guiTextField.text = text;
    [HMServer.sh updateText:text forRemakeID:self.remake.sID textID:@(indexPath.row+1)];
}

-(void)serverCreateMovie
{
    if (self.remake.missingSomeTexts) {
        [self showMissingTextsMessage];
        return;
    }
    [self.guiCreateMovieActivity startAnimating];
    [HMServer.sh renderRemakeWithID:self.remake.sID];
}

-(void)updateValues
{
    [self.tableView reloadData];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)guiRetryButton:(UIButton *)sender
{
    [self updateServerWithTextAtIndexPath:[NSIndexPath indexPathForRow:sender.tag inSection:0]];
}

- (IBAction)onPressedCreateMovieButton:(UIButton *)sender
{
    // Check if more texts needed.
    [self serverCreateMovie];
}

- (IBAction)onPressedCancel:(id)sender
{
    [self.remakerDelegate updateWithUpdateType:HMRemakerUpdateTypeCancelEditingTexts info:nil];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
