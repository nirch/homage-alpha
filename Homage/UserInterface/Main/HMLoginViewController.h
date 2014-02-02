//
//  HMLoginViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMLoginDelegate.h"

@interface HMLoginViewController : UIViewController

@property (nonatomic) id<HMLoginDelegate> delegate;

@end
