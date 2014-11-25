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

-(void)requestShare:(NSString *)shareID
          forRemake:(NSString *)remakeID
             userID:(NSString *)userID
          shareLink:(NSString *)shareLink
    originatingScreen:(NSNumber *)originatingScreen
               info:(NSDictionary *)info {

    // Parameters of the request
    NSDictionary *params = @{
                             @"share_id":shareID,
                             @"user_id":userID,
                             @"remake_id":remakeID ,
                             @"share_link":shareLink,
                             @"share_status":@(NO),
                             @"originating_screen":originatingScreen
                             };
    
    // Post request to the server.
    [self postRelativeURLNamed:@"share remake"
                   parameters:params
             notificationName:HM_NOTIFICATION_SERVER_SHARE_REMAKE_REQUEST
                         info:@{
                                @"userID":userID,
                                @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT],
                                @"share_bundle":info
                                }
                       parser:nil];
}

-(void)reportShare:(NSString *)shareID
            userID:(NSString *)userID
         forRemake:(NSString *)remakeID
       shareMethod:(NSNumber *)shareMethod
      shareSuccess:(BOOL)shareSuccess
              info:(NSDictionary *)info {
    NSNumber *success = [NSNumber numberWithBool:shareSuccess];
    // Parameters of the request
    NSDictionary *params = @{
                             @"share_id":shareID,
                             @"share_method":shareMethod,
                             @"share_status":success,
                             @"user_id":userID
                             };
    
    [self putRelativeURLNamed:@"share remake"
                    parameters:params
              notificationName:HM_NOTIFICATION_SERVER_SHARE_REMAKE
                          info:@{
                                 @"userID":userID,
                                 @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT],
                                 @"share_bundle":info
                                 }
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

-(void)reportVideoStopWithViewID:(NSString *)viewID
                       forEntity:(NSNumber *)entityType
                          withID:(NSString *)entityID
                       forUserID:(NSString *)userID
                     forDuration:(NSNumber *)playbackTime
              outOfTotalDuration:(NSNumber *)videoDuration
           fromOriginatingScreen:(NSNumber *)originatingScreen {
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
    if (userID == nil || sessionID == nil) return;
    [self postRelativeURLNamed:@"user session start" parameters:@{@"session_id":sessionID, @"user_id":userID} notificationName:HM_NOTIFICATION_SERVER_USER_BEGIN_SESSION info:@{@"userID":userID, @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]} parser:nil];
    [[Mixpanel sharedInstance] track:@"user session start" properties:@{@"session_id":sessionID, @"user_id":userID}];
}

-(void)reportSession:(NSString *)sessionID endForUser:(NSString *)userID
{
    if (userID == nil || sessionID == nil) return;
    [self postRelativeURLNamed:@"user session end" parameters:@{@"session_id":sessionID, @"user_id":userID} notificationName:HM_NOTIFICATION_SERVER_USER_END_SESSION info:@{@"userID":userID, @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]} parser:nil];
    [[Mixpanel sharedInstance] track:@"user session end" properties:@{@"session_id":sessionID, @"user_id":userID}];
    
}

-(void)reportSession:(NSString *)sessionID updateForUser:(NSString *)userID
{
    if (userID == nil || sessionID == nil) return;
    [self postRelativeURLNamed:@"user session update" parameters:@{@"session_id":sessionID, @"user_id":userID} notificationName:HM_NOTIFICATION_SERVER_USER_UPDATE_SESSION info:@{@"userID":userID, @"attempts_count":[NSNumber numberWithInt:ATTEMPTS_COUNT]} parser:nil];
    [[Mixpanel sharedInstance] track:@"user session update" properties:@{@"session_id":sessionID, @"user_id":userID}];
}

@end
