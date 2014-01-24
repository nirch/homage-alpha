//
//  User+Logic.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "User.h"

@interface User (Logic)

#pragma mark - Same or another user
-(BOOL)isThisUser:(User *)otherUser;
-(BOOL)isNotThisUser:(User *)otherUser;

#pragma mark - Login / Logout user
// Marks all users in local storage as logged out.
+(void)logoutAllInContext:(NSManagedObjectContext *)context;

// Returns the user marked as logged in from local storage.
+(User *)loggedInUserInContext:(NSManagedObjectContext *)context;

// Helper/shortcut method that returns loggedInUserInContext
+(User *)current;

// Mark user as logged in. (Mark all others as logged out).
-(void)loginInContext:(NSManagedObjectContext *)context;

// Mark user as logged out.
-(void)logoutInContext:(NSManagedObjectContext *)context;


@end
