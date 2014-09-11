//
//  HMServer+analytics.m
//  Homage
//
//  Created by Yoav Caspin on 7/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+analytics.h"
#import "HMNotificationCenter.h"
#import "BSONIdGenerator.h"
#import "Mixpanel.h"

@implementation HMServer (analytics)

#define ATTEMPTS_COUNT 3

-(NSString *)generateBSONID
{
    return [BSONIdGenerator generate];
}

-(void)reportRemakeShare:(NSString *)remakeID forUserID:(NSString *)userID shareMethod:(NSNumber *)shareMethod
{
    [self postRelativeURLNamed:@"share remake"
                    parameters:@{@"user_id":userID, @"remake_id":remakeID , @"share_method":shareMethod}
              notificationName:HM_NOTIFICATION_SERVER_SHARE_REMAKE
                          info:@{@"userID":userID,@"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]}
                        parser:nil
     ];
}

-(void)reportVideoStartWithViewID:(NSString *)viewID forEntity:(NSNumber *)entityType withID:(NSString *)entityID forUserID:(NSString *)userID fromOriginatingScreen:(NSNumber *)originatingScreen
{
    if (entityType.intValue == HMStory)
    {
        [self postRelativeURLNamed:@"view story"
                        parameters:@{@"view_id":viewID, @"story_id":entityID, @"user_id":userID ,@"playback_event":[NSNumber numberWithInt:HMPlaybackEventStart], @"originating_screen":originatingScreen}
                  notificationName:HM_NOTIFICATION_SERVER_STORY_VIEW
                              info:@{@"story_id":entityID, @"userID":userID , @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]}
                            parser:nil
         ];
    } else if (entityType.intValue == HMRemake)
    {
        [self postRelativeURLNamed:@"view remake"
                        parameters:@{@"view_id":viewID, @"remake_id":entityID, @"user_id":userID, @"playback_event":[NSNumber numberWithInt:HMPlaybackEventStart], @"originating_screen":originatingScreen}
                  notificationName:HM_NOTIFICATION_SERVER_REMAKE_VIEW
                              info:@{@"remake_id":entityID, @"userID":userID , @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]}
                            parser:nil
         ];
    }
}

-(void)reportVideoStopWithViewID:(NSString *)viewID forEntity:(NSNumber *)entityType withID:(NSString *)entityID forUserID:(NSString *)userID forDuration:(NSNumber *)playbackTime outOfTotalDuration:(NSNumber *)videoDuration fromOriginatingScreen:(NSNumber *)originatingScreen
{
    if (entityType.intValue == HMStory)
    {
        [self postRelativeURLNamed:@"view story"
                        parameters:@{@"view_id":viewID, @"story_id":entityID, @"user_id":userID ,@"playback_duration":playbackTime, @"total_duration":videoDuration, @"playback_event":[NSNumber numberWithInt:HMPlaybackEventStop], @"originating_screen":originatingScreen}
                  notificationName:HM_NOTIFICATION_SERVER_STORY_VIEW
                              info:@{@"story_id":entityID, @"userID":userID , @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]}
                            parser:nil
         ];
    } else if (entityType.intValue == HMRemake)
    {
        [self postRelativeURLNamed:@"view remake"
                        parameters:@{@"view_id":viewID, @"remake_id":entityID, @"user_id":userID ,@"playback_duration":playbackTime, @"total_duration":videoDuration,@"playback_event":[NSNumber numberWithInt:HMPlaybackEventStop],@"originating_screen":originatingScreen}
                  notificationName:HM_NOTIFICATION_SERVER_REMAKE_VIEW
                              info:@{@"remake_id":entityID, @"userID":userID , @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]}
                            parser:nil
         ];        
    }
}

-(void)reportSession:(NSString *)sessionID beginForUser:(NSString *)userID
{
    [self postRelativeURLNamed:@"user session start" parameters:@{@"session_id":sessionID, @"user_id":userID} notificationName:HM_NOTIFICATION_SERVER_USER_BEGIN_SESSION info:@{@"userID":userID, @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]} parser:nil];
    [[Mixpanel sharedInstance] track:@"user session start" properties:@{@"session_id":sessionID, @"user_id":userID}];
}

-(void)reportSession:(NSString *)sessionID endForUser:(NSString *)userID
{
    [self postRelativeURLNamed:@"user session end" parameters:@{@"session_id":sessionID, @"user_id":userID} notificationName:HM_NOTIFICATION_SERVER_USER_END_SESSION info:@{@"userID":userID, @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]} parser:nil];
    [[Mixpanel sharedInstance] track:@"user session end" properties:@{@"session_id":sessionID, @"user_id":userID}];
    
}

-(void)reportSession:(NSString *)sessionID updateForUser:(NSString *)userID
{
    [self postRelativeURLNamed:@"user session update" parameters:@{@"session_id":sessionID, @"user_id":userID} notificationName:HM_NOTIFICATION_SERVER_USER_UPDATE_SESSION info:@{@"userID":userID, @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]} parser:nil];
    [[Mixpanel sharedInstance] track:@"user session update" properties:@{@"session_id":sessionID, @"user_id":userID}];
    
}

@end
