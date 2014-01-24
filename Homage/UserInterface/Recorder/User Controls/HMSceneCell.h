//
//  HMSceneCell.h
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage+Logic.h"

@interface HMSceneCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *guiSceneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiSceneLockedIcon;
@property (weak, nonatomic) IBOutlet UIImageView *guiSceneRetakeIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiSceneTimeLabel;

@property (nonatomic) HMFootageReadyState readyState;

@end
