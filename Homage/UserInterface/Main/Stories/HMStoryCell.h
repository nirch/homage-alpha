//
//  HMStoryCell.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMFontLabel.h"

@interface HMStoryCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet  HMFontLabel *guiStoryNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;


@end
