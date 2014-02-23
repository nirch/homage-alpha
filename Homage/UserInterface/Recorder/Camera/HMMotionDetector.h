//
//  HMMotionDetector.h
//  Homage
//
//  Created by Yoav Caspin on 2/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMMotionDetectorDelegate.h"

@interface HMMotionDetector : NSObject

@property id<HMMotionDetectorDelegate> delegate;
+(HMMotionDetector *)sharedInstance;
+(HMMotionDetector *)sh;

-(void)start;
-(void)stop;

@end
