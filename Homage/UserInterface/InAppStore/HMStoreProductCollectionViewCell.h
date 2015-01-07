//
//  HMStoreProductCollectionViewCell.h
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMStoreProductCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *guiImage;
@property (weak, nonatomic) IBOutlet UILabel *guiTitle;
@property (weak, nonatomic) IBOutlet UILabel *guiText;
@property (weak, nonatomic) IBOutlet UILabel *guiPrice;
@property (weak, nonatomic) IBOutlet UIButton *guiBuyButton;
@property (weak, nonatomic) IBOutlet UIView *guiSepLine;

@end
