//
//  Remake+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake.h"

@interface Remake (Factory)

// Creates or fetches a remake with given id, related to given story and user.
+(Remake *)remakeWithID:(NSString *)sID story:(Story *)story user:(User *)user inContext:(NSManagedObjectContext *)context;

// Finds and returns existing remake with given id. returns nil if not found.
+(Remake *)findWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context;

// Returns a footage related to the instance of this remake, related to the given scene ID.
// If scene ID is illegal (doesn't exists in related story) returns nil.
// If scene ID is legal, but footage doesn't exist, will create a footage with no info and return it.
-(Footage *)footageWithSceneID:(NSNumber *)sID;

@end
