//
//  HMSaveToDeviceActivity.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMSaveToDeviceActivity.h"
#import "HMNotificationCenter.h"

@implementation HMSaveToDeviceActivity

-(NSString *)activityType
{
    NSString *activityType = [NSString stringWithFormat:@"%@.DownloadVideoToDeviceActivity", [[NSBundle mainBundle] bundleIdentifier]];
    return activityType;
}

- (NSString *)activityTitle
{
    return LS(@"DOWNLOAD_MY_VIDEO_TITLE");
}

- (UIImage *)activityImage
{
    // Note: These images need to have a transparent background and I recommend these sizes:
    // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
    // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.
    return [UIImage imageNamed:@"DownloadIcon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s",__FUNCTION__);
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    [self activityDidFinish:YES];
}


@end
