//
//  HMsideBarViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMsideBarNavigatorDelegate.h"

@interface HMsideBarViewController : UIViewController
@property id<HMsideBarNavigatorDelegate> delegate;

@end
