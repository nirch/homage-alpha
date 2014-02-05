//
//  HMServer+Users.m
//  Homage
//
//  Created by Tomer Harry on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Users.h"
#import "HMNotificationCenter.h"
#import "HMUserParser.h"

@implementation HMServer (Users)

-(void)createUserWithID:(NSString *)userID
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/user
    // Creates a new user for the given story and user.
    // Returns (JSON) with the info about the new remake.
    [self postRelativeURLNamed:@"new user"
                    parameters:@{@"user_id":userID}
              notificationName:HM_NOTIFICATION_SERVER_USER_CREATION
                          info:@{@"userID":userID}
                        parser:[HMUserParser new]
     ];
}

@end