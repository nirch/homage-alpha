//
//  HMUserParser.m
//  Homage
//
//  Created by Tomer Harry on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUserParser.h"

@implementation HMUserParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    [self parseUser:info];
    [DB.sh save];
}

-(void)parseUser:(NSDictionary *)info
{
    NSString *userID = info[@"_id"][@"$oid"];
    User *user = [User userWithID:userID inContext:self.ctx];

    // Currently the user id and the email are the same
    user.email = info[@"email"];
    user.isPublic = [info boolNumberForKey:@"is_public"];
    user.userID = userID;
    user.firstName = info[@"facebook"][@"first_name"];
    user.fbID = info[@"facebook"][@"id"];
    
    self.parseInfo[@"userID"] = userID;
}

@end
