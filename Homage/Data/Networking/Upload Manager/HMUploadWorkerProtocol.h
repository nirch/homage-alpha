//
//  HMUploadWorkerProtocol.h
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUploadManagerDelegate.h"

@protocol HMUploadWorkerProtocol <NSObject>

@property (nonatomic, weak) id<HMUploadManagerDelegate> delegate;

@property (nonatomic, readonly) NSString *source;
@property (nonatomic, readonly) NSString *destination;
@property (nonatomic, readonly) NSString *jobID;
@property (nonatomic, readonly) double progress;
@property (nonatomic) NSMutableDictionary *userInfo;

///
/**
*  Sets the source url to read the file from and the destination url to upload the file to.
*
*  @param jobID          a unique string identifier for the new job.
*  @param source      string value representing the source of the file, usually on the local file system.
*  @param destination string value representing the destination url to upload to, usually on some remote server.
*
*   Remark - The implementation will decide what source and destination actually means (can be urls or anything else).
*/
-(void)newJobWithID:(NSString *)jobID source:(NSString *)source destination:(NSString *)destination;

///
/**
*  Gives the worker the command to start uploading the file.
*
*   @return YES if was able to start working. NO otherwise. (A manager probably should check this returned value)
*
*/
-(BOOL)startWorking;

///
/**
*  Tells a working worker to stop / cancel what it is currently doing.
*/
-(void)stopWorking;

@end
