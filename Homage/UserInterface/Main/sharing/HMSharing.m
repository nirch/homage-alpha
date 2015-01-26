//
//  HMSharing.m
//  Homage
//
//  Created by Aviv Wolf on 10/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSharing.h"
#import "DB.h"
#import "HMServer.h"
#import "HMServer+analytics.h"
#import "HMServer+AppConfig.h"
#import "JBWhatsAppActivity.h"
#import "mixPanel.h"
#import "HMSaveToDeviceActivity.h"
#import <FacebookSDK/FacebookSDK.h>
#import "HMCacheManager.h"

@interface HMSharing() <
    UIDocumentInteractionControllerDelegate
>

@property (weak) UIActivityViewController *activityViewController;
@property (nonatomic) UIDocumentInteractionController *documentInteractionController;
@property (nonatomic) NSDictionary *shareBundle;
@property (nonatomic) NSString *application;
@property (nonatomic) NSNumber *shareMethod;


@end

@implementation HMSharing

-(id)init
{
    self = [super init];
    if (self) {
        self.image = nil;
        self.shareAsFile = NO;
    }
    return self;
}

#pragma mark sharing
-(NSDictionary *)generateShareBundleForRemake:(Remake *)remake
                               trackEventName:(NSString *)trackEventName
                            originatingScreen:(NSNumber *)originatingScreen
{
    
    // The dictionary holding the generated share info.
    NSMutableDictionary *shareBundle = [NSMutableDictionary new];
    
    // Build the remake share URL
    NSString *storyNameWithoutSpaces = [remake.story.name stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *shareLinkPrefix = [HMServer.sh getShareLinkPrefix];
    NSString *shareID = [HMServer.sh generateBSONID];
    NSString *remakeShareURL = [NSString stringWithFormat:@"%@/%@" , shareLinkPrefix , shareID];
    
    // Build share subject and body
    NSString *generalShareSubject;
    NSString *whatsAppShareString;
    if (remake.story.shareMessage)
    {
        generalShareSubject = remake.story.shareMessage;
        whatsAppShareString = [NSString stringWithFormat:LS(@"SHARE_MSG_BODY") ,remake.story.shareMessage , remakeShareURL];
    } else {
        generalShareSubject = [NSString stringWithFormat:LS(@"DEFAULT_SHARE_MSG_SUBJECT") , remake.story.name];
        whatsAppShareString = [NSString stringWithFormat:LS(@"DEFUALT_SHARE_MSG_BODY") , remake.story.name , remakeShareURL];
    }
    
    // General share body.
    NSString *generalShareBody = [whatsAppShareString stringByAppendingString:[NSString stringWithFormat:LS(@"SHARE_MSG_BODY_HASHTAGS") , storyNameWithoutSpaces, storyNameWithoutSpaces]];
    
    //
    // Build the bundle and return it
    //
    shareBundle[K_SHARE_ID] = shareID;
    shareBundle[K_REMAKE_ID] = remake.sID;
    shareBundle[K_REMAKE_OWNER_ID] = remake.user.userID;
    shareBundle[K_STORY_NAME] = remake.story.name;
    shareBundle[K_USER_ID] = [User current].userID;
    shareBundle[K_SHARE_URL] = remakeShareURL;
    shareBundle[K_SHARE_SUBJECT] = generalShareSubject;
    shareBundle[K_SHARE_BODY] = generalShareBody;
    shareBundle[K_WHATS_APP_MESSAGE] = whatsAppShareString;
    shareBundle[K_ORIGINATING_SCREEN] = originatingScreen;
    shareBundle[K_TRACK_EVENT_NAME] = trackEventName;
    
    if (remake.isVideoAvailableLocally && self.shareAsFile) {
        shareBundle[K_REMAKE_LOCAL_VIDEO_URL] = [HMCacheManager.sh urlForCachedResource:remake.videoURL
                                                                              cachePath:HMCacheManager.sh.remakesCachePath];
        
    }
    
    return shareBundle;
}

-(void)requestShareWithBundle:(NSDictionary *)shareBundle
{
    NSString *shareID = shareBundle[K_SHARE_ID];
    NSString *remakeID = shareBundle[K_REMAKE_ID];
    NSString *remakeShareURL = shareBundle[K_SHARE_URL];
    NSNumber *originatingScreen = shareBundle[K_ORIGINATING_SCREEN];
    [HMServer.sh requestShare:shareID
                    forRemake:remakeID
                       userID:[User current].userID
                    shareLink:remakeShareURL
            originatingScreen:originatingScreen
                         info:shareBundle];
}

-(void)shareRemakeBundle:(NSDictionary *)shareBundle
                parentVC:(UIViewController *)parentVC
          trackEventName:(NSString *)trackEventName
               thumbnail:(UIImage *)thumbnail
              sourceView:(UIView *)sourceView
{
    // Gather info about the share
    self.shareBundle = shareBundle;
    NSString *generalShareSubject = shareBundle[K_SHARE_SUBJECT];
    NSString *generalShareBody =    shareBundle[K_SHARE_BODY];
    NSURL *videoFileURL = shareBundle[K_REMAKE_LOCAL_VIDEO_URL];

    // Whatsapp message
    NSString *whatAppMessage = shareBundle[K_WHATS_APP_MESSAGE];

    // Create the activity items array.
    NSMutableArray *activityItems = [NSMutableArray new];

    // General share body
    if (self.shareAsFile) {
        if (videoFileURL) {
            [activityItems addObject:videoFileURL];
        }
    } else {
        
        // Text for the share as link message.
        if (generalShareBody) {
            [activityItems addObject:generalShareBody];
        }

        // Whatsapp
        if (whatAppMessage) {
            [activityItems addObject:[[WhatsAppMessage alloc] initWithMessage:whatAppMessage forABID:nil]];
        }

        // Thumbnail
        if (thumbnail) {
            [activityItems addObject:thumbnail];
        }
    }
    
    // Application activities.
    NSMutableArray *applicationActivities = [NSMutableArray new];

    // Whatsapp activity.
    [applicationActivities addObject:[JBWhatsAppActivity new]];

    
    // The activityViewController
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                         applicationActivities:applicationActivities];

    self.activityViewController = activityViewController;
    
    activityViewController.completionWithItemsHandler = ^(NSString *activityType,
                                                          BOOL completed,
                                                          NSArray *returnedItems,
                                                          NSError *activityError) {
        
        // Share method
        NSNumber *shareMethod = [self getShareMethod:activityType];

        // Report to the server.
        [HMServer.sh reportShare:shareBundle[K_SHARE_ID]
                          userID:shareBundle[K_USER_ID]
                       forRemake:shareBundle[K_REMAKE_ID]
                     shareMethod:shareMethod
                    shareSuccess:completed
                     application:activityType
                            info:shareBundle];

        // Report to mixpanel
        if (activityType) {
            NSDictionary *trackProperties = @{
                                              @"story" : shareBundle[K_STORY_NAME] ,
                                              @"share_method" : activityType,
                                              @"remake_id" : shareBundle[K_REMAKE_ID],
                                              @"user_id" : shareBundle[K_USER_ID],
                                              @"remake_owner_id": shareBundle[K_REMAKE_OWNER_ID],
                                              @"originating_screen": shareBundle[K_ORIGINATING_SCREEN]
                                              };
            [[Mixpanel sharedInstance] track:trackEventName properties:trackProperties];
        }
        
        [self.delegate sharingDidFinishWithShareBundle:shareBundle];
    };

    [activityViewController setValue:generalShareSubject forKey:@"subject"];
    activityViewController.excludedActivityTypes = @[
                                                     UIActivityTypePrint,
                                                     UIActivityTypeAssignToContact,
                                                     UIActivityTypeSaveToCameraRoll,
                                                     UIActivityTypeAddToReadingList,
                                                     UIActivityTypeCopyToPasteboard,
                                                     UIActivityTypeAirDrop
                                                     ];

    if (IS_IPAD && sourceView) {
        activityViewController.popoverPresentationController.sourceView = sourceView;
    }


    dispatch_async(dispatch_get_main_queue(), ^{
        [parentVC presentViewController:activityViewController animated:YES completion:^{}];
    });

}

