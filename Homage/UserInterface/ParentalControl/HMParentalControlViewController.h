//
//  HMParentalControlViewController.h
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HMParentalControlDelegate.h"

@interface HMParentalControlViewController : UIViewController

@property (nonatomic) id<HMParentalControlDelegate>delegate;

@end
