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

// Creates a new remake for the given story and user.
-(void)remakeStoryWithID:(NSString *)storyID forUserID:(NSString *)userID
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/remake
    // Creates a new remake for the given story and user.
    // Returns (JSON) ...
    [self postRelativeURLNamed:@"remake"
                    parameters:@{@"story_id":storyID, @"user_id":userID}
             notificationName:HM_NOTIFICATION_SERVER_FETCHED_STORIES
                       parser:[[HMRemakeParser alloc] init]
     ];
}

// Refetch all remakes for the provided user id.
-(void)refetchRemakesForUserID:(NSString *)userID
{
    // A simple get request to the server
    // Example URL: http://54.204.34.168:4567/remakes/user/<user id>
    // Returns (JSON) list and info of the remakes for user.
    
    NSString *relativeURL = [self relativeURLNamed:@"remakes/user" withSuffix:userID];
    [self getRelativeURL:relativeURL
              parameters:nil
             notificationName:HM_NOTIFICATION_SERVER_FETCHED_USER_REMAKES
                       parser:[[HMRemakesParser alloc] init]
     ];
}


@end
