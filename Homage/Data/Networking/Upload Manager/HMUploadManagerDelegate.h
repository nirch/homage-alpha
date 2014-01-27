//
//  HMUploadManagerDelegate.h
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

@protocol HMUploadManagerDelegate <NSObject>


@optional

///
/**
*  A worker is reporting about progress made
*
*  @param worker   The worker reporting the progress
*  @param progress A fraction of the progress for this job.
*/
-(void)worker:(id)worker reportingProgress:(double)progress info:(NSDictionary *)info;

///
/**
 *  A worker is reporting about finishing a job.
 *
 *  @param worker   The worker reporting the end of the job.
 *  @param success  A boolean value indicating if the job was finished successfuly or not.
 */
-(void)worker:(id)worker reportingFinishedWithSuccess:(BOOL)success info:(NSDictionary *)info;


@end
