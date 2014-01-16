//
//  HMServer+Remakes.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Remakes)

// Creates a new remake for the given story and user.
-(void)remakeStoryWithID:(NSString *)storyID forUserID:(NSString *)userID;

// Refetch all remakes for the provided user id.
-(void)refetchRemakesForUserID:(NSString *)userID;

@end