-(void)shareVideoFileInRemakeBundle:(NSDictionary *)shareBundle
                           parentVC:(UIViewController *)parentVC
                     trackEventName:(NSString *)trackEventName
                         sourceView:(UIView *)sourceView
{
    NSURL *url = shareBundle[K_REMAKE_LOCAL_VIDEO_URL];
    NSString *path = [url path];
    self.shareBundle = shareBundle;

    // Temp resource url
    NSError *error;
    NSString *tempPath = [self tempPathAndMakeSureToCleanFileIfExists];
    NSURL *tempURL = [NSURL fileURLWithPath:tempPath];
    
    // Copy resource file to temp file.
    if ( [[NSFileManager defaultManager] isReadableFileAtPath:path] ) {
        error = nil;
        [[NSFileManager defaultManager] copyItemAtURL:url toURL:tempURL error:&error];
        
        if (error) {
            
        } else {
            self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:tempURL];
            self.documentInteractionController.delegate = self;
            [self.documentInteractionController presentOpenInMenuFromRect:CGRectZero inView:parentVC.view animated:YES];
        }
    }
}

-(NSString *)tempPathAndMakeSureToCleanFileIfExists
{
    NSString *tempPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/temp.mp4"];
    // Delete old temp file if exists.
    if ( [[NSFileManager defaultManager] isReadableFileAtPath:tempPath] ) {
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    }
    return tempPath;
}


