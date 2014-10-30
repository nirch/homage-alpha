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
-(void)shareRemake:(Remake *)remake parentVC:(UIViewController *)parentVC trackEventName:(NSString *)trackEventName
{
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
    } else
    {
        generalShareSubject = [NSString stringWithFormat:LS(@"DEFAULT_SHARE_MSG_SUBJECT") , remake.story.name];
        whatsAppShareString = [NSString stringWithFormat:LS(@"DEFUALT_SHARE_MSG_BODY") , remake.story.name , remakeShareURL];
    }
    
    NSString *generalShareBody = [whatsAppShareString stringByAppendingString:[NSString stringWithFormat:LS(@"SHARE_MSG_BODY_HASHTAGS") , storyNameWithoutSpaces, storyNameWithoutSpaces]];
    WhatsAppMessage *whatsappMsg = [[WhatsAppMessage alloc] initWithMessage:whatsAppShareString forABID:nil];
    
    //
    NSArray *activityItems = [NSArray arrayWithObjects: generalShareBody, whatsappMsg, remake.thumbnail, nil];
    NSArray *applicationActivities = @[[[JBWhatsAppActivity alloc] init]];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:applicationActivities];
    activityViewController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed) {
            NSDictionary *trackProperties = @{
                                              @"story" : remake.story.name ,
                                              @"share_method" : activityType ,
                                              @"remake_id" : remake.sID,
                                              @"user_id" : User.current.userID,
                                              @"remake_owner_id": remake.user.userID
                                              };
            
            [[Mixpanel sharedInstance] track:trackEventName properties:trackProperties];
            NSNumber *shareMethod = [self getShareMethod:activityType];
            [HMServer.sh reportShare:shareID forRemake:remake.sID forUserID:[User current].userID shareMethod:shareMethod shareLink:remakeShareURL shareSuccess:true fromOriginatingScreen:[NSNumber numberWithInteger:HMMyStories]];
            
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
    //TODO:: get whatsapp activity name from iphone
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
