//
//  Scene+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Scene.h"

#define HM_SCENE        @"Scene"

@interface Scene (Factory)

///
/**
*  Finds or creates a new scene with the given scene id for the given story.
*
*  @param sID     The scene ID number.
*  @param story   The story the scene is related to.
*  @param context The managed object context.
*
*  @return An existing or newly created scene with the given id and related to given story.
*/
+(Scene *)sceneWithID:(NSNumber *)sID story:(Story *)story inContext:(NSManagedObjectContext *)context;


@end
