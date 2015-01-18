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
@class Remake;

#define K_STORE_PURCHASES_COUNT @"store purchases count"
#define K_STORE_OPENED_FOR @"store opened for"

typedef NS_ENUM(NSInteger, HMStoreOpenedFor) {
    HMStoreOpenedForStoryDetailsRemakeButton,
    HMStoreOpenedForSideBarStoreButton,
    HMStoreOpenedForSaveRemakeToCameraRoll
};

@interface HMInAppStoreViewController : UIViewController<
    HMStoreManagerDelegate
>

@property (nonatomic, weak) id<HMStoreDelegate>delegate;
@property (nonatomic) HMStoreOpenedFor openedFor;
@property (nonatomic) Remake *remake;

+(HMInAppStoreViewController *)storeVC;
+(HMInAppStoreViewController *)storeVCForStory:(Story *)story;
+(HMInAppStoreViewController *)storeVCForRemake:(Remake *)remake;

@end
