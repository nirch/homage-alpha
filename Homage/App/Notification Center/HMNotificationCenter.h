//
//  HMNotificationCenter.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSNotificationCenter+Utils.h"
#import "NSNotification+Utils.h"

// General application states.
#define HM_NOTIFICATION_APPLICATION_STARTED @"Application Started"

// Fetches from the REST API.
#define HM_NOTIFICATION_SERVER_STORIES              @"Server Stories"

#define HM_NOTIFICATION_SERVER_REMAKE_CREATION      @"Server New Remake"
#define HM_NOTIFICATION_SERVER_REMAKE               @"Server Remake"
#define HM_NOTIFICATION_SERVER_USER_REMAKES         @"Server User Remakes"
#define HM_NOTIFICATION_SERVER_REMAKE_DELETION      @"Server Remake Deletion"
#define HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY    @"Server Remakes For Story"

#define HM_NOTIFICATION_SERVER_FOOTAGE              @"Server Footage"
#define HM_NOTIFICATION_SERVER_TEXT                 @"Server Text"
#define HM_NOTIFICATION_SERVER_RENDER               @"Server Render"

// Reachability
#define HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE @"Server Reachability Status Change"

// Uploads
#define HM_NOTIFICATION_UPLOAD_PROGRESS             @"Upload Progress"
#define HM_NOTIFICATION_UPLOAD_FINISHED             @"Upload Finished"

// Lazy loading notifications
#define HM_NOTIFICATION_SERVER_STORY_THUMBNAIL      @"Server Story Thumbnail"
#define HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL     @"Server Remake Thumbnail"
#define HM_NOTIFICATION_SERVER_SCENE_THUMBNAIL      @"Server Scene Thumbnil"
#define HM_NOTIFICATION_SERVER_SCENE_SILHOUETTE     @"Server Scene Silhouette"


@interface HMNotificationCenter : NSObject

@end
