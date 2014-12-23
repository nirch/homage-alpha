//
//  HMInAppStoreViewController.h
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoreDelegate.h"

@class Story;

@interface HMInAppStoreViewController : UIViewController

@property (nonatomic, weak) id<HMStoreDelegate>delegate;

+(HMInAppStoreViewController *)storeVCForStory:(Story *)story;

@end
