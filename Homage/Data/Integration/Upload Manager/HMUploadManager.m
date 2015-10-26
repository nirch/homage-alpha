//
//  HMUploadManager.m
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "DB.h"
#import "HMUploadManager.h"
#import "HMServer+Footages.h"
#import "HMNotificationCenter.h"
#import "HMServer+ReachabilityMonitor.h"
#import "mixPanel.h"
#import "HMServer+AppConfig.h"
#import "HMCacheManager.h"

#define MAX_NUMBER_OF_SERVER_UPDATE_ATTEMPTS 3

@interface HMUploadManager()

@property (nonatomic, readonly) NSMutableSet *idleWorkersPool;
@property (nonatomic, readonly) NSMutableDictionary *busyWorkers;
@property (nonatomic, readonly) NSMutableDictionary *footagesByJobID;
@property (nonatomic, readonly) NSMutableDictionary *workersByFootageIdentifier;

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
        _idleWorkersPool = [NSMutableSet new];
        _busyWorkers = [NSMutableDictionary new];
        _footagesByJobID = [NSMutableDictionary new];
        _workersByFootageIdentifier = [NSMutableDictionary new];
    }
    return self;
}

-(void)addWorkers:(NSSet *)workers
{
    for (id<HMUploadWorkerProtocol>worker in workers) {
        // The manager will add itself as the delegate for all workers
        // And add each worker to the idle workers pool.
        [worker setDelegate:self];
        [self.idleWorkersPool addObject:worker];
    }
}

-(void)startMonitoring
{
    [self initObservers];
    [self checkForUploads];
}

-(void)stopMonitoring
{
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // Observe reachability
    [nc addUniqueObserver:self
                 selector:@selector(onReachabilityStatusChanged:)
                     name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                   object:nil];
    
    
    // Observe upload start updates
    [nc addUniqueObserver:self
                 selector:@selector(onServerUpdatedAboutUploadNeedsToStart:)
                     name:HM_NOTIFICATION_SERVER_FOOTAGE_UPLOAD_START
                   object:nil];

    // Observe upload success updates
    [nc addUniqueObserver:self
                 selector:@selector(onServerUpdatedAboutUploadSuccess:)
                     name:HM_NOTIFICATION_SERVER_FOOTAGE_UPLOAD_SUCCESS
                   object:nil];

}


-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_FOOTAGE_UPLOAD_START object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_FOOTAGE_UPLOAD_SUCCESS object:nil];
}

#pragma mark - Observers handlers
-(void)onReachabilityStatusChanged:(NSNotification *)notification
{
    if (HMServer.sh.isReachable)
        [self checkForUploads];
}

-(void)onServerUpdatedAboutUploadNeedsToStart:(NSNotification *)notification
{
    NSString *remakeID = notification.userInfo[@"remakeID"];
    NSNumber *sceneID = notification.userInfo[@"sceneID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    Footage *footage = [remake footageWithSceneID:sceneID];
    NSInteger attemptCount = [notification.userInfo[@"attemptCount"] integerValue];

    if (notification.isReportingError) {
        HMGLogError(@"Failed updating server about footage ready for upload. %@ Attempt %@", footage.takeID, @(attemptCount));
        // Inform mixpanel that failed to update server about upload about to start.
        NSDictionary *props = @{
                                @"remake_id":remakeID,
                                @"scene_id":sceneID,
                                @"take_id":footage.takeID,
                                @"attempt_count":@(attemptCount)
                                };
        [[Mixpanel sharedInstance] track:@"UpdateServerAboutUploadStartFailed" properties:props];

        // Failed to update server about that an upload to s3 is about to start.
        // Wait awhile and retry to update the server.
        attemptCount++;
        if (attemptCount <= MAX_NUMBER_OF_SERVER_UPDATE_ATTEMPTS) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self updateServerAboutUploadFootage:footage attemptCount:attemptCount];
            });
        }
        return;
    }
    
    // Start the upload.
    [self uploadFootage:footage];
}

