//
//  HMRemakeCell.h
//  Homage
//
//  Created by Yoav Caspin on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMRemakeCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;

// Social indicators
@property (weak, nonatomic) IBOutlet UIImageView *guiLikesIcon;
@property (weak, nonatomic) IBOutlet UITextView *guiLikesCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiViewsIcon;
@property (weak, nonatomic) IBOutlet UITextView *guiViewsCountLabel;
@property (weak, nonatomic) IBOutlet UIView *guiContainer;

@end
