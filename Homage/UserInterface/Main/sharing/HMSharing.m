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
#import "HMServer+Info.h"
#import "JBWhatsAppActivity.h"
#import "mixPanel.h"

@implementation HMSharing

#pragma mark sharing
-(NSDictionary *)generateShareBundleForRemake:(Remake *)remake
                               trackEventName:(NSString *)trackEventName
                            originatingScreen:(NSNumber *)originatingScreen {
    
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
               thumbnail:(UIImage *)thumbnail {

    // Gather info about the share
    NSString *generalShareSubject = shareBundle[K_SHARE_SUBJECT];
    NSString *generalShareBody =    shareBundle[K_SHARE_BODY];
    
    
    // Whatsapp message
    NSString *whatAppMessage = shareBundle[K_WHATS_APP_MESSAGE];
    
    // Create the activity items array.
    NSMutableArray *activityItems = [NSMutableArray new];
    if (generalShareBody) [activityItems addObject:generalShareBody];
    if (whatAppMessage) [activityItems addObject:[[WhatsAppMessage alloc] initWithMessage:whatAppMessage forABID:nil]];
    if (thumbnail) [activityItems addObject:thumbnail];

    //
    NSArray *applicationActivities = @[[[JBWhatsAppActivity alloc] init]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        NSNumber *shareMethod = [self getShareMethod:activityType];

        // Report to the server.
        [HMServer.sh reportShare:shareBundle[K_SHARE_ID]
                          userID:shareBundle[K_USER_ID]
                       forRemake:shareBundle[K_REMAKE_ID]
                     shareMethod:shareMethod
                    shareSuccess:completed
                            info:shareBundle];
        
        // Mixpanel report.
        if (completed) {
            NSDictionary *trackProperties = @{
                                              @"story" : shareBundle[K_STORY_NAME] ,
                                              @"share_method" : activityType ,
                                              @"remake_id" : shareBundle[K_REMAKE_ID],
                                              @"user_id" : shareBundle[K_USER_ID],
                                              @"remake_owner_id": shareBundle[K_REMAKE_OWNER_ID],
                                              @"originating_screen": shareBundle[K_ORIGINATING_SCREEN]
                                              };
            [[Mixpanel sharedInstance] track:trackEventName properties:trackProperties];
        }
    };

    [activityViewController setValue:generalShareSubject forKey:@"subject"];
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList];
    dispatch_async(dispatch_get_main_queue(), ^{
        [parentVC presentViewController:activityViewController animated:YES completion:^{}];
    });

}

-(NSNumber *)getShareMethod:(NSString *)activityType
{
    if ([activityType isEqualToString:@"com.apple.UIKit.activity.CopyToPasteboard"])
        return [NSNumber numberWithInt:HMShareMethodCopyToPasteboard];
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToFacebook"])
        return [NSNumber numberWithInt:HMShareMethodPostToFacebook];
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToWhatsApp"])
        return [NSNumber numberWithInt:HMShareMethodPostToWhatsApp];
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.Mail"])
        return [NSNumber numberWithInt:HMShareMethodEmail];
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.Message"])
        return [NSNumber numberWithInt:HMShareMethodMessage];
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToWeibo"])
        return [NSNumber numberWithInt:HMShareMethodPostToWeibo];
    else if ([activityType isEqualToString:@"com.apple.UIKit.activity.PostToTwitter"])
        return [NSNumber numberWithInt:HMShareMethodPostToTwitter];
    else return [NSNumber numberWithInt:999];
}

@end
