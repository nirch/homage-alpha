//
//  HMGUserRemakeCVCell.h
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMGUserRemakeCVCell : UICollectionViewCell

@property (nonatomic) BOOL layoutInitialized;

// Thumb
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbImage;
@property (weak, nonatomic) IBOutlet UIView *buttonsView;
@property (weak, nonatomic) IBOutlet UILabel *storyNameLabel;

// Overlays
@property (weak, nonatomic) IBOutlet UIView *guiHighlightOverlay;
@property (weak, nonatomic) IBOutlet UIScrollView *guiScrollView;
@property (weak, nonatomic) IBOutlet UIView *guiThumbContainer;

// Actions on the remake.
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *remakeButton;
@property (weak, nonatomic) IBOutlet UIButton *guiDownloadButton;
@property (weak, nonatomic) IBOutlet UILabel *guiRetakeLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiDeleteLabel;



// Activity
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *shareActivity;
@property (weak, nonatomic) IBOutlet UIView *guiActivityOverlay;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

// Borders
@property (weak, nonatomic) IBOutlet UIView *guiSepTop;
@property (weak, nonatomic) IBOutlet UIView *guiSepBottom;


-(void)closeAnimated:(BOOL)animated;
-(void)disableInteractionForAShortWhile;

@end
