//
//  HMUploadS3Worker.h
//  Homage
//
//  Created by Aviv Wolf on 10/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMUploadManagerDelegate.h"
#import "HMUploadWorkerProtocol.h"
#import "HMAWS3Client.h"

@interface HMUploadS3Worker : NSObject<
    HMUploadWorkerProtocol
>

@property (nonatomic, weak) id<HMUploadManagerDelegate>manager;

+(NSSet *)instantiateWorkers:(NSInteger)numberOfWorkers;

@end
