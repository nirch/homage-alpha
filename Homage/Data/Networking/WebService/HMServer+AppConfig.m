//
//  HMServer+Info.m
//  Homage
//
//  Created by Yoav Caspin on 10/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+AppConfig.h"
#import "HMNotificationCenter.h"
#import "HMConfigurationParser.h"

@implementation HMServer (AppConfig)

#pragma mark - Init config
-(void)loadAdditionalConfig
{
    [self getRelativeURLNamed:@"additional config" parameters:nil notificationName:HM_NOTIFICATION_SERVER_CONFIG info:nil parser:[HMConfigurationParser new]];
}

#pragma mark - Login
-(HMLoginFlowType)loginFlowType
{
    return [self.configurationInfo[@"login_flow_type"] integerValue];
}

#pragma mark - Sharing
-(NSString *)getShareLinkPrefix
{
    return [self.configurationInfo[@"share_link_prefix"] stringValue];
}

#pragma mark - Recorder
-(BOOL)shouldMirrorSelfieSilhouette
{
    NSNumber *should = self.configurationInfo[@"mirror_selfie_silhouette"];
    if (!should) return NO;
    return should.boolValue;
}

-(BOOL)shouldShowFirstSceneContextMessage
{
    NSNumber *should = self.configurationInfo[@"recorder_first_scene_context_message"];
    if (!should) return YES;
    return should.boolValue;
}

-(NSString *)campaignID
{
    NSString *campaignIDString = self.configurationInfo[@"campaign_id"];
    return campaignIDString;
}

-(BOOL)shouldUploaderReportUploads
{
    NSNumber *should = self.configurationInfo[@"uploader_reports_uploads"];
    if (!should) return YES;
    return should.boolValue;
}

@end
