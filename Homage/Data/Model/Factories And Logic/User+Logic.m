//
//  User+Logic.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "User+Logic.h"
#import "DB.h"

@implementation User (Logic)

#pragma mark - Same or another user
-(BOOL)isThisUser:(User *)otherUser
{
    return [self.userID isEqualToString:otherUser.userID];
}

-(BOOL)isNotThisUser:(User *)otherUser
{
    return ![self isThisUser:otherUser];
}

#pragma mark is guest user
-(BOOL)isGuestUser
{
    if (self.email) return NO;
    return YES;
}

#pragma mark - Login / Logout user
// Marks all users in local storage as logged out.
+(void)logoutAllInContext:(NSManagedObjectContext *)context
{
    // Mark all users as logged out.
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HM_USER];
    request.sortDescriptors = @[];
    NSError *error;
    NSArray *users = [context executeFetchRequest:request error:&error];
    if (error) {
        HMGLogError(@"Critical error in User logoutAllInContext. %@", error);
        return;
    }
    for (User *user in users) {
        user.isLoggedIn = @NO;
    }
}

// Returns the user marked as logged in from local storage.
+(User *)loggedInUserInContext:(NSManagedObjectContext *)context
{
    // Return logged in user if exists.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isLoggedIn=%@", @YES];
    User *user = (User *)[DB.sh fetchSingleEntityNamed:HM_USER withPredicate:predicate inContext:context];
    return user;
}

// Helper/shortcut method that returns loggedInUserInContext
+(User *)current
{
    return [User loggedInUserInContext:DB.sh.context];
}

// Mark user as logged in. (Mark all others as logged out).
-(void)loginInContext:(NSManagedObjectContext *)context
{
    [User logoutAllInContext:context];
    self.isLoggedIn = @YES;
}

// Mark user as logged out.
-(void)logoutInContext:(NSManagedObjectContext *)context
{
    self.isLoggedIn = @NO;
}

-(Remake *)findRemakeByID:(NSString *)remakeID inContext:(NSManagedObjectContext *)context
{
    Remake *remake = [Remake findWithID:remakeID inContext:context];
    if ([remake.user.userID isEqualToString:self.userID]) return remake;
    return nil;
}

-(Remake *)userPreviousRemakeForStory:(NSString *)storyID
{
    for (Remake *remake in self.remakes)
    {
        if (remake.story.sID == storyID && (remake.status.integerValue == HMGRemakeStatusInProgress || remake.status.integerValue == HMGRemakeStatusTimeout))
        {
            return remake;
        }
    }
    return nil;
}

@end
