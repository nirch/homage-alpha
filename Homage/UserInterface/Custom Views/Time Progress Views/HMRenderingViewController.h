//
//  HMRenderingViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWTimeProgressView.h"
#import "AWTimeProgressDelegate.h"
#import "HMFontLabel.h"

@interface HMRenderingViewController : UIViewController <AWTimeProgressDelegate>

@property (weak, nonatomic) IBOutlet UIView *guiInProgressView;

@property (weak, nonatomic) IBOutlet AWTimeProgressView *guiProgressBarView;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiInProgressLabel;
@property (weak, nonatomic) IBOutlet UIView *guiDoneRenderingView;
@property (weak, nonatomic) IBOutlet UIView *guiProgressBar;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiDoneLabel;

@end