-(void)onServerUpdatedAboutUploadSuccess:(NSNotification *)notification
{
    NSString *remakeID = notification.userInfo[@"remakeID"];
    NSNumber *sceneID = notification.userInfo[@"sceneID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    Footage *footage = [remake footageWithSceneID:sceneID];
    NSInteger attemptCount = [notification.userInfo[@"attemptCount"] integerValue];

    if (notification.isReportingError) {
        HMGLogError(@"Failed updating server about footage upload success. %@ Attempt %@", footage.takeID, @(attemptCount));
        // Inform mixpanel that failed to update server about upload about to start.
        NSDictionary *props = @{
                                @"remake_id":remakeID,
                                @"scene_id":sceneID,
                                @"take_id":footage.takeID,
                                @"attempt_count":@(attemptCount)
                                };
        [[Mixpanel sharedInstance] track:@"UpdateServerAboutUploadSuccessFailed" properties:props];
        
        // Failed to update server about that an upload to s3 was successful.
        // Wait awhile and retry to update the server.
        attemptCount++;
        if (attemptCount <= MAX_NUMBER_OF_SERVER_UPDATE_ATTEMPTS && footage.done.boolValue != YES) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self updateServerAboutSuccessfulUploadFootage:footage attemptCount:attemptCount];
            });
        }
        return;
    }
    footage.done = @YES;
    HMGLogDebug(@"Updated server about successful upload %@", footage.takeID);
}

#pragma mark - Updating server
-(void)updateServerAboutUploadFootage:(Footage *)footage attemptCount:(NSInteger)attemptCount
{
    footage.done = @NO;
    // PUT FOOTAGE (on successful put, the upload will begin.
    // If failed to update the server about the upload, will attempt again after a delay.
    if ([HMServer.sh shouldUploaderReportUploads]) {
        HMGLogDebug(@"Will inform server about upload about to start: %@", footage.takeID);
        [HMServer.sh updateOnUploadStartFootageForRemakeID:footage.remake.sID
                                                   sceneID:footage.sceneID
                                                    takeID:[footage takeID]
                                              attemptCount:attemptCount
                                                  isSelfie:footage.rawIsSelfie.boolValue];
    }
}

-(void)updateServerAboutSuccessfulUploadFootage:(Footage *)footage attemptCount:(NSInteger)attemptCount
{
    // POST FOOTAGE (on successful put, the upload will begin.
    // If failed to update the server about the successful upload, will attempt again after a delay.
    Scene *scene = [footage.remake.story findSceneWithID:footage.sceneID];
    NSInteger resolution = scene.uploadedResolution?scene.uploadedResolution.integerValue:360;    
    if ([HMServer.sh shouldUploaderReportUploads]) {
        HMGLogDebug(@"Will inform server about upload success: %@", footage.takeID);
        [HMServer.sh updateOnSuccessFootageForRemakeID:footage.remake.sID
                                                   sceneID:footage.sceneID
                                                    takeID:[footage takeID]
                                              attemptCount:attemptCount
                                                  isSelfie:footage.rawIsSelfie.boolValue
                                            resolution:resolution
         ];
    }
}

#pragma mark - Manager actions
-(void)checkForUploads
{
    HMGLogDebug(@"Uploader checks if any uploads are pending...");
    [self checkForUploadsWithPrioritizedFootages:nil];
}

-(void)checkForUploadsWithPrioritizedFootages:(NSArray *)prioritizedFootages
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _checkForUploadsWithPrioritizedFootages:prioritizedFootages];
    });
}

-(void)_checkForUploadsWithPrioritizedFootages:(NSArray *)prioritizedFootages
{
    User *user = User.current;
    if (!user) return;
    
    NSFetchRequest *fetchRequest;
    NSError *error;
    NSArray *footages;
    
    //
    // Clean up first.
    // Check if some uploaded files upload state is inconsistent (can happen if user killed app in the middle of upload etc.)
    //
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_FOOTAGE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"currentlyUploaded=%@",@YES]; // All footages marked as currently uploading.
    error = nil;
    footages = [DB.sh.context executeFetchRequest:fetchRequest error:&error];
    if (!error) [self updateFootagesStateIfNotReallyCurrentlyUploading:footages];
    
    //
    // Bring all footages for this user, that have a rawLocalFile that is not the same as the uploaded file
    // (can happen on retakes of scenes already uploaded or if a raw file was never successfuly uploaded for this footage)
    //
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_FOOTAGE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.remake.user=%@ AND currentlyUploaded=%@ AND NOT SELF.rawLocalFile=SELF.rawUploadedFile",user,@NO];
    fetchRequest.fetchLimit = 10; // Limit to 10 footages at a time.
    error = nil;
    footages = [DB.sh.context executeFetchRequest:fetchRequest error:&error];
    if (footages.count==0) {
        HMGLogDebug(@"Uploader didn't find any new footages to upload...");
        return;
    }
    
    HMGLogDebug(@"Footages to upload:%ld",(long)footages.count);
    //
    // If footages to prioritize passed, put them at the top of the list.
    //
    if (prioritizedFootages) {
        footages  = [footages sortedArrayUsingComparator:^NSComparisonResult(id footage1, id footage2) {
            if ([footages containsObject:footage1]) return NSOrderedAscending;
            return NSOrderedDescending;
        }];
    }
    
    
    for (Footage *footage in footages)
    {
        [self updateServerAboutUploadFootage:footage attemptCount:1];
    }
}

