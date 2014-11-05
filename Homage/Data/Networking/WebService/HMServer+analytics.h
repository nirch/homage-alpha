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
-(void)reportShare:(NSString *)shareID forRemake:(NSString *)remakeID forUserID:(NSString *)userID shareMethod:(NSNumber *)shareMethod shareLink:(NSString *)shareLink shareSuccess:(BOOL)shareSuccess fromOriginatingScreen:(NSNumber *)originatingScreen;
-(void)reportVideoStartWithViewID:(NSString *)viewID forEntity:(NSNumber *)entityType withID:(NSString *)entityID forUserID:(NSString *)userID fromOriginatingScreen:(NSNumber *)originatingScreen;
-(void)reportVideoStopWithViewID:(NSString *)viewID forEntity:(NSNumber *)entityType withID:(NSString *)entityID forUserID:(NSString *)userID forDuration:(NSNumber *)playbackTime outOfTotalDuration:(NSNumber *)videoDuration fromOriginatingScreen:(NSNumber *)originatingScreen;
-(void)reportSession:(NSString *)sessionID beginForUser:(NSString *)userID;
-(void)reportSession:(NSString *)sessionID endForUser:(NSString *)userID;
-(void)reportSession:(NSString *)sessionID updateForUser:(NSString *)userID;

@end
