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

#pragma mark - Boolean values
-(BOOL)should:(NSString *)key withDefault:(BOOL)defaultValue
{
    NSNumber *should = self.configurationInfo[key];
    if (!should) return defaultValue;
    return should.boolValue;
}

#pragma mark - Login
-(HMLoginFlowType)loginFlowType
{
    return [self.configurationInfo[@"login_flow_type"] integerValue];
}

-(BOOL)loginFlowSkipIntroVideo
{
    return [self should:@"login_flow_skip_intro_video" withDefault:NO];
}


#pragma mark - Sharing
-(NSString *)getShareLinkPrefix
{
    return [self.configurationInfo[@"share_link_prefix"] stringValue];
}

#pragma mark - Recorder
-(BOOL)shouldMirrorSelfieSilhouette
{
    return [self should:@"mirror_selfie_silhouette" withDefault:NO];
}

-(BOOL)shouldShowFirstSceneContextMessage
{
    return [self should:@"recorder_first_scene_context_message" withDefault:YES];
}

-(NSString *)campaignID
{
    NSString *campaignIDString = self.configurationInfo[@"campaign_id"];
    return campaignIDString;
}

-(BOOL)shouldUploaderReportUploads
{
    return [self should:@"uploader_reports_uploads" withDefault:YES];
}

#pragma mark - In app purchases
-(BOOL)supportsInAppPurchases
{
    return [self should:@"in_app_purchases" withDefault:NO];
}

-(BOOL)shouldHidePremiumStories
{
    return [self should:@"in_app_purchases_hide_premium_stories" withDefault:NO];
}

@end