-(NSNumber *)getShareMethod:(NSString *)activityType
{
    if ([activityType isEqualToString:@"com.apple.UIKit.activity.CopyToPasteboard"])
        return @(HMShareMethodCopyToPasteboard);
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToFacebook"])
        return @(HMShareMethodPostToFacebook);
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToWhatsApp"])
        return @(HMShareMethodPostToWhatsApp);
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.Mail"])
        return @(HMShareMethodEmail);
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.Message"])
        return @(HMShareMethodMessage);
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToWeibo"])
        return @(HMShareMethodPostToWeibo);
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToTwitter"])
        return @(HMShareMethodPostToTwitter);
    else if ([activityType isEqualToString:[NSString stringWithFormat:@"%@.DownloadVideoToDeviceActivity", [[NSBundle mainBundle] bundleIdentifier]]])
        return @(HMShareMethodSaveToCameraRoll);
    else return @(999);
}

#pragma mark - UIDocumentInteractionControllerDelegate
-(void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    if (application)
        self.application = application;

    // Report to the server.
    NSDictionary *shareBundle = self.shareBundle;
    [HMServer.sh reportShare:shareBundle[K_SHARE_ID]
                      userID:shareBundle[K_USER_ID]
                   forRemake:shareBundle[K_REMAKE_ID]
                 shareMethod:@(HMShareMethodSendOrUploadVideoFile)
                shareSuccess:YES
                 application:self.application? self.application:@"unknown"
                        info:shareBundle];
    
    // Track the event to mixpanel
    NSDictionary *trackProperties = @{
                                      @"story" : shareBundle[K_STORY_NAME] ,
                                      @"share_method" : @(HMShareMethodSendOrUploadVideoFile),
                                      @"remake_id" : shareBundle[K_REMAKE_ID],
                                      @"user_id" : shareBundle[K_USER_ID],
                                      @"remake_owner_id": shareBundle[K_REMAKE_OWNER_ID],
                                      @"originating_screen": shareBundle[K_ORIGINATING_SCREEN]
                                      };
    
    NSString *trackEventName = self.shareBundle[K_TRACK_EVENT_NAME];
    [[Mixpanel sharedInstance] track:trackEventName properties:trackProperties];
    
    // Cleanup and finishup
    self.shareBundle = nil;
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    if (application)
        self.application = application;
}

@end
