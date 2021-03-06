//
//  HMServer+Users.h
//  Homage
//
//  Created by Tomer Harry on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@class User;

@interface HMServer (Users)

///
/**
 *  A POST request to the server requesting to create a new user.
 
 *  Notification name when done: HM_NOTIFICATION_SERVER_USER_CREATION.
 
 *  Parser used: HMUserParser.
 
 *  @code
 
 [HMServer.sh createUserWithID:@"nir@homage.it"];
 
 *  @endcode
 *  @param userID  The id of the user (e-mail)
 */
-(void)createUserWithDictionary:(NSDictionary *)userParams;
-(void)updateUserUponJoin:(NSDictionary *)userParams;
-(void)updateUserPreferences:(NSDictionary *)userParams;
-(void)updatePushToken:(NSData *)pushToken forUser:(User *)user;

@end
