//
//  HMUploadManager.h
//  Homage
//
//  Created by Aviv Wolf on 1/18/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <AWSRuntime/AWSRuntime.h>
#import <AWSS3/AWSS3.h>

@interface HMUploadManager : NSObject<AmazonServiceRequestDelegate>

@property (nonatomic, strong) S3TransferManager *tm;

// HMUploadManager is a singleton
+(HMUploadManager *)sharedInstance;

// Just an alias for sharedInstance for shorter writing.
+(HMUploadManager *)sh;



@end