-(void)updateFootagesStateIfNotReallyCurrentlyUploading:(NSArray *)footages
{
    NSInteger cleanedCount = 0;
    for (Footage *footage in footages) {
        if (![self isCurrentlyUploadingFootage:footage] && footage.currentlyUploaded) {
            footage.currentlyUploaded = @NO;
            cleanedCount++;
        }
    }
    if (cleanedCount>0) HMGLogDebug(@"%ld footages were marked as currently uploading, but had no related upload jobs. Fixed state." ,(long)cleanedCount);
}

-(void)uploadFootage:(Footage *)footage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _uploadFootage:footage];
    });
}

-(void)uploadFile:(NSString *)localFilePath
{
    return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _uploadFile:localFilePath];
    });
}

-(void)_uploadFootage:(Footage *)footage
{
    // No workers, no new jobs can be done.
    if (self.idleWorkersPool.count==0) return;
    if (!footage.rawLocalFileShouldBeUploaded) return;
    
    // Kick a lazy worker and send it to work.
    id<HMUploadWorkerProtocol>worker = [self popIdleWorker];
    if (!worker) return;
    
    // We have the worker and something to upload.
    // Let the work begin.
    footage.lastUploadAttemptTime = [NSDate date];
    [self putWorkerToWork:worker onFootage:footage];
}

-(void)_uploadFile:(NSString *)localFilePath
{
    //no workers available
    if (self.idleWorkersPool.count==0) return;
    
    // Kick a lazy worker and send it to work.
    id<HMUploadWorkerProtocol>worker = [self popIdleWorker];
    if (!worker) return;
    
    [self putWorkerToWork:worker onFile:localFilePath];
}

-(void)cancelUploadForFootage:(Footage *)footage
{
    id<HMUploadWorkerProtocol>worker = self.workersByFootageIdentifier[footage.identifier];
    if (!worker) return;
    HMGLogDebug(@"Canceled upload for footage:%@ with file:%@", footage.identifier, worker.source);
    [worker stopWorking];
    [self putWorkerToRest:worker];
}

-(void)cancelAllUploads
{
    for (Footage *footage in self.footagesByJobID.allValues) [self cancelUploadForFootage:footage];
}


-(id<HMUploadWorkerProtocol>)popIdleWorker
{
    id<HMUploadWorkerProtocol> worker = self.idleWorkersPool.allObjects.firstObject;
    [self.idleWorkersPool removeObject:worker];
    return worker;
}

-(void)putWorkerToWork:(id<HMUploadWorkerProtocol>)worker onFootage:(Footage *)footage
{
    HMGLogDebug(@"Uploading raw footage to %@", footage.rawVideoS3Key);
    
    // Initialize worker for new job.
    [worker newJobWithID:[[NSUUID UUID] UUIDString]
                  source:footage.rawLocalFile
             destination:footage.rawVideoS3Key
     ];
    
    // Set some user info about the job.
    [worker setUserInfo:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                        HM_INFO_REMAKE_ID:footage.remake,
                                                                        HM_INFO_SCENE_ID:footage.sceneID,
                                                                        HM_INFO_FOOTAGE_IDENTIFIER:footage.identifier, @"type" : @"footage"
                                                                        }]
     ];
    
    // Add some meta data about the job.
    worker.metaData = @{@"take_id":footage.takeID};
    
    if ([worker startWorking]) {
        self.busyWorkers[worker.jobID] = worker;
        self.footagesByJobID[worker.jobID] = footage;
        self.workersByFootageIdentifier[footage.identifier] = worker;
        footage.currentlyUploaded = @YES;
    } else {
        // Failed. Put the worker back in the pool.
        [self.idleWorkersPool addObject:worker];
    }
}

