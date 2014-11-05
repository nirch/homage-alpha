//
//  Footage.m
//  Homage
//
//  Created by Aviv Wolf on 10/30/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage.h"
#import "Remake.h"


@implementation Footage

@dynamic currentlyUploaded;
@dynamic lastUploadAttemptTime;
@dynamic lastUploadFailedErrorDescription;
@dynamic processedVideoS3Key;
@dynamic rawLocalFile;
@dynamic rawUploadedFile;
@dynamic rawVideoS3Key;
@dynamic sceneID;
@dynamic status;
@dynamic uploadsFailedCounter;
@dynamic done;
@dynamic remake;

@end
