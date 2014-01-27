//
//  HMAWS3Client.h
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class HMUploadS3Worker;

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>

#define BUCKET_NAME     @"homageapp"
#define ACCESS_KEY_ID   @"AKIAJTPGKC25LGKJUCTA"
#define SECRET_KEY      @"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"

@interface HMAWS3Client : NSObject<AmazonServiceRequestDelegate>

// HMAWS3Client is a singleton
+(HMAWS3Client *)sharedInstance;

// Just an alias for sharedInstance for shorter writing.
+(HMAWS3Client *)sh;

///
/**
*  Start an upload operation for this worker and if it is implementing the AmazonServiceRequestDelegate protocol
*   will route all related delegate method call to it.
*
*  @param s3worker The worker keeping track of this specific upload job and reports to the manager.
*
*  @return Returns the S3TransferOperation object for this upload operation.
*
*/
-(S3TransferOperation *)startUploadJobForWorker:(HMUploadS3Worker *)s3worker;

@end
