//
//  HMInAppStoreViewController.h
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoreDelegate.h"
#import "HMStoreManagerDelegate.h"

@class Story;

@interface HMInAppStoreViewController : UIViewController<
    HMStoreManagerDelegate
>

@property (nonatomic, weak) id<HMStoreDelegate>delegate;

+(HMInAppStoreViewController *)storeVC;
+(HMInAppStoreViewController *)storeVCForStory:(Story *)story;

@end
