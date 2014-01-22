//
//  Scene+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Scene.h"

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

///
/**
*  Given a scene ID, returns a string title in a fixed format. For example:SCENE 3
*
*  @param sceneID The id number of a scene.
*
*  @return Title as a string.
*/
+(NSString *)titleForSceneBySceneID:(NSNumber *)sceneID;

///
/**
*  Uses titleForSceneBySceneID with the id of this scene and returns the title.
*
*  @return Title as a string.
*/
-(NSString *)titleForSceneID;

///
/**
*  Returns a formatted title for the duration of the scene in seconds.tenths of a second.
*
*  @return Title as a string. Time in seconds and tenths of a second ==> @"#.#"
*/
-(NSString *)titleForTime;

///
/**
*  The duration in seconds (stored duration / 1000)
*
*   @return Duration in seconds as NSTimeInterval
*/
-(NSTimeInterval)durationInSeconds;

@end
