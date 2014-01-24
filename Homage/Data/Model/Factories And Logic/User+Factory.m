//
//  User+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "User+Factory.h"
#import "DB.h"

@implementation User (Factory)

// Fetches (or creates if missing), in local storage, a user with the provided ID.
+(User *)userWithID:(NSString *)userID inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID=%@",userID];
    User *user = [DB.sh fetchOrCreateEntityNamed:HM_USER withPredicate:predicate inContext:context];
    user.userID = userID;
    return user;
}


@end
