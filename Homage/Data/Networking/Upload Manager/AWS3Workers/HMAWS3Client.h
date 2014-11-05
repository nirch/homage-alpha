//
//  HMAWS3Client.h
//  Homage
//
//  Created by Aviv Wolf on 10/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class HMUploadS3Worker;

#import <AWSiOSSDKv2/S3.h>

#define BUCKET_NAME     @"homageapp"
#define ACCESS_KEY_ID   @"AKIAJTPGKC25LGKJUCTA"
#define SECRET_KEY      @"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"

#define STATUS_LABEL_READY          @"Ready"
#define STATUS_LABEL_UPLOADING      @"Uploading..."
#define STATUS_LABEL_DOWNLOADING    @"Downloading..."
#define STATUS_LABEL_FAILED         @"Failed"
#define STATUS_LABEL_COMPLETED      @"Completed"

@interface HMAWS3Client : NSObject

// Transfer manager
@property (nonatomic, strong) AWSS3TransferManager *tm;

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
 *  @return Returns the AWSS3TransferManagerUploadRequest object for this upload operation.
 *
 */
-(AWSS3TransferManagerUploadRequest *)startUploadJobForWorker:(HMUploadS3Worker *)s3worker;

@end
