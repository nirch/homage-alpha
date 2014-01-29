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
    NSString *userID = info[@"_id"];
    User *user = [User userWithID:userID inContext:self.ctx];

    // Currently the user id and the email are the same
    user.email = userID;
    user.isPublic = [info boolNumberForKey:@"is_public"];
}


@end
