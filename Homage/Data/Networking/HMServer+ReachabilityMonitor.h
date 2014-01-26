//
//  HMServer+ReachabilityMonitor.h
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (ReachabilityMonitor)

-(void)startMonitoringReachability;
-(BOOL)isReachable;
-(AFNetworkReachabilityStatus)reachabilityStatus;

@end
