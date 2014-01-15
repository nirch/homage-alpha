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

@implementation HMServer (Remakes)

// Creates a new remake for the given story and user.
-(void)remakeStoryWithID:(NSString *)storyID forUserID:(NSNumber *)userID
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/remake
    // Creates a new remake for the given story and user.
    // Returns (JSON) ...
    [self postRelativeURLNamed:@"remake"
                    parameters:@{@"story_id":storyID, @"user_id":userID.stringValue}
             notificationName:HM_NOTIFICATION_SERVER_FETCHED_STORIES
                       parser:[[HMRemakeParser alloc] init]
     ];
}

// Refetch all remakes for the provided user id.
-(void)refetchRemakesForUserID:(NSNumber *)userID
{
    // TODO: finish implementation
    
//    // A simple get request to the server
//    // Example URL: http://54.204.34.168:4567/remakes/
//    // Returns (JSON) list and info of the available stories.
//    [self getRelativeURLNamed:@"stories"
//             notificationName:HM_NOTIFICATION_SERVER_FETCHED_STORIES
//                       parser:[[HMStoriesParser alloc] init]
//     ];
}


@end
