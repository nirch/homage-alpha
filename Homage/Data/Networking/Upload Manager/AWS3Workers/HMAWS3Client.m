//
//  HMAWS3Client.m
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAWS3Client.h"
#import "HMUploadS3Worker.h"

#define UPLOAD_TIMEOUT 600
#define CONNECTION_TIMEOUT 60

@interface HMAWS3Client()

@end

@implementation HMAWS3Client

// HMAWS3Client is a singleton
+(HMAWS3Client *)sharedInstance
{
    static HMAWS3Client *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMAWS3Client alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMAWS3Client *)sh
{
    return [HMAWS3Client sharedInstance];
}

#pragma mark - Initializations
-(id)init
{
    self = [super init];
    if (self) {
        [self initS3TransferManager];
    }
    return self;
}


-(void)initS3TransferManager
{
    HMGLogDebug(@"initS3TransferManager");
    
    // Initialize the S3 Client.
    [AmazonErrorHandler shouldNotThrowExceptions];
    AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    // [AmazonLogger verboseLogging];
    
    s3.timeout = UPLOAD_TIMEOUT;
    s3.connectionTimeout = CONNECTION_TIMEOUT;
    s3.maxRetries = 10;
    
    // Initialize the S3TransferManager
    self.tm = [S3TransferManager new];
    self.tm.s3 = s3;
}

-(S3TransferOperation *)startUploadJobForWorker:(HMUploadS3Worker *)s3worker
{
    // Validations
    
    if (!s3worker.source) {
        HMGLogError(@"startUploadJobForWorker failed. No source file provided");
        return nil;
    }


    if (![[NSFileManager defaultManager] fileExistsAtPath:s3worker.source]) {
        // File doesn't exist in the provided path
        HMGLogError(@"startUploadJobForWorker failed. File doesn't exist in provided path %@", s3worker.source);
        return nil;
    }

    
    if (!s3worker.destination) {
        HMGLogError(@"startUploadJobForWorker failed. No destination provided");
        return nil;
    }
    
    
    // The upload request.
    // Sets the worker as the delegate.
    S3PutObjectRequest *uploadRequest = [S3PutObjectRequest new];
    uploadRequest.bucket = BUCKET_NAME;
    uploadRequest.filename = s3worker.source;
    uploadRequest.key = s3worker.destination;
    uploadRequest.delegate = s3worker;
    S3TransferOperation *transferOpertaion = [self.tm upload:uploadRequest];
    
    return transferOpertaion;
}

@end
