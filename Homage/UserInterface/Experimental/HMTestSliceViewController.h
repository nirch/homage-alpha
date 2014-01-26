//
//  HMTestSliceViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class AWPieSliceView;

@interface HMTestSliceViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;
@property (weak, nonatomic) IBOutlet AWPieSliceView *guiSlice;
@property (weak, nonatomic) IBOutlet UISlider *guiSlider;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiStartActivity;
@property (weak, nonatomic) IBOutlet UIButton *guiStartButton;

@end
