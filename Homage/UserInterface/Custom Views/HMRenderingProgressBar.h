//
//  HMRenderingProgressBar.h
//  Homage
//
//  Created by Yoav Caspin on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMFontLabel.h"

@interface HMRenderingProgressBar : UIProgressView

@property (weak, nonatomic) IBOutlet UIView *renderingView;
@property (weak, nonatomic) IBOutlet UIView *doneView;
@property (strong, nonatomic) IBOutlet HMFontLabel *renderLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

-(void)start;

@end
