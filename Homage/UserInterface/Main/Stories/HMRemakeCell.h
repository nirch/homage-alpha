//
//  HMRemakeCell.h
//  Homage
//
//  Created by Yoav Caspin on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMFontLabel.h"

@interface HMRemakeCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiUserName;
@property (weak, nonatomic) IBOutlet UIView *videoPlayerContainer;

@end
