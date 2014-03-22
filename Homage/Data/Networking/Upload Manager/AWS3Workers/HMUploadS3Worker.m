//
//  HMUploadS3Worker.m
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUploadS3Worker.h"
#import "HMNotificationCenter.h"

@interface HMUploadS3Worker()

@property (nonatomic) HMAWS3Client *client;
@property (nonatomic) NSString *name;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;

@end

@implementation HMUploadS3Worker

@synthesize delegate = _delegate;
@synthesize jobID = _jobID;
@synthesize source = _source;
@synthesize destination = _destination;
@synthesize userInfo = _userInfo;
@synthesize progress = _progress;


+(NSSet *)instantiateWorkers:(NSInteger)numberOfWorkers
{
    NSMutableSet *workers = [NSMutableSet new];
    for (int i=0;i<numberOfWorkers;i++) {
        HMUploadS3Worker *newWorker = [HMUploadS3Worker new];
        [workers addObject:newWorker];
    }
    return workers;
}


-(id)init
{
    self = [super init];
    if (self) {
        self.client = [HMAWS3Client new];
    }
    return self;
}


#pragma mark - Source and destination url
-(void)newJobWithID:(NSString *)jobID source:(NSString *)source destination:(NSString *)destination
{
    _jobID = jobID;
    _source =  source;
    _destination = destination;
    _name = [destination lastPathComponent];
    _progress = 0;
}

-(BOOL)startWorking
{
    S3TransferOperation *transferOperation = [self.client startUploadJobForWorker:self];
    if (!transferOperation) {
        HMGLogError(@"Couldn't start upload job (transferOperation is nil) %@", self.jobID);
        return NO;
    }
    [self markAsWorkingInTheBackground];
    self.userInfo[@"transferOperation"] = transferOperation;
    return YES;
}

-(void)stopWorking
{
//    [self.client.tm cancelAllTransfers];
    S3TransferOperation *transferOperation = self.userInfo[@"transferOperation"];
    S3PutObjectRequest *putRequest = transferOperation.putRequest;
    [transferOperation pause];
    [transferOperation cleanup];
    [putRequest cancel];
    [self.userInfo removeObjectForKey:@"transferOperation"];
}

-(void)markAsWorkingInTheBackground
{
    //
    // Just in case it is still marked.
    //
    [self unmarkAsWorkingInTheBackground];
    
    //
    // Mark for working in the background.
    //
    UIApplication *app = [UIApplication sharedApplication];
    __weak HMUploadS3Worker *wSelf = self;
    _backgroundTask = [app beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [app endBackgroundTask:wSelf.backgroundTask];
        wSelf.backgroundTask = UIBackgroundTaskInvalid;
    }];
}

-(void)unmarkAsWorkingInTheBackground
{
    if (self.backgroundTask != UIBackgroundTaskInvalid) {
        UIApplication *app = [UIApplication sharedApplication];
        [app endBackgroundTask:self.backgroundTask];
        self.backgroundTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark - AmazonServiceRequestDelegate
//
//  Did receive response
//
-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    HMGLogDebug(@"didReceiveResponse called: %@", response);
}

//
//  Did send data
//
-(void)request:(AmazonServiceRequest *)request didSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    // HMGLogDebug(@"%lld / %lld writtern", totalBytesWritten, totalBytesExpectedToWrite);
    double progress = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite);
    if (progress > self.progress+0.05) {
        _progress = progress;
        HMGLogDebug(@"%@ %.02f writtern", self.source, self.progress);
        
        // Update the manager, if able.
        if ([self.delegate respondsToSelector:@selector(worker:reportingProgress:info:)]) {
            [self.delegate worker:self reportingProgress:self.progress info:self.userInfo];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UPLOAD_PROGRESS object:self userInfo:@{}];
        
    }
}


//
// Did complete response
//
-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    /**
     Example response for multipart upload.
     
     <?xml version="1.0" encoding="UTF-8"?>
     <CompleteMultipartUploadResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
     <Location>https://homageapp.s3.amazonaws.com/Remakes%2F52e58c31db25451064000011%2Fraw_scene_1.mov</Location>
     <Bucket>homageapp</Bucket>
     <Key>Remakes/52e58c31db25451064000011/raw_scene_1.mov</Key>
     <ETag>"29e1fcd4157073de5b851016b46224a3-3"</ETag>
     </CompleteMultipartUploadResult>
     
     */
    _progress = 1.0;
    HMGLogDebug(@"Complete with response: %@", [[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding]);

    // Update the manager, if able.
    if ([self.delegate respondsToSelector:@selector(worker:reportingFinishedWithSuccess:info:)]) {
        [self.delegate worker:self reportingFinishedWithSuccess:YES info:nil];
    }

    [self unmarkAsWorkingInTheBackground];
}



//
//  did fail with error
//
-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    HMGLogDebug(@"didFailWithError called: %@", error);
    
    // Update the manager, if able.
    if ([self.delegate respondsToSelector:@selector(worker:reportingFinishedWithSuccess:info:)]) {
        [self.delegate worker:self reportingFinishedWithSuccess:NO info:@{@"error":error}];
    }
    
    [self unmarkAsWorkingInTheBackground];
}


//
//  did fail with service exception
//
-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    HMGLogDebug(@"didFailWithServiceException called: %@", exception);
    
    // Update the manager, if able.
    if ([self.delegate respondsToSelector:@selector(worker:reportingFinishedWithSuccess:info:)]) {
        [self.delegate worker:self reportingFinishedWithSuccess:NO info:@{@"exception":exception}];
    }
    
    [self unmarkAsWorkingInTheBackground];
}



@end
