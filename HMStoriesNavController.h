//
//  HMStoriesNavController.h
//  Homage
//
//  Created by Yoav Caspin on 2/9/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMStoriesNavControllerDelegate.h"

@interface HMStoriesNavController : UINavigationController

@property id<HMStoriesNavControllerDelegate> storyNavDelegate;

@end
