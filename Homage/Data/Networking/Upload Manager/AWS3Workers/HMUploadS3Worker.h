//
//  HMUploadS3Worker.h
//  Homage
//
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUploadManagerDelegate.h"
#import "HMUploadWorkerProtocol.h"
#import "HMAWS3Client.h"

@interface HMUploadS3Worker : NSObject<HMUploadWorkerProtocol, AmazonServiceRequestDelegate>

@property (nonatomic, weak) id<HMUploadManagerDelegate>manager;

+(NSSet *)instantiateWorkers:(NSInteger)numberOfWorkers;

@end
