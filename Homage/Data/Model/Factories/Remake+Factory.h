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
///
/**
*  An array of footages of this remake, ordered by the related sceneID.
*/
@property (nonatomic, readonly) NSArray *footagesOrdered;


///
/**
*  A footage can be: Already taken and ready for a retake, Ready for recording or Locked (see HMFootageReadyState)
*/
@property (nonatomic, readonly) NSArray *footagesReadyStates;

///
/**
*  Creates or fetches a remake with given id, related to given story and user.
*
*  @param sID     id of existing/new remake.
*  @param story   a story object the remake is related to.
*  @param user    the user related to the remake.
*  @param context The managed object context.
*
*  @return an existing remake (or a new one, if not found).
*/
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
