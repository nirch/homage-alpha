//
//  User+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "User.h"

#define HM_USER         @"User"

@interface User (Factory)

///
/**
*  Creates or fetch a user with given user id.
*
*  @param userID  A string representing a unique user.
*  @param context The managed object context.
*
*  @return A new or an existing user managed object.
*/
+(User *)userWithID:(NSString *)userID inContext:(NSManagedObjectContext *)context;


@end
