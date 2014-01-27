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

@interface HMUploadManager()

@property (nonatomic, readonly) NSMutableSet *idleWorkersPool;
@property (nonatomic, readonly) NSMutableDictionary *busyWorkers;
@property (nonatomic, readonly) NSMutableDictionary *uploadedFootages;

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
        _uploadedFootages = [NSMutableDictionary new];
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
    [self checkForUploads];
    [self initObservers];
}

-(void)stopMonitoring
{
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe refetching of remakes
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChanged:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:nil];
}

#pragma mark - Observers handlers
-(void)onReachabilityStatusChanged:(NSNotification *)notification
{
    if (HMServer.sh.isReachable) {
        [self checkForUploads];
    }
}

#pragma mark - Manager actions
-(void)checkForUploads
{
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
    
    
    
    //
    // Bring all footages for this user, that have open status.
    //
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_FOOTAGE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.remake.user=%@ AND status=%@ AND newRawLocalFileWaitingForUpload=%@",user,@(HMFootageStatusStatusOpen),@YES];
    fetchRequest.fetchLimit = 10; // Limit to 10 footages at a time.
    NSError *error;
    NSArray *footages = [DB.sh.context executeFetchRequest:fetchRequest error:&error];
    
    if (prioritizedFootages) {
        footages  = [footages sortedArrayUsingComparator:^NSComparisonResult(id footage1, id footage2) {
            if ([footages containsObject:footage1]) return NSOrderedAscending;
            return NSOrderedDescending;
        }];
    }
    
    for (Footage *footage in footages) [self checkFootage:footage];
}

-(void)checkFootage:(Footage *)footage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _checkFootage:footage];
    });
}

-(void)_checkFootage:(Footage *)footage
{
    if (self.idleWorkersPool.count==0) return;
    if (!footage.needsToStartUpload) return;
    
    // Get a lazy worker to work.
    id<HMUploadWorkerProtocol>worker = [self popIdleWorker];
    if (!worker) return;
    
    // We have the worker and something to upload.
    // Let the work begin.
    footage.newRawLocalFileWaitingForUpload = @NO;
    footage.lastUploadAttemptTime = [NSDate date];
    [self putWorkerToWork:worker onFootage:footage];
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
    [worker newJobWithID:[[NSUUID UUID] UUIDString]
                  source:footage.rawLocalFile
             destination:footage.rawVideoS3Key
     ];
    [worker setUserInfo:[NSMutableDictionary dictionaryWithDictionary:@{
                                                                        HM_INFO_REMAKE_ID:footage.remake,
                                                                        HM_INFO_SCENE_ID:footage.sceneID
                                                                        }]
     ];
    self.busyWorkers[worker.jobID] = worker;
    self.uploadedFootages[worker.jobID] = footage;
    [worker startWorking];
}

-(void)putWorkerToRest:(id<HMUploadWorkerProtocol>)worker
{
    [self.busyWorkers removeObjectForKey:worker.jobID];
    [self.uploadedFootages removeObjectForKey:worker.jobID];
    [self.idleWorkersPool addObject:worker];
}

-(void)updateServerAboutSuccessfulUploadForFootage:(Footage *)footage
{
    [HMServer.sh updateFootageForRemakeID:footage.remake.sID sceneID:footage.sceneID];
}

#pragma mark - Manager delegate
-(void)worker:(id)worker reportingFinishedWithSuccess:(BOOL)success info:(NSDictionary *)info
{
    id<HMUploadWorkerProtocol>aWorker = (id<HMUploadWorkerProtocol>)worker;
    
    // Find the related footage in the upload footages dictionary
    Footage *footage = self.uploadedFootages[aWorker.jobID];
    
    // Update the footage about success / failure
    if (success) {
        
        footage.newRawLocalFileWaitingForUpload = @NO;
        [self updateServerAboutSuccessfulUploadForFootage:footage];
        
        // This worker earned his day pay
        // Put the worker to rest
        [self putWorkerToRest:worker];
        
    } else {
        
        // This worker failed to do the job.
        // Mark the footage that it still needs to be uploaded.
        footage.newRawLocalFileWaitingForUpload = @YES;
        [self putWorkerToRest:worker]; // TODO: schedule retry attempts
        
    }


}

-(void)worker:(id)worker reportingProgress:(double)progress info:(NSDictionary *)info
{
    //
    // Notify about the progress made
    //
    NSString *remakeID = [[worker userInfo] objectForKey:HM_INFO_REMAKE_ID];
    NSNumber *sceneID = [[worker userInfo] objectForKey:HM_INFO_SCENE_ID];
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_UPLOAD_PROGRESS
                                                        object:self
                                                      userInfo:@{
                                                                 HM_INFO_REMAKE_ID:remakeID,
                                                                 HM_INFO_SCENE_ID:sceneID,
                                                                 HM_INFO_PROGRESS:@(progress)
                                                                 }
     ];
}

@end
