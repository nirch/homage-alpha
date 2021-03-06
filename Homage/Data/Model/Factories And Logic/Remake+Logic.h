//
//  Remake+Logic.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake.h"

typedef NS_ENUM(NSInteger, HMGRemakeStatus) {
    HMGRemakeStatusNew,
    HMGRemakeStatusInProgress,
    HMGRemakeStatusRendering,
    HMGRemakeStatusDone,
    HMGRemakeStatusTimeout,
    HMGRemakeStatusDeleted,
    HMGRemakeStatusPendingScenes,
    HMGRemakeStatusPendingQueue,
    HMGRemakeStatusFailed,
    HMGRemakeStatusClientRequestedDeletion
};

typedef NS_ENUM(NSInteger, HMGRemakeBGQuality) {
    HMGRemakeBGQualityUndefined,
    HMGRemakeBGQualityBad,
    HMGRemakeBGQualityOK,
    HMGRemakeBGQualityGood
};


@interface Remake (Logic)

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

-(NSInteger)footagesUploadedCount;
-(NSInteger)footagesReadyCount;

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

/**
 *  Check if at least one footage was taken for this remake.
 *
 *  @return YES if user still didn't do any take (nextReadyForFirstRetakeSceneID is 1).
 */
-(BOOL)noFootagesTakenYet;

///
/**
*  Used to determine if the remake is ready for the user to choose "CREATE MOVIE"

*   This is true when there are no more scenes to be retaken for the first time (YES if "nextReadyForFirstRetakeSceneID" is nil).

*  @return YES if retake.nextReadyForFirstRetakeSceneID is nil, NO otherwise.
*/
-(BOOL)allScenesTaken;

///
/**
 *  Returns the last scene ID related to the story of this remake. (scenes are ordered by number)
 *
 *   @return sceneID with the highest value.
 */
-(NSNumber *)lastSceneID;

///
/**
*  Checks if user needs to enter any texts before creating a movie.
*
*  @return YES if the related story defined texts to be entered.
*   NO otherwise.
*/
-(BOOL)textsShouldBeEntered;

///
/**
 *  Checks if user needs to enter more texts before he can create a story.
 *
 *  @return YES if more texts should be entered and confirmed by the server.
 *   NO otherwise (so edit texts window should probably supplied to the user first).
 */
-(BOOL)missingSomeTexts;

///
/**
*  Returns a value of remake's text, given the text ID.
*
*  @param textID The text ID (notice, this starts at 1).
*
*  @return Returns a string or nil if the id is out of bounds.
*/
-(NSString *)textWithID:(NSNumber *)textID;

///
/**
*  Iterates footages of this remake and calls deleteRawLocalFile on each of them
*/
-(void)deleteRawLocalFiles;

///
/**
 *  Returns YES if the user liked this remake.
 *
 *  @param userID The user id of the user that liked/unliked this remake.
 *  @return Returns a boolean value indicating if the user did or didn't like this remake.
 */
-(BOOL)isLikedByUserID:(NSString *)userID;

///
/**
 *  Returns YES if the current user liked this remake.
 *
 *  @return Returns a boolean value indicating if the current user did or didn't like this remake.
 */
-(BOOL)isLikedByCurrentUser;

/**
 *  Mark as liked by given user.
 *
 *  @param userID The user id that liked this remake.
 */
-(void)likedByUserID:(NSString *)userID;

/**
 *  Unmark as liked by given user.
 *
 *  @param userID The user id that unliked this remake.
 */
-(void)unlikedByUserID:(NSString *)userID;

/**
 *  The ordered array of takes of this remake (with ready / taken footage).
 *
 *  @return An array of take ids. All footages must be in correct (taken) state. Otherwise will return nil.
 */
-(NSArray *)allTakenTakesIDS;

/**
 *  Return if the video of this remake was downloaded and is cached on the device.
 *
 *  @return A boolean value indicating if video is available or not on the device.
 */
-(BOOL)isVideoAvailableLocally;

/**
 *  Iterates footages and according to good/bad bg of all footages, returns
 *
 *      HMGRemakeBGQualityUndefined - one of the footages (or more) not taken yet
 *      HMGRemakeBGQualityBad - all footages shot with bad background.
 *      HMGRemakeBGQualityOK - some of the footages shot with good and some with bad bg.
 *      HMGRemakeBGQualityGood - all footages shot with good background.
 *
 *  @return HMGRemakeBGQuality number
 */
-(HMGRemakeBGQuality)footagesBGQuality;

@end
