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
@property (weak, nonatomic) IBOutlet UIImageView *guiRowIndicatorImage;
@property (weak, nonatomic) IBOutlet UIButton *guiSelectRowButton;
@property (weak, nonatomic) IBOutlet UIButton *guiRetakeSceneButton;
@property (weak, nonatomic) IBOutlet UIProgressView *guiUploadProgressBar;

@property (nonatomic) HMFootageReadyState readyState;
@property (nonatomic) UIDynamicAnimator *animator;

@end