-(void)putWorkerToWork:(id<HMUploadWorkerProtocol>)worker onFile:(NSString *)localFilePath
{
    NSString *destinationPath = @"Temp/ProcessBackgroundException/";
    NSString *fileName = [localFilePath lastPathComponent];
    NSString *destination = [destinationPath stringByAppendingString:fileName];

    HMGLogDebug(@"Uploading new file to %@" , destination);
    
    [worker newJobWithID:[[NSUUID UUID] UUIDString]
                  source:localFilePath
             destination:destination];
    
    [worker setUserInfo:[NSMutableDictionary dictionaryWithDictionary:@{@"type" : @"file"}]];
    
    if ([worker startWorking]) {
        self.busyWorkers[worker.jobID] = worker;
    } else {
        // Failed. Put the worker back in the pool.
        [self.idleWorkersPool addObject:worker];
    }
}

-(void)putWorkerToRest:(id<HMUploadWorkerProtocol>)worker
{
    Footage *footage = self.footagesByJobID[worker.jobID];
    [self.busyWorkers removeObjectForKey:worker.jobID];
    [self.footagesByJobID removeObjectForKey:worker.jobID];
    [self.workersByFootageIdentifier removeObjectForKey:footage.identifier];
    [self.idleWorkersPool addObject:worker];
    footage.currentlyUploaded = @NO;
}

-(BOOL)isCurrentlyUploadingFootage:(Footage *)footage
{
    if (self.workersByFootageIdentifier[footage.identifier]) return YES;
    return NO;
}

#pragma mark - Manager delegate
-(void)worker:(id)worker reportingFinishedWithSuccess:(BOOL)success info:(NSDictionary *)info
{
    id<HMUploadWorkerProtocol>aWorker = (id<HMUploadWorkerProtocol>)worker;
    
    Footage *footage = self.footagesByJobID[aWorker.jobID];
    
    //TODO: make this nicer
    if (!footage)
    {
        //probably a file
        return;
    }
    
    // We are not interested in canceled jobs. The rawLocalFile and the source uploaded, must be the same.
    if (![footage.rawLocalFile isEqualToString:aWorker.source]) return;
    
    // Update the footage about success / failure
    if (success) {
        footage.rawUploadedFile = aWorker.source;

        // Updating server about successful upload
        [self updateServerAboutSuccessfulUploadFootage:footage attemptCount:1];
        
        // This worker earned his day pay
        // Put the worker to rest
        [self putWorkerToRest:worker];
        
    } else {
        
        // This worker failed to do the job.
        footage.uploadsFailedCounter = @(footage.uploadsFailedCounter.integerValue + 1);
        [self putWorkerToRest:worker];
        
    }
    
    // If an internet connection is currently available, check if more file should be uploaded.
    if (HMServer.sh.isReachable) [self checkForUploads];
}

-(void)worker:(id)worker reportingProgress:(double)progress info:(NSDictionary *)info
{
    
    NSString *type = [[worker userInfo] objectForKey:@"type"];
    
    if ([type isEqualToString:@"file"])
    {
        return;
    }
    
    //
    // Notify about the progress made
    //
    NSString *remakeID = [[worker userInfo] objectForKey:HM_INFO_REMAKE_ID];
    NSNumber *sceneID = [[worker userInfo] objectForKey:HM_INFO_SCENE_ID];
    NSNumber *footageIdentifier = [[worker userInfo] objectForKey:HM_INFO_FOOTAGE_IDENTIFIER];
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UPLOAD_PROGRESS
                                                        object:self
                                                      userInfo:@{
                                                                 HM_INFO_REMAKE_ID:remakeID,
                                                                 HM_INFO_SCENE_ID:sceneID,
                                                                 HM_INFO_FOOTAGE_IDENTIFIER:footageIdentifier,
                                                                 HM_INFO_PROGRESS:@(progress)
                                                                 }];
}



@end
