//
//  HMRecorderMessagesOverlayViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderMessagesOverlayViewController.h"

@interface HMRecorderMessagesOverlayViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiGeneralMessageContainer;

@property (weak, nonatomic) IBOutlet UIView *guiTextMessageContainer;
@property (weak, nonatomic) IBOutlet UILabel *guiTextMessageTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiTextMessageLabel;

@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;


@property (nonatomic, readonly) HMRecorderMessagesType messageType;

@end

@implementation HMRecorderMessagesOverlayViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - Selecting and showing messages
-(void)showMessageOfType:(HMRecorderMessagesType)messageType info:(NSDictionary *)info
{
    _messageType = messageType;
    self.guiGeneralMessageContainer.hidden = messageType != HMRecorderMessagesTypeGeneral;
    self.guiTextMessageContainer.hidden = messageType != HMRecorderMessagesTypeRemakeContext;
    
    if (self.messageType == HMRecorderMessagesTypeGeneral) {
        [self.guiDismissButton setTitle:@"OK, GOT IT" forState:UIControlStateNormal];
    } else if (self.messageType == HMRecorderMessagesTypeRemakeContext) {
        self.guiTextMessageTitleLabel.text = info[@"title"];
        self.guiTextMessageLabel.text = info[@"text"];
        [self.guiDismissButton setTitle:@"START!" forState:UIControlStateNormal];
    }
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissButton:(UIButton *)sender
{
    [self.remakerDelegate dismissMessagesOverlay];
}


@end
