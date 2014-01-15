//
//  HMRecorderChildInterface.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakerProtocol.h"

@protocol HMRecorderChildInterface <NSObject>

@property (nonatomic) id<HMRemakerProtocol>remakerDelegate;

@end
