//
//  Story+Logic.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Story.h"

@interface Story (Logic)

///
/**
*  The scenes of the story ordered by scene id.
*/
@property (nonatomic, readonly) NSArray *scenesOrdered;

///
/**
 *  The texts of the story ordered by text id.
 */
@property (nonatomic, readonly) NSArray *textsOrdered;


///
/**
*  Used to check if story has a scene with the given scene id.
*
*  @param sID The scene id number to look for.
*
*  @return YES if scene id exists for that story. NO otherwise.
*/
-(BOOL)hasSceneWithID:(NSNumber *)sID;

///
/**
*  Searches and returns a scene object related to this story, if such scene id exists.
*
*  @param sID The scene id number to look for.
*
*  @return Returns a scene object if found. nil otherwise.
*/
-(Scene *)findSceneWithID:(NSNumber *)sID;

///
/**
*  Returns YES to "selfie" type stories (selfie=@YES)
*   NO otherwise
*
*  @return BOOL value indicating if the story is of the selfie type
*/
-(BOOL)isASelfie;

///
/**
*  Returns YES to "director" type stories (selfie=@NO)
*
*  @return BOOL value indicating if the story is of the director type
*/
-(BOOL)isADirector;

@end