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

@interface HMRenderingViewController : UIViewController <AWTimeProgressDelegate>

@property (weak, nonatomic) IBOutlet UILabel *guiLabel;
@property (weak, nonatomic) IBOutlet AWTimeProgressView *guiProgressBar;


@end
