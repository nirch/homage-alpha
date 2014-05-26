//
//  HMServer+Remakes.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Remakes)

///
/**
 *  A POST request to the server requesting to create a new remake of a story by a user.

 *  Notification name when done: HM_NOTIFICATION_SERVER_REMAKE_CREATION.

 *  Parser used: HMRemakeParser.

 *  @code
 
[HMServer.sh remakeStoryWithID:self.story.sID forUserID:User.current.userID];
 
 *  @endcode
 *  @param storyID The id of the story
 *  @param userID  The id of the user
 */
-(void)createRemakeForStoryWithID:(NSString *)storyID forUserID:(NSString *)userID withResolution:(NSString *)resolution;

///
/**
 *  A GET request to the server requesting info about a remake with given ID.
 
 *  Notification name when done: HM_NOTIFICATION_SERVER_REMAKE_CREATION.
 
 *  Parser used: HMRemakeParser.
 
 *  @code
 
 [HMServer.sh remakeStoryWithID:self.story.sID forUserID:User.current.userID];
 
 *  @endcode
 *  @param storyID The id of the story
 *  @param userID  The id of the user
 */
-(void)refetchRemakeWithID:(NSString *)remakeID;


///
/**
 *  A GET request to the server requesting info about remakes related to a user.

 *  Notification name when done: HM_NOTIFICATION_SERVER_USER_REMAKES.

 *  Parser used: HMRemakesParser.

 *  @code
[HMServer.sh refetchRemakesForUserID:User.current.userID];
 *  @endcode
 *  @param userID  The id of the user
 */
-(void)refetchRemakesForUserID:(NSString *)userID;

///
/**
 *  A DELETE request to the server requesting deletion of the remake with the given id.
 
 *  Notification name when done: HM_NOTIFICATION_SERVER_REMAKE_DELETION.
 
 *  Parser used: HMRemakeParser.
 
 *  @code
[HMServer.sh deleteRemakeWithID:remakeID];
 *  @endcode
 *  @param remakeID  The id of the remake to delete.
 */
-(void)deleteRemakeWithID:(NSString *)remakeID;


    
    
///
/**
 *  A GET request to the server requesting info about remakes related to a user.
 
 *  Notification name when done: HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY.
 
 *  Parser used: HMRemakesParser.
 
 *  @code
 [HMServer.sh refetchRemakesWithStoryID:storyID];
 *  @endcode
 *  @param storyID  The id of the story
 */
-(void)refetchRemakesWithStoryID:(NSString *)storyID;



-(void)markRemakeAsInappropriate:(NSDictionary *)userParams;
    
    
    
@end
