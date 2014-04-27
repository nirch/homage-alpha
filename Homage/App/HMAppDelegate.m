//
//  HMAppDelegate.m
//  Homage
//
//  Created by Homage on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAppDelegate.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMUploadManager.h"
#import "HMUploadS3Worker.h"
#import "Mixpanel.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import <FacebookSDK/FacebookSDK.h>
#import <Crashlytics/Crashlytics.h>


@implementation HMAppDelegate

#define MIXPANEL_TOKEN @"7d575048f24cb2424cd5c9799bbb49b1"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                           UIRemoteNotificationTypeSound |
                                                                           UIRemoteNotificationTypeAlert
                                                                           )
     ];
    
    #ifndef DEBUG
         [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    #endif
    
    [Crashlytics startWithAPIKey:@"daa34917843cd9e52b65a68cec43efac16fb680a"];
    
    self.pushNotificationFromBG = nil;
    
    // TODO: Route here the remote notification received when the app was inactive
    if (launchOptions) {
        NSDictionary *notificationInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notificationInfo) {
            
            HMPushNotificationType pushNotificationType = [[notificationInfo objectForKey:@"type"] intValue];
            
            if ( pushNotificationType == HMPushMovieReady || pushNotificationType == HMPushMovieFailed)
            {
                NSString *remakeID = [notificationInfo objectForKey:@"remake_id"];
                self.pushNotificationFromBG = @{@"remake_id" : remakeID };
            }
            
            // TODO: according to the detail in the notification, decide where and how to navigate to the proper screen in the UI.
            // IMPORTANT!!!!!:
            // Remmember that your app was just launched, you will have to initialize stuff first, before navigating to the screen you want.
            // You don't even have the local storage at this point and you have to wait for NSManagedDocument to open/be created.
            // So raise some flags or whatever here, and do the navigation logic in your UIViewControllers where they belong and at the proper moment!
        }
    }
    
    [FBLoginView class];
    return YES;
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // TODO: Route here the remote notification received when the app was active
    // This is a simple situation and the easiest way to announce about the notification is just
    // post a NSNotificationCenter notification here, and whatever UI in the app that want to handle it, will just
    // add an observer for it.
    
    NSMutableDictionary *info = [userInfo mutableCopy];
    HMPushNotificationType pushNotificationType = [[userInfo objectForKey:@"type"] intValue];
    
    if ( pushNotificationType == HMPushMovieReady || pushNotificationType == HMPushMovieFailed)
    {
        if (application.applicationState == UIApplicationStateActive)
        {
            [info setObject:[NSNumber numberWithInt:UIApplicationStateActive] forKey:@"app_state"];
        } else if (application.applicationState == UIApplicationStateInactive)
        {
            [info setObject:[NSNumber numberWithInt:UIApplicationStateInactive] forKey:@"app_state"];
            
        }
        
        if (pushNotificationType == HMPushMovieReady)
        {
            [info setObject:[NSNumber numberWithBool:YES] forKey:@"success"];
        } else
        {
            [info setObject:[NSNumber numberWithBool:NO] forKey:@"success"];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_PUSH_NOTIFICATION_MOVIE_STATUS object:self userInfo:info];
    }
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	HMGLogDebug(@"Registered to remote notifications with token: %@", deviceToken);
    self.pushToken = deviceToken;
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	HMGLogError(@"Failed to get token for remote notifications: %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_APP_WILL_RESIGN_ACTIVE object:nil userInfo:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [HMServer.sh stopMonitoringReachability];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_APP_WILL_ENTER_FOREGROUND object:nil userInfo:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [HMServer.sh startMonitoringReachability];    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    // Call FBAppCall's handleOpenURL:sourceApplication to handle Facebook app responses
    BOOL wasHandled = [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
    
    // You can add your app-specific url handling code here if needed
    
    return wasHandled;
}

@end
