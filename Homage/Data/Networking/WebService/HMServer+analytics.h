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

-(NSString *)generateBSONID;
-(void)reportRemakeShare:(NSString *)remakeID forUserID:(NSString *)userID shareMethod:(NSNumber *)shareMethod;
-(void)reportVideoStartWithViewID:(NSString *)viewID forEntity:(NSInteger)entityType withID:(NSString *)entityID forUserID:(NSString *)userID;
-(void)reportVideoStopWithViewID:(NSString *)viewID forEntity:(NSInteger)entityType withID:(NSString *)entityID forUserID:(NSString *)userID forDuration:(NSNumber *)playbackTime outOfTotalDuration:(NSNumber *)videoDuration;
-(void)reportSession:(NSString *)sessionID beginForUser:(NSString *)userID;
-(void)reportSession:(NSString *)sessionID endForUser:(NSString *)userID;

@end
