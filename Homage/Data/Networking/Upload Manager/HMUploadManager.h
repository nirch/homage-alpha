//
//  HMUploadManager.h
//  Homage
//
//  Abstraction of an uploader, so the specific implementation with S3 can be replaced later.
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Footage;

#import "HMUploadWorkerProtocol.h"
#import "HMUploadManagerDelegate.h"

@interface HMUploadManager : NSObject<HMUploadManagerDelegate>

// HMUploadManager is a singleton
+(HMUploadManager *)sharedInstance;

// Just an alias for sharedInstance for shorter writing.
+(HMUploadManager *)sh;

///
/**
*   Adds a set of worker to the upload manager.
*
*  @param workers - a set of workers conforming with the HMUploadWorkerProtocol
*/
-(void)addWorkers:(NSSet *)workers;

///
/**
*  Start monitoring Footage raw video files to upload and begin to assign available workers
*   to upload jobs.
*/
-(void)startMonitoring;

///
/**
*  Cancel all current upload jobs and return all workers to the workers pool.
*/
-(void)stopMonitoring;


///
/**
*  Check for uploads.
*/
-(void)checkForUploads;

///
/**
 *  Check for uploads, but give a list of spcific footages a priority above all others.
 *     Same as checkForUploads, but also provides a list of footages that will get higher priority
 *     when the manager picks raw files to be uploaded.
 *
 *  @param footages - an array of footages what will be prioritized when choosing the next raw file of a footage to upload.
 */
-(void)checkForUploadsWithPrioritizedFootages:(NSArray *)footages;

///
/**
*  Given a footage, will check if that footage is currently being uploaded.
*   if it does, that upload will be stopped and the relevant worker will be returned to the idle workers pool.
*   if it doesn't, nothing will happen.
*
*   @param footage - the footage what the upload of should be canceled (if such exists).
*/
-(void)cancelUploadForFootage:(Footage *)footage;

///
/**
*  A way to ask the upload manager if he currently uploads a file related to the given footage.
*
*  @param footage The footage we ask the question about.
*
*  @return YES if an upload job currently exists fot this footage.
*/
-(BOOL)isCurrentlyUploadingFootage:(Footage *)footage;

///
/**
 *  Cancel all upload jobs currently active (if any exist).
 *   All workers will return to the idle workers pool.
 */
-(void)cancelAllUploads;




@end
