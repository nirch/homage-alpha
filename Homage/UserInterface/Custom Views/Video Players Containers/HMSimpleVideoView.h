//
//  HMSimpleVideoView.h
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HMSimpleVideoView : UIView

@property (weak, nonatomic) IBOutlet UIView *guiVideoContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiVideoThumb;
@property (weak, nonatomic) IBOutlet UIView *guiVideoThumbOverlay;
@property (weak, nonatomic) IBOutlet UILabel *guiVideoLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiLoadActivity;
@property (weak, nonatomic) IBOutlet UIButton *guiPlayButton;
@property (weak, nonatomic) IBOutlet UIView *guiControlsContainer;

@property (weak, nonatomic) IBOutlet UIButton *guiStopButton;
@property (weak, nonatomic) IBOutlet UIButton *guiPlayPauseButton;
@property (weak, nonatomic) IBOutlet UIButton *guiFullScreenButton;
@property (weak, nonatomic) IBOutlet UISlider *guiVideoSlider;

@end
