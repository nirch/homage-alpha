//
//  HMSideBarViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMSideBarNavigatorDelegate.h"

@interface HMSideBarViewController : UIViewController

typedef NS_ENUM(NSInteger, HMAppTab) {
    HMStoriesTab,
    HMMeTab,
    HMSettingsTab,
};

@property id<HMSideBarNavigatorDelegate> delegate;
-(void)updateSideBarGUIWithName:(NSString *)userName FBProfile:(NSString *)fbProfileID;

@end
