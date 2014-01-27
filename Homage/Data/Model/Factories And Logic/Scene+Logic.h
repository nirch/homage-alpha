//
//  Scene+Logic.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Scene.h"

@interface Scene (Logic)

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

///
/**
 *  Does this scene have a script?
 *
 *  @return A boolean value indicating if the scene has any content in the script property.
 */
-(BOOL)hasScript;

///
/**
 * The point the camera should focus on
 *
 *  @return  A CGPoint representation of the point the camera should focus on
 */
-(CGPoint)focusCGPoint;




@end
