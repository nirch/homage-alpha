//
//  HMServer+Info.m
//  Homage
//
//  Created by Yoav Caspin on 10/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Info.h"
#import "HMNotificationCenter.h"
#import "HMConfigurationParser.h"

@implementation HMServer (Info)

-(void)loadAdditionalConfig
{
    [self getRelativeURLNamed:@"additional config" parameters:nil notificationName:HM_NOTIFICATION_SERVER_CONFIG info:nil parser:[HMConfigurationParser new]];
}

-(NSString *)getShareLinkPrefix
{
    return self.configurationInfo[@"share_link_prefix"];
}

-(BOOL)shouldMirrorSelfieSilhouette
{
    NSNumber *should = self.configurationInfo[@"mirrorSelfieSilhouette"];
    if (!should) return NO;
    return should.boolValue;
}

@end
