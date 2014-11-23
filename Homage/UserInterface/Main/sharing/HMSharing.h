//
//  HMSharing.h
//  Homage
//
//  Created by Aviv Wolf on 10/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Remake;

#define K_SHARE_ID            @"SHARE_ID"
#define K_USER_ID             @"USER_ID"
#define K_REMAKE_ID           @"REMAKE_ID"
#define K_REMAKE_OWNER_ID     @"REMAKE_OWNER_ID"
#define K_STORY_NAME          @"STORY_NAME"
#define K_SHARE_URL           @"SHARE_URL"
#define K_SHARE_METHOD        @"SHARE_METHOD"
#define K_SHARE_SUBJECT       @"SHARE_SUBJECT"
#define K_SHARE_BODY          @"SHARE_BODY"
#define K_WHATS_APP_MESSAGE   @"WHATS_APP_MESSAGE"
#define K_THUMBNAIL           @"THUMBNAIL"
#define K_ORIGINATING_SCREEN  @"ORIGINATING_SCREEN"
#define K_TRACK_EVENT_NAME    @"TRACK_EVENT_NAME"

@interface HMSharing : NSObject

/**
 *  Generate info bundle for sharing a remake.
 *
 *  @param remake            The remake to share.
 *  @param trackEventName    The name of the analytics tracking event.
 *  @param originatingScreen The originating screen the user initiated the share from.
 *
 *  @return A dictionary with all the generate info about the share.
 */
-(NSDictionary *)generateShareBundleForRemake:(Remake *)remake
                               trackEventName:(NSString *)trackEventName
                            originatingScreen:(NSNumber *)originatingScreen;

/**
 *  Report to the server about a share.
 *
 *  @param shareBundle A dictionary containing info about the share.
 */
-(void)requestShareWithBundle:(NSDictionary *)shareBundle;

/**
 *  Share remake UI for share remake bundle.
 *
 *  @param shareBundle    Info about the share (link, remakeID etc).
 *  @param parentVC       The parent view controller for the opened view controller.
 *  @param trackEventName Analytics tracking event name.
 *  @param thumbnail      Thumbnail.
 */
-(void)shareRemakeBundle:(NSDictionary *)shareBundle
                parentVC:(UIViewController *)parentVC
          trackEventName:(NSString *)trackEventName
               thumbnail:(UIImage *)thumbnail;


@end
