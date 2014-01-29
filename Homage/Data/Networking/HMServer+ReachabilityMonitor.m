//
//  HMServer+ReachabilityMonitor.m
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+ReachabilityMonitor.h"
#import "HMNotificationCenter.h"

@implementation HMServer (ReachabilityMonitor)

-(void)startMonitoringReachability
{
    [self.session.reachabilityManager startMonitoring];
    __weak HMServer *weakSelf = self;
    [self.session.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:weakSelf userInfo:@{@"status": @(status)}];;
        switch (status) {
                case AFNetworkReachabilityStatusNotReachable:
                    HMGLogDebug(@"Reachability: NO Internet Connection");
                    break;

                case AFNetworkReachabilityStatusReachableViaWiFi:
                    HMGLogDebug(@"Reachability: YES WIFI");
                    break;

                case AFNetworkReachabilityStatusReachableViaWWAN:
                    HMGLogDebug(@"Reachability: YES 3G");
                break;
            default:
                HMGLogDebug(@"Reachability: unknown");
                break;
        }
    }];
}

-(void)stopMonitoringReachability
{
    [self.session.reachabilityManager stopMonitoring];
}

-(BOOL)isReachable
{
    return self.session.reachabilityManager.reachable;
}

-(AFNetworkReachabilityStatus)reachabilityStatus
{
    return self.session.reachabilityManager.networkReachabilityStatus;
}

@end
