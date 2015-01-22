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

-(void)createUserWithDictionary:(NSDictionary *)userParams
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/user
    // Creates a new user for the given story and user.
    // Returns (JSON) with the info about the new remake.
    [self postRelativeURLNamed:@"new user"
                    parameters:userParams
              notificationName:HM_NOTIFICATION_SERVER_USER_CREATION
                          info:@{}
                        parser:[HMUserParser new]
     ];
}

-(void)updateUserUponJoin:(NSDictionary *)userParams
{
    [self putRelativeURLNamed:@"update user"
                    parameters:userParams
              notificationName:HM_NOTIFICATION_SERVER_USER_UPDATED
                         info:@{}
                        parser:[HMUserParser new]
     ];
}

-(void)updateUserPreferences:(NSDictionary *)userParams
{
    [self putRelativeURLNamed:@"update user"
                   parameters:userParams
             notificationName:HM_NOTIFICATION_SERVER_USER_PREFERENCES_UPDATE
                         info:@{}
                       parser:[HMUserParser new]
     ];
}

-(void)updatePushToken:(NSData *)pushToken forUser:(User *)user
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/user/push_token
    // Updates a user's push token related to an already existing device identifier.
    // Does nothing on the server side if device identifier not found for that user.
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceIdentifier = [device.identifierForVendor UUIDString];
    NSString *userID = user.userID;
    if (device == nil || deviceIdentifier == nil || userID == nil) {
        // We must have all these parameters to perform this operation.
        // but we don't. skip request.
        return;
    }
    
    // Send the update request to the server.
    NSDictionary *parameters = @{@"user_id":userID,
                                 @"device_id":deviceIdentifier,
                                 @"ios_push_token":pushToken};
    
    [self putRelativeURLNamed:@"update push token"
               parameters:parameters
         notificationName:HM_NOTIFICATION_SERVER_PUSH_TOKEN
                     info:nil
                   parser:nil];

}

@end
