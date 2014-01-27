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
 */
-(void)checkForUploadsWithPrioritizedFootages:(NSArray *)footages;

@end
