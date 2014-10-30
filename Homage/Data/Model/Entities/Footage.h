//
//  Footage.h
//  Homage
//
//  Created by Aviv Wolf on 10/30/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Remake;

@interface Footage : NSManagedObject

@property (nonatomic, retain) NSNumber * currentlyUploaded;
@property (nonatomic, retain) NSDate * lastUploadAttemptTime;
@property (nonatomic, retain) id lastUploadFailedErrorDescription;
@property (nonatomic, retain) NSString * processedVideoS3Key;
@property (nonatomic, retain) NSString * rawLocalFile;
@property (nonatomic, retain) NSString * rawUploadedFile;
@property (nonatomic, retain) NSString * rawVideoS3Key;
@property (nonatomic, retain) NSNumber * sceneID;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSNumber * uploadsFailedCounter;
@property (nonatomic, retain) NSNumber * done;
@property (nonatomic, retain) Remake *remake;

@end
