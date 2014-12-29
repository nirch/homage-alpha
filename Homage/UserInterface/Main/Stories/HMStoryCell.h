//
//  HMStoryCell.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRegularFontLabel.h"

@interface HMStoryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiStoryNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet UIImageView *guiLevelOfDifficulty;

@property (weak, nonatomic) IBOutlet UIImageView *guiShotMode;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiNumOfRemakes;
@property (weak, nonatomic) IBOutlet UIView *guiStoryLockedContainer;

@end
