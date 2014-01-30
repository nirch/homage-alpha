//
//  Footage.m
//  Homage
//
//  Created by Aviv Wolf on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage.h"
#import "Remake.h"


@implementation Footage

@dynamic lastUploadAttemptTime;
@dynamic lastUploadFailedErrorDescription;
@dynamic newRawLocalFileWaitingForUpload;
@dynamic processedVideoS3Key;
@dynamic rawLocalFile;
@dynamic rawVideoS3Key;
@dynamic sceneID;
@dynamic status;
@dynamic successfulyUploadedRawLocalFile;
@dynamic remake;

@end
