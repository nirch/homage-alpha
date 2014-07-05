//
//  HMServer+Stories.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Stories.h"
#import "HMStoryParser.h"
#import "HMStoriesParser.h"
#import "HMNotificationCenter.h"

@implementation HMServer (Stories)

// Refetch list of available stories
-(void)refetchStories
{
    // A simple get request to the server
    // Example URL: http://54.204.34.168:4567/stories
    // Returns (JSON) list and info of the available stories.
    [self getRelativeURLNamed:@"stories"
                   parameters:nil
             notificationName:HM_NOTIFICATION_SERVER_STORIES
                         info:nil
                       parser:[HMStoriesParser new]
     ];
}

-(void)refetchStoryWithStoryID:(NSString *)storyID
{
    
    NSString *relativeURL = [self relativeURLNamed:@"story" withSuffix:storyID];
    [self getRelativeURL:relativeURL
              parameters:nil
        notificationName:HM_NOTIFICATION_SERVER_NEW_STORY_FETCHED
                    info:@{@"story_id":storyID}
                  parser:[HMStoryParser new]
     ];
    
}

@end
