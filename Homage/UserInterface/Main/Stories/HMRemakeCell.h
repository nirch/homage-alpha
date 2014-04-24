//
//  HMRemakeCell.h
//  Homage
//
//  Created by Yoav Caspin on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMAvenirBookFontLabel.h"

@interface HMRemakeCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiUserName;
@property (weak, nonatomic) IBOutlet UIButton *guiMoreButton;

@end
