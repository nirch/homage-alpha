//
//  HMUploadManager.m
//  Homage
//
//  Created by Aviv Wolf on 1/18/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#define BUCKET_NAME     @"homageapp"
#define ACCESS_KEY_ID   @"AKIAJTPGKC25LGKJUCTA"
#define SECRET_KEY      @"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"
#define TEST_FILE_KEY   @"Test File"
#define TEST_FILE_SIZE  1000000LL

#import "HMUploadManager.h"

@interface HMUploadManager()

@property (nonatomic, strong, readonly) NSMutableDictionary *uploadOperations;

@end

@implementation HMUploadManager

// HMUploadManager is a singleton
+(HMUploadManager *)sharedInstance
{
    static HMUploadManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMUploadManager alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMUploadManager *)sh
{
    return [HMUploadManager sharedInstance];
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
    _uploadOperations = [NSMutableDictionary new];
    
    // Initialize the S3 Client.
    AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:ACCESS_KEY_ID withSecretKey:SECRET_KEY];
    //[AmazonLogger verboseLogging];
    
    // Initialize the S3TransferManager
    self.tm = [S3TransferManager new];
    self.tm.s3 = s3;
    self.tm.delegate = self;

    // Log the available buckets for this client.
    for (S3Bucket *bucket in self.tm.s3.listBuckets) {
        HMGLogDebug(@"Buckets available:%@", bucket.name);
    }
    
    // Create the bucket
    S3CreateBucketRequest *createBucketRequest = [[S3CreateBucketRequest alloc] initWithName:@"homageapp"];
    @try {
        S3CreateBucketResponse *createBucketResponse = [s3 createBucket:createBucketRequest];
        HMGLogDebug(@"Create bucket response object:%@", createBucketResponse);
        if(createBucketResponse.error != nil)
        {
            NSLog(@"Error: %@", createBucketResponse.error);
        }
    }@catch(AmazonServiceException *exception){
        if(![@"BucketAlreadyOwnedByYou" isEqualToString: exception.errorCode]){
            NSLog(@"Unable to create bucket: %@", exception.error);
        }
    }
    
    NSString *filePath = [self generateTempFile:@"test_data.txt" size:TEST_FILE_SIZE];
    self.uploadOperations[TEST_FILE_KEY] = [self.tm uploadFile:filePath bucket:BUCKET_NAME key:TEST_FILE_KEY];
    
    
//
//    // Dictionary of upload operations
//
//    
//    // Test uploading file
////    self.uploadOperations[@"test"] =
}

-(NSString *)generateTempFile:(NSString *)filename size:(long long)approximateFileSize {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString * filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    if (![fm fileExistsAtPath:filePath]) {
        NSOutputStream * os= [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
        NSString * dataString = @"S3TransferManager_V2 ";
        const uint8_t *bytes = [dataString dataUsingEncoding:NSUTF8StringEncoding].bytes;
        long fileSize = 0;
        [os open];
        while(fileSize < approximateFileSize){
            [os write:bytes maxLength:dataString.length];
            fileSize += dataString.length;
        }
        [os close];
    }
    return filePath;
}

#pragma mark - AmazonServiceRequestDelegate
-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse called: %@", response);
}

-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    NSLog(@"%lld / %lld writtern", totalBytesWritten, totalBytesExpectedToWrite);
//    if([((S3PutObjectRequest *)request).key isEqualToString:kKeyForSmallFile]){
//        double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
//        self.putObjectTextField.text = [NSString stringWithFormat:@"%.2f%%", percent];
//    }
//    else if([((S3PutObjectRequest *)request).key isEqualToString:kKeyForBigFile]) {
//        double percent = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite)*100;
//        self.multipartObjectTextField.text = [NSString stringWithFormat:@"%.2f%%", percent];
//    }
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    NSLog(@"Complete with response: %@", [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]);
//    if([((S3PutObjectRequest *)request).key isEqualToString:kKeyForSmallFile]){
//        self.putObjectTextField.text = @"Done";
//    }
//    else if([((S3PutObjectRequest *)request).key isEqualToString:kKeyForBigFile]) {
//        self.multipartObjectTextField.text = @"Done";
//    }
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError called: %@", error);
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    NSLog(@"didFailWithServiceException called: %@", exception);
}

@end
