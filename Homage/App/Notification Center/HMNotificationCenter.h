//
//  HMNotificationCenter.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSNotificationCenter+Utils.h"

// General application states.
#define HM_NOTIFICATION_APPLICATION_STARTED @"Application Started"

// Fetches from the network.
#define HM_NOTIFICATION_SERVER_FETCHED_STORIES              @"Fetched Stories"
#define HM_NOTIFICATION_SERVER_FETCHED_STORY_THUMBNAIL      @"Story Thumbnail Fetched"

#define HM_NOTIFICATION_SERVER_FETCHED_USER_REMAKES         @"Fetched User Remakes"
#define HM_NOTIFICATION_SERVER_DELETED_REMAKE               @"Deleted Remake"

@interface HMNotificationCenter : NSObject

@end
