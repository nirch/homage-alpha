//
//  HMAWS3Client.m
//  Homage
//
//  Created by Aviv Wolf on 10/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAWS3Client.h"
#import "HMUploadS3Worker.h"
#import "Mixpanel.h"
#import "HMServer.h"

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

    // Configurate the transfer
    AWSStaticCredentialsProvider *credentialsProvider = [AWSStaticCredentialsProvider credentialsWithAccessKey:ACCESS_KEY_ID secretKey:SECRET_KEY];
    AWSServiceConfiguration *configuration = [AWSServiceConfiguration configurationWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
    [configuration setMaxRetryCount:5];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;

    // Get the default transfer manager.
    self.tm = [AWSS3TransferManager defaultS3TransferManager];

    // Check if transfer manager created.
    if (!self.tm) {
        HMGLogError(@"Failed initializing upload manager");
        [[Mixpanel sharedInstance] track:@"UploadManagerInitFailed"];
    }
}

-(AWSS3TransferManagerUploadRequest *)startUploadJobForWorker:(HMUploadS3Worker *)s3worker
{
    // Validations
    if (!s3worker.source) {
        HMGLogError(@"startUploadJobForWorker failed. No source file provided");
        [[Mixpanel sharedInstance] track:@"UploadJobStartFailed" properties:@{@"reason":@"No source file provided"}];
        return nil;
    }
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:s3worker.source]) {
        // File doesn't exist in the provided path
        HMGLogError(@"startUploadJobForWorker failed. File doesn't exist in provided path %@", s3worker.source);
        [[Mixpanel sharedInstance] track:@"UploadJobStartFailed" properties:@{@"reason":@"Source file missing",@"more_info":s3worker.source}];
        return nil;
    }
    
    
    if (!s3worker.destination) {
        HMGLogError(@"startUploadJobForWorker failed. No destination provided");
        [[Mixpanel sharedInstance] track:@"UploadJobStartFailed" properties:@{@"reason":@"No destination provided"}];
        return nil;
    }

    // Source url
    NSString *sourcePath = s3worker.source;
    if (![sourcePath hasPrefix:@"file://"]) {
        sourcePath = [NSString stringWithFormat:@"file://%@", sourcePath];
    }
    NSURL *sourceURL = [NSURL URLWithString:sourcePath];
    
    // The upload request.
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = HMServer.sh.bucketName;
    uploadRequest.body = sourceURL;
    uploadRequest.key = s3worker.destination;
    uploadRequest.metadata = s3worker.metaData;
    
    // return the upload request
    return uploadRequest;
}



@end
