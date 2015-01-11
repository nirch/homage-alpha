//
//  HMServer+analytics.h
//  Homage
//
//  Created by Yoav Caspin on 7/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (analytics)

///
typedef NS_ENUM(NSInteger, HMViewEvent) {
    HMPlaybackEventStart,
    HMPlaybackEventStop,
};

//
typedef NS_ENUM(NSInteger, HMEntityType) {
    HMStory,
    HMRemake,
    HMIntroMovie,
    HMScene,
    HMPreview,
    HMHowtoVideo
};

typedef NS_ENUM(NSInteger, HMShareMethod) {
    HMShareMethodCopyToPasteboard,
    HMShareMethodPostToFacebook,
    HMShareMethodPostToWhatsApp,
    HMShareMethodEmail,
    HMShareMethodMessage,
    HMShareMethodPostToWeibo,
    HMShareMethodPostToTwitter,
};

typedef NS_ENUM(NSInteger, HMOrigScreen) {
    HMStoryDetails,
    HMMyStories,
    HMWelcomeScreen,
    HMHowTo,
    HMRecorderPreview,
    HMRecorderMenu,
};

-(NSString *)generateBSONID;
-(void)reportVideoStartWithViewID:(NSString *)viewID forEntity:(NSNumber *)entityType withID:(NSString *)entityID forUserID:(NSString *)userID fromOriginatingScreen:(NSNumber *)originatingScreen;
-(void)reportVideoStopWithViewID:(NSString *)viewID forEntity:(NSNumber *)entityType withID:(NSString *)entityID forUserID:(NSString *)userID forDuration:(NSNumber *)playbackTime outOfTotalDuration:(NSNumber *)videoDuration fromOriginatingScreen:(NSNumber *)originatingScreen;
-(void)reportSession:(NSString *)sessionID beginForUser:(NSString *)userID;
-(void)reportSession:(NSString *)sessionID endForUser:(NSString *)userID;
-(void)reportSession:(NSString *)sessionID updateForUser:(NSString *)userID;

/**
 *  Post report about a new share remake.
 *  This request will create the share object on the server side DB.
 *  If this request is not successful, the share link will not work on the server side.
 *
 *  @param shareID           The client side generated UUID of the share.
 *  @param remakeID          The id of the remake to share.
 *  @param userID            The id of the user sharing.
 *  @param shareLink         The share link url.
 *  @param originatingScreen The originating screen of the share.
 */
-(void)requestShare:(NSString *)shareID
          forRemake:(NSString *)remakeID
             userID:(NSString *)userID
          shareLink:(NSString *)shareLink
  originatingScreen:(NSNumber *)originatingScreen
               info:(NSDictionary *)info;

/**
 *  Update server with info about a share.
 *
 *  @param shareID           The client side generated UUID of the share.
 *  @param userID            The id of the user sharing.
 *  @param remakeID          The id of the remake to share.
 *  @param shareMethod       The share method number of this share.
 *  @param shareSuccess      Was the share successful or not.
 */
-(void)reportShare:(NSString *)shareID
            userID:(NSString *)userID
         forRemake:(NSString *)remakeID
       shareMethod:(NSNumber *)shareMethod
      shareSuccess:(BOOL)shareSuccess
              info:(NSDictionary *)info;

@end
