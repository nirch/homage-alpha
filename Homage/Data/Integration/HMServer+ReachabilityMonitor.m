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
        switch (status) {
                case AFNetworkReachabilityStatusNotReachable:
                    HMGLogDebug(@"Reachability: NO Internet Connection");
                    weakSelf.connectionLabel = @"";
                    break;

                case AFNetworkReachabilityStatusReachableViaWiFi:
                    HMGLogDebug(@"Reachability: YES WIFI");
                    weakSelf.connectionLabel = @"wifi";
                    break;

                case AFNetworkReachabilityStatusReachableViaWWAN:
                    HMGLogDebug(@"Reachability: YES 3G");
                    weakSelf.connectionLabel = @"wan";
                break;
            default:
                HMGLogDebug(@"Reachability: unknown");
                break;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                            object:weakSelf
                                                          userInfo:@{@"status": @(status)}];;
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
