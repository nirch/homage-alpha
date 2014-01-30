//
//  HMServer+ReachabilityMonitor.h
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

typedef NS_ENUM(NSInteger, HMNetworkReachabilityStatus) {
    HMNetworkReachabilityStatusUnknown          = -1,
    HMNetworkReachabilityStatusNotReachable     = 0,
    HMNetworkReachabilityStatusReachableViaWWAN = 1,
    HMNetworkReachabilityStatusReachableViaWiFi = 2,
};

@interface HMServer (ReachabilityMonitor)

-(void)startMonitoringReachability;
-(void)stopMonitoringReachability;
-(BOOL)isReachable;
-(AFNetworkReachabilityStatus)reachabilityStatus;

@end
