//
//  HMSceneCell.m
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSceneCell.h"

@implementation HMSceneCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setReadyState:(HMFootageReadyState)readyState
{
    if (readyState == HMFootageReadyStateReadyForFirstRetake) {
        // Ready for first retake
        self.guiSceneLabel.highlighted = YES;
        self.guiSceneLabel.enabled = YES;
        self.guiSceneLockedIcon.hidden = YES;
        self.guiSceneTimeLabel.hidden = NO;
        self.guiSceneRetakeIcon.hidden = YES;
    } else if (readyState == HMFootageReadyStateReadyForSecondRetake) {
        // Ready for second retake.
        self.guiSceneLabel.highlighted = NO;
        self.guiSceneLabel.enabled = YES;
        self.guiSceneLockedIcon.hidden = YES;
        self.guiSceneTimeLabel.hidden = YES;
        self.guiSceneRetakeIcon.hidden = NO;
    } else {
        // Locked
        self.guiSceneLabel.highlighted = NO;
        self.guiSceneLabel.enabled = NO;
        self.guiSceneLockedIcon.hidden = NO;
        self.guiSceneTimeLabel.hidden = YES;
        self.guiSceneRetakeIcon.hidden = YES;
    }
    
}

@end
