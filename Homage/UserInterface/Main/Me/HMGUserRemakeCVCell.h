//
//  HMGUserRemakeCVCell.h
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMGUserRemakeCVCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet UIView *moviePlaceHolder;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *remakeButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *closeMovieButton;

@end
