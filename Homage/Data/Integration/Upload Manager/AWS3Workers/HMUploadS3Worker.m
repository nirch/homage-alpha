//
//  HMUploadS3Worker.m
//  Homage
//
//  Created by Aviv Wolf on 10/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUploadS3Worker.h"
#import "HMNotificationCenter.h"
#import "Mixpanel.h"
#import "HMServer.h"

@interface HMUploadS3Worker()

@property (nonatomic) HMAWS3Client *client;
@property (nonatomic) NSString *name;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) int64_t totalBytesWritten;
@property (nonatomic) int64_t totalBytesExpectedToWrite;
@property (nonatomic) BOOL wasCanceled;

@end

@implementation HMUploadS3Worker

@synthesize delegate = _delegate;
@synthesize jobID = _jobID;
@synthesize source = _source;
@synthesize destination = _destination;
@synthesize userInfo = _userInfo;
@synthesize progress = _progress;
@synthesize metaData = _metaData;


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
    _metaData = nil;
}

-(BOOL)startWorking
{
    //
    // Create the upload request to do the job.
    //
    self.wasCanceled = NO;
    AWSS3TransferManagerUploadRequest *uploadRequest = [self.client startUploadJobForWorker:self];
    if (!uploadRequest) return NO;
    
    //
    // Mark as working in the background, so if app goes to the background, the upload will continue.
    //
    [self markAsWorkingInTheBackground];
    self.userInfo[@"uploadRequest"] = uploadRequest;
    
    //
    // Upload progress block.
    //
    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self requestDidSendData:bytesSent totalBytesWritten:totalBytesSent totalBytesExpectedToWrite:totalBytesExpectedToSend];
        });
    };
    
    //
    //  Tell client transfer manager to start the upload and handle success/failure.
    //
    NSDate *start = [NSDate date];
    [[self.client.tm upload:uploadRequest] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
        
        NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:start];
        NSString *networkType = HMServer.sh.connectionLabel;
        
        //
        // Handle success.
        //
        if (!task.error && task.isCompleted && !task.isCancelled && !self.wasCanceled) {
                double speed = self.totalBytesWritten/duration;
            
                // Successful upload. Update the manager.
                _progress = 1.0;
                HMGLogDebug(@"Completed upload");
                [self.delegate worker:self reportingFinishedWithSuccess:YES info:nil];
                [self unmarkAsWorkingInTheBackground];
                [[Mixpanel sharedInstance] track:@"UploadSuccess" properties:@{@"source":self.source,
                                                                               @"destination":self.destination,
                                                                               @"duration":@(duration),
                                                                               @"spd":@(speed),
                                                                               @"total_bytes_sent":@(self.totalBytesWritten),
                                                                               @"total_bytes_expected_to_write":@(self.totalBytesExpectedToWrite),
                                                                               @"network_type":networkType
                                                                               }];
            
            return nil;
        }
        
        //
        // Handle cancellation.
        //
        if (self.wasCanceled) {
            HMGLogDebug(@"Upload task was canceled because of user retake.");
            [[Mixpanel sharedInstance] track:@"UploadCanceled" properties:@{@"source":self.source,
                                                                            @"destination":self.destination,
                                                                            @"duration":@(duration),
                                                                            @"total_bytes_sent":@(self.totalBytesWritten),
                                                                            @"total_bytes_expected_to_write":@(self.totalBytesExpectedToWrite),
                                                                            @"network_type":networkType
                                                                            }];
            
            [self.delegate worker:self reportingFinishedWithSuccess:NO info:nil];
            [self unmarkAsWorkingInTheBackground];
            return nil;
        }
        
        //
        // Handle failure.
        //
        
        // Update the app's upload manager.
        NSString *errorString = task.error ? [task.error localizedDescription] : @"";
        [[Mixpanel sharedInstance] track:@"UploadFailed" properties:@{@"source":self.source,
                                                                      @"destination":self.destination,
                                                                      @"duration":@(duration),
                                                                      @"total_bytes_sent":@(self.totalBytesWritten),
                                                                      @"total_bytes_expected_to_write":@(self.totalBytesExpectedToWrite),
                                                                      @"network_type":networkType,
                                                                      @"is_canceled":@(task.isCancelled),
                                                                      @"error":errorString
                                                                      }];
        
        [self.delegate worker:self reportingFinishedWithSuccess:NO info:@{@"error":errorString}];
        [self unmarkAsWorkingInTheBackground];
        return nil;
    }];
    
    return YES;
}

-(void)stopWorking
{
    AWSS3TransferManagerUploadRequest *uploadRequest =self.userInfo[@"uploadRequest"];
    self.wasCanceled = YES;
    [uploadRequest cancel];
    [self.userInfo removeObjectForKey:@"uploadRequest"];
    HMGLogDebug(@"Upload worker stopping: %@", self.destination);
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

#pragma mark - Upload progress
//
//  Did send data
//
-(void)requestDidSendData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    double progress = ((double)totalBytesWritten/(double)totalBytesExpectedToWrite);
    self.totalBytesWritten = totalBytesWritten;
    self.totalBytesExpectedToWrite = totalBytesExpectedToWrite;

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



@end
