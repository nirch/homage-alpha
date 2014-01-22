//
//  Footage+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage.h"

@class Scene;

typedef NS_ENUM(NSInteger, HMFootageStatus) {
    HMFootageStatusStatusOpen,
    HMFootageStatusStatusUploading,
    HMFootageStatusStatusProcessing,
    HMFootageStatusStatusReady
};

typedef NS_ENUM(NSInteger, HMFootageReadyState) {
    HMFootageReadyStateReadyForFirstRetake,
    HMFootageReadyStateReadyForSecondRetake,
    HMFootageReadyStateStillLocked
};

@interface Footage (Factory)

@property (nonatomic, readonly) Scene *relatedScene;

///
/**
*  Creates a new footage with scene ID
*
*  @param sID     The relates scene ID
*  @param remake  The related remake object.
*  @param context The managed object context.
*
*  @return Returns the newly created footage object.
*/
+(Footage *)newFootageWithSceneID:(NSNumber *)sID remake:(Remake *)remake inContext:(NSManagedObjectContext *)context;

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

@end
