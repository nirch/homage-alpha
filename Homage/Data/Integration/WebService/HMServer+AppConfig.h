//
//  HMServer+AppConfig.h
//  Homage
//
//  Created by Yoav Caspin on 10/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer(AppConfig)

#pragma mark - Init config
-(void)loadAdditionalConfig;

#pragma mark - Login
typedef NS_ENUM(NSInteger, HMLoginFlowType) {
    HMLoginFlowTypeNormal,                  // Login screen. Allows user email, facebook or guest login.
    HMLoginFlowTypeAutoGuestLogin           // Skips login screen (Auto Login as guest)
};

#pragma mark - User save to device policy
typedef NS_ENUM(NSInteger, HMUserSaveToDevicePolicy) {
    HMUserSaveToDevicePolicyNotAllowed,     // Not allowed to save to camera roll.
    HMUserSaveToDevicePolicyAllowed,        // User can save remakes to camera roll freely.
    HMUserSaveToDevicePolicyPremium         // User can save remakes to camera roll at a price (in app purchases must be turned on).
};

/**
 *  Login flow type. The defailt is 0 (HMLoginFlowTypeNormal)
 *
 *  @return HMLoginFlowType value as defined in config.
 */
-(HMLoginFlowType)loginFlowType;

#pragma mark - Sharing
/**
 *  The prefix of share links defined in config.
 *
 *  @return NSString of the prefix of the share url aws defined in config.
 */
-(NSString *)getShareLinkPrefix;

#pragma mark - Recorder
/**
 *  Setting determining if flip to horizontally the silhouete on client side when shooting a selfie.
 *
 *  @return YES if mirror_selfie_silhouette is set to true. default is NO.
 */
-(BOOL)shouldMirrorSelfieSilhouette;

/**
 *  Setting determining if to show a message screen before shooting the first scene.
 *
 *  @return YES if recorder_first_scene_context_message was set to true. default is YES.
 */
-(BOOL)shouldShowFirstSceneContextMessage;

#pragma mark - Campaign
/**
 *  the campaign_id set for this application.
 *
 *  @return an NSString identifying the campaign related to this app.
 */
-(NSString *)campaignID;

#pragma mark - Store
-(NSString *)productsPrefix;

/**
 *  Setting determining if the upload manager reports start/finished uploads
 *
 *
 *  @return YES if should report to server on start/finished uploads.
 */
-(BOOL)shouldUploaderReportUploads;

/**
 *  YES if possible to buy premium content in app.
 *
 *  @return YES/NO if premium content should be purchased before used by user.
 */
-(BOOL)supportsInAppPurchases;

/**
 *  Setting determining if to show premium stories or not in the stories feed.
 *
 *  @return YES if set to hide premium stories (NO by default).
 */
-(BOOL)shouldHidePremiumStories;

#pragma mark - FaceBook
-(NSString *)facebookAppID;

@end
