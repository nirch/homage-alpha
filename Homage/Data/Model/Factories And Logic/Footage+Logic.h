//
//  Footage+Logic.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage.h"

@class Scene;

@interface Footage (Logic)

///
typedef NS_ENUM(NSInteger, HMFootageStatus) {
    HMFootageStatusStatusOpen,
    HMFootageStatusStatusUploading,
    HMFootageStatusStatusProcessing,
    HMFootageStatusStatusReady
};




typedef NS_ENUM(NSInteger, HMFootageReadyState) {
    HMFootageReadyStateReadyForFirstRetake,
    HMFootageReadyStateReadyForSecondRetake,
    HMFootageReadyStateStillLocked,
    HMFootageReadyStateStillUnkown
};

///
/**
*  The scene related to this footage.
*/
-(Scene *)relatedScene;

///
/**
 *  Creates a new unique file name for a local raw footage video file.
 *   The format of the file name is '<remakeID>_<sceneID>_<timeStamp>.mp4'
 *
 *  @return File name as a string.
 */
-(NSString *)generateNewRawFileName;

///
/**
 *  Deletes the related raw local file and set rawLocalFile property to nil.
 */
-(void)deleteRawLocalFile;

///
/**
*  Returns the ready state of a footage.
*
*   @return HMFootageReadyState value (ready for first retake, ready for second retake or still locked)
*/
-(HMFootageReadyState)readyState;

///
/**
*   Returns YES if this footage already has a local raw file that was not successfully uploaded in the past.
*   (the rawLocalFile should be identical to rawUploadedFile, if a succesful upload took place)
*/
-(BOOL)rawLocalFileShouldBeUploaded;

///
/**
*  An identifier including the remake id and scene id related to this footage
*
*  @return A string value of the format <remakeID>_<sceneID>
*/
-(NSString *)identifier;

@end
