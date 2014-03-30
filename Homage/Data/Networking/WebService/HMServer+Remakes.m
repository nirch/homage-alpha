//
//  HMServer+Remakes.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Remakes.h"
#import "HMNotificationCenter.h"
#import "HMRemakeParser.h"
#import "HMRemakesParser.h"

@implementation HMServer (Remakes)

-(void)createRemakeForStoryWithID:(NSString *)storyID forUserID:(NSString *)userID
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/remake
    // Creates a new remake for the given story and user.
    // Returns (JSON) with the info about the new remake.
    [self postRelativeURLNamed:@"new remake"
                    parameters:@{@"story_id":storyID, @"user_id":userID}
             notificationName:HM_NOTIFICATION_SERVER_REMAKE_CREATION
                          info:@{@"userID":userID}
                       parser:[HMRemakeParser new]
     ];
}

-(void)refetchRemakeWithID:(NSString *)remakeID
{
    // A simple GET request to the server
    // Example URL: http://54.204.34.168:4567/remake/52d7a02edb25451630000002
    // Fetches info of a remake with the given id.
    // Returns (JSON) with the info about the given remake.
    NSString *relativeURL = [self relativeURLNamed:@"existing remake" withSuffix:remakeID];
    [self getRelativeURL:relativeURL
              parameters:nil
        notificationName:HM_NOTIFICATION_SERVER_REMAKE
                    info:@{@"remakeID":remakeID}
                  parser:[HMRemakeParser new]
     ];
}

-(void)refetchRemakesWithStoryID:(NSString *)storyID
{
    // A simple GET request to the server
    // Example URL: http://54.204.34.168:4567/remake/52d7a02edb25451630000002
    // Fetches info of a remake with the given id.
    // Returns (JSON) with the info about the given remake.
    NSString *relativeURL = [self relativeURLNamed:@"story's remakes" withSuffix:storyID];
    [self getRelativeURL:relativeURL
              parameters:nil
        notificationName:HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY
                    info:@{@"storyID":storyID}
                  parser:[HMRemakesParser new]
     ];
}

    
-(void)refetchRemakesForUserID:(NSString *)userID
{
    // A simple get request to the server
    // Example URL: http://54.204.34.168:4567/remakes/user/<user id>
    // Returns (JSON) list and info of the remakes for user.
    NSString *relativeURL = [self relativeURLNamed:@"user's remakes" withSuffix:userID];
    
    HMRemakesParser *remakesParser = [HMRemakesParser new];
    remakesParser.shouldRemoveOlderRemakes = YES;
    
    [self getRelativeURL:relativeURL
              parameters:nil
             notificationName:HM_NOTIFICATION_SERVER_USER_REMAKES
                    info:@{@"userID":userID}
                       parser:[HMRemakesParser new]
     ];
}

-(void)deleteRemakeWithID:(NSString *)remakeID
{
    // A simple DELETE request to the server
    // Example URL: http://54.204.34.168:4567/remake/52d7a02edb25451630000002
    // Deletes a remake with the given id.
    // Returns (JSON) with the info about the deletion.
    NSString *relativeURL = [self relativeURLNamed:@"delete remake" withSuffix:remakeID];
    [self deleteRelativeURL:relativeURL
                 parameters:nil
           notificationName:HM_NOTIFICATION_SERVER_REMAKE_DELETION
                       info:@{@"remakeID":remakeID}
                     parser:nil
     ];
}


-(void)markRemakeAsInappropriate:(NSDictionary *)userParams
{
    [self postRelativeURLNamed:@"report inappropriate"
                    parameters:userParams
              notificationName:HM_NOTIFICATION_MARKED_AS_INAPPROPRIATE
                          info:nil 
                        parser:nil
     ];
}

@end
