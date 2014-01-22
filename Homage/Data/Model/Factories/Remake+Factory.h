//
//  Remake+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake.h"

@interface Remake (Factory)

typedef NS_ENUM(NSInteger, HMGRemakeStatus) {
    HMGRemakeStatusNew,
    HMGRemakeStatusInProgress,
    HMGRemakeStatusRendering,
    HMGRemakeStatusDone
};

// Creates or fetches a remake with given id, related to given story and user.
+(Remake *)remakeWithID:(NSString *)sID story:(Story *)story user:(User *)user inContext:(NSManagedObjectContext *)context;

///
/**
*  Search for an existing remake by given id.
*
*  @param sID     id of the remake.
*  @param context The managed object context.
*
*  @return Returns existing remake with given id. returns nil if not found.
*/
+(Remake *)findWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context;

///
/**
*  Returns a footage related to the instance of this remake, related to the given scene ID.
*
*  @param sID id of a scene.
*
*  @return If scene ID is illegal (doesn't exists in related story) returns nil. 
*           If scene ID is legal, but footage doesn't exist, will create a footage with no info and return it.
*/
-(Footage *)footageWithSceneID:(NSNumber *)sID;


///
/**
*  The scene ID related to the first footage with a HMFootageReadyStateReadyForFirstRetake state.
*
*   (HMFootageReadyStateReadyForFirstRetake simply means a "white" scene without a lock near it and that the user still didn't provide footage for it)
*
*  @return Returns ths first sceneID number. Returns nil if none found.
*/
-(NSNumber *)nextReadyForFirstRetakeSceneID;

///
/**
*  Returns the last scene ID related to the story of this remake. (scenes are ordered by number)
*
*   @return sceneID with the highest value.
*/
-(NSNumber *)lastSceneID;

@end
