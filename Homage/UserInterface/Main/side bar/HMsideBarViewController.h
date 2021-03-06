//
//  HMSideBarViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMSideBarNavigatorDelegate.h"
#import "HMStoreDelegate.h"

@class User;

@interface HMSideBarViewController : UIViewController<
    HMStoreDelegate
>

typedef NS_ENUM(NSInteger, HMAppTab) {
    HMStoriesTab,
    HMMeTab,
    HMSettingsTab,
};

@property id<HMSideBarNavigatorDelegate> delegate;
-(void)updateSideBarGUIWithUser:(User *)user
                       userName:(NSString *)userName
                      FBProfile:(NSString *)fbProfileID;

@end
