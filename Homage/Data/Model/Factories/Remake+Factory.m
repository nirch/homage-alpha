//
//  Remake+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake+Factory.h"
#import "DB.h"

@implementation Remake (Factory)

// Fetches existing or creates a new remake (with id, story and user).
+(Remake *)remakeWithID:(NSString *)sID story:(Story *)story user:(User *)user inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@ AND story=%@",sID, story];
    Remake *remake = [DB.sh fetchOrCreateEntityNamed:HM_REMAKE withPredicate:predicate inContext:context];
    
    // Should never be owned by another user! This is a critical error!
    if (remake.user && [remake.user isNotThisUser:user]) {
        HMGLogError(@"Critical model/parsing error: remake already owned by user (%@). Why %@?", remake.user.sID, user.sID);
        return nil;
    }
    remake.sID = sID;
    remake.story = story;
    remake.user = user;
    return remake;
}

// Finds and returns existing remake with given id. returns nil if not found.
+(Remake *)findWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@",sID];
    return (Remake *)[DB.sh fetchSingleEntityNamed:HM_REMAKE withPredicate:predicate inContext:context];
}

// Returns a footage related to the instance of this remake, related to the given scene ID.
// If scene ID is illegal (doesn't exists in related story) returns nil.
// If scene ID is legal, but footage doesn't exist, will create a footage with no info and return it.
-(Footage *)footageWithSceneID:(NSNumber *)sID
{
    // Ensure related story has the related sceneID
    if (![self.story hasSceneWithID:sID]) {
        HMGLogError(@"Wrong scene ID (%@) for this remake (%@)", sID, self.sID);
        return nil;
    }
    
    // Find and return existing.
    Footage *footage = [self findFootageWithSceneID:sID];
    if (footage) return footage;
    
    // Create a new one if doesn't exist.
    return [Footage newFootageWithSceneID:sID remake:self inContext:self.managedObjectContext];
}

-(Footage *)findFootageWithSceneID:(NSNumber *)sID
{
    for (Footage *footage in self.footages) {
        if ([footage.sceneID isEqualToNumber:sID]) return footage;
    }
    return nil;
}

@end
