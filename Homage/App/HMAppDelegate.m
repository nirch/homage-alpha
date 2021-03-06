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
#import "HMServer+analytics.h"
#import "HMServer+AppConfig.h"
#import "HMServer+Users.h"
#import "Mixpanel.h"
#import "HMStyle.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import <FacebookSDK/FacebookSDK.h>

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import <Appirater/Appirater.h>
#import "HMABTester.h"
#import <sys/utsname.h>

@interface HMAppDelegate()

@property (nonatomic, readonly) NSNumber *slowDeviceFlag;

@end

@implementation HMAppDelegate

#pragma mark - keys
// -------------------------------------------------------------------------------------
// Tokens, private and public keys.
// TODO: move to config or (even better) implement token per session if service supports
// -------------------------------------------------------------------------------------
// Apple ID
#define APPLE_ID @"851746600"
// ----------------------------------------------------------

#pragma mark - Application life cycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Init localization.
    [self initLocalizationWithOptions:launchOptions];
    
    // Required services
    [self initRequiredServices];

    //  TODO: handle old known push token here.
    //    // Get push token from previous app launches.
    //    if (!self.pushToken)
    //        self.pushToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"];
    
    // Async: Let the device know we want to receive push notifications
    [self initRemotePushNotificationsWithLaunchOptions:launchOptions];
    
    self.shouldAllowStatusBar = YES;
    self.pushNotificationFromBG = nil;
    
    // Routing remote notification received when the app was inactive
    if (launchOptions) {
        NSDictionary *notificationInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (notificationInfo) {
            
            HMPushNotificationType pushNotificationType = [[notificationInfo objectForKey:@"type"] intValue];
        
            if ( pushNotificationType == HMPushMovieReady || pushNotificationType == HMPushMovieFailed)
            {
                NSString *remakeID = [notificationInfo objectForKey:@"remake_id"];
                self.pushNotificationFromBG = @{@"remake_id" : remakeID , @"type" : [NSNumber numberWithInt:pushNotificationType]};
                [[Mixpanel sharedInstance] track:@"push notification clicked" properties:@{@"type" : @"movie ready" , @"app_status" : @"closed"}];
            }
            
            if ( pushNotificationType == HMPushNewStory )
            {
                NSString *storyID = [notificationInfo objectForKey:@"story_id"];
                self.pushNotificationFromBG = @{@"story_id" : storyID , @"type" : [NSNumber numberWithInt:pushNotificationType]};
                [[Mixpanel sharedInstance] track:@"push notification clicked" properties:@{@"type" : @"new story available" , @"story_id" : storyID , @"app_status" : @"closed"}];
            }
            
            if (pushNotificationType == HMGeneralMessage)
            {
                self.pushNotificationFromBG = @{@"type" : [NSNumber numberWithInt:pushNotificationType]};
                 [[Mixpanel sharedInstance] track:@"push notification clicked" properties:@{@"type" : @"general meesage" , @"app_status" : @"closed"}];
            }
        }
    }
    
    //appirater - library for app rating popup
    [Appirater setAppId:APPLE_ID];
    [Appirater setDaysUntilPrompt:1];
    [Appirater setUsesUntilPrompt:10];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater setDebug:NO];
    [Appirater appLaunched:YES];
    self.userJoinFlow = NO;
    [FBLoginView class];
    
    // Some app wide styling
    //[[UITextField appearance] setTintColor:[HMStyle.sh colorNamed:@"@impact"]];
    
    // Initialize some info about device
    _deviceModel = machineName();
    
    // Initialize AB Testing.
    _abTester = [HMABTester new];
    
    // Some apple stupidity handling here.
    [self preloadKeyboardView];
    
    return YES;
}


// Remote push notifications handling
-(void)initRemotePushNotificationsWithLaunchOptions:(NSDictionary *)launchOptions
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        //
        // use registerUserNotificationSettings
        // iOS 8 and above
        //
        // Notification type (sound, alert and badge)
        NSUInteger notificationTypes = (UIUserNotificationTypeSound |
                                        UIUserNotificationTypeAlert |
                                        UIUserNotificationTypeBadge);
        
        // Register user norification.
        [application registerUserNotificationSettings:[UIUserNotificationSettings
                                                       settingsForTypes:notificationTypes
                                                       categories:nil]];
        
        // Register remote notification.
        [application registerForRemoteNotifications];
    } else {
        //
        // use registerForRemoteNotifications
        // iOS 7
        //
        
        // Let the device know we want to receive push notifications
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound |
                                                                               UIRemoteNotificationTypeAlert
                                                                               )
         ];
    }
}


-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // TODO: Route here the remote notification received when the app was active
    // This is a simple situation and the easiest way to announce about the notification is just
    // post a NSNotificationCenter notification here, and whatever UI in the app that want to handle it, will just
    // add an observer for it.
    
    [self initRequiredServices];
    
    NSMutableDictionary *info = [userInfo mutableCopy];
    HMPushNotificationType pushNotificationType = [[userInfo objectForKey:@"type"] intValue];
    
    //the app can be active or inactive but still not in the background
    if (application.applicationState == UIApplicationStateActive)
    {
        [info setObject:[NSNumber numberWithInt:UIApplicationStateActive] forKey:@"app_state"];
    } else if (application.applicationState == UIApplicationStateInactive)
    {
        [info setObject:[NSNumber numberWithInt:UIApplicationStateInactive] forKey:@"app_state"];
        
    }
    
    if ( pushNotificationType == HMPushMovieReady || pushNotificationType == HMPushMovieFailed)
    {
        if (pushNotificationType == HMPushMovieReady)
        {
            [info setObject:[NSNumber numberWithBool:YES] forKey:@"success"];
        } else
        {
            [info setObject:[NSNumber numberWithBool:NO] forKey:@"success"];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_PUSH_NOTIFICATION_MOVIE_STATUS object:self userInfo:info];
         [[Mixpanel sharedInstance] track:@"push notification clicked" properties:@{@"type" : @"movie ready" , @"app_status" : @"background"}];
        
    }
    
    if (pushNotificationType == HMPushNewStory)
    {
        NSString *storyID = [userInfo objectForKey:@"story_id"];
        [info setObject:storyID forKey:@"story_id"];
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_PUSH_NOTIFICATION_NEW_STORY object:self userInfo:info];
        [[Mixpanel sharedInstance] track:@"push notification clicked" properties:@{@"type" : @"new story available" , @"story_id" : storyID , @"app_status" : @"background"}];
    }
    
    if (pushNotificationType == HMGeneralMessage)
    {
       [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_PUSH_NOTIFICATION_GENERAL_MESSAGE object:self userInfo:info];
        [[Mixpanel sharedInstance] track:@"push notification clicked" properties:@{@"type" : @"general meesage" , @"app_status" : @"background"}];
    }
    
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    self.pushToken = deviceToken;
    
    // Remmember push notification token for future app starts
    [[NSUserDefaults standardUserDefaults] setValue:deviceToken forKey:@"deviceToken"];
    
    // User already logged in.
    // Report token to server for this device of this user.
    HMGLogDebug(@"Will report new push token to server");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Check if user already logged in.
        User *user = [User current];
        HMGLogDebug(@"Registered to remote notifications with token:%@ for user_id:%@", deviceToken, user.userID);
        if (user == nil) {
            // No user yet.
            // Skip. (send the push notification info when user logs in).
            return;
        }
        [HMServer.sh updatePushToken:deviceToken forUser:user];
    });
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
    if (!self.currentSessionHomageID) return;
    if (!self.userJoinFlow && [User current])
    {
        [HMServer.sh reportSession:self.currentSessionHomageID endForUser:[User current].userID];
        self.sessionStartFlag = NO;
    }
    [[Mixpanel sharedInstance] track:@"AppMovedToBackGround"];
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
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [HMServer.sh startMonitoringReachability];
    if (!self.userJoinFlow && [User current])
    {
        
        if (!self.sessionStartFlag)
        {
            self.currentSessionHomageID = [HMServer.sh generateBSONID];
            [HMServer.sh reportSession:self.currentSessionHomageID beginForUser:[User current].userID];
            self.sessionStartFlag = YES;
        }
    }
    [FBSettings setDefaultAppID:[HMServer.sh facebookAppID]];
    [FBAppEvents activateApp];
    
    // Facebook
#define FB_APP_ID @"447743458659084"

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    if (self.currentSessionHomageID)
    {
        NSString *userID = [User current].userID;
        if (!userID) userID = @"unknown";
        [HMServer.sh reportSession:self.currentSessionHomageID endForUser:[User current].userID];
        self.sessionStartFlag = NO;
    }
  
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




#pragma mark - App States
-(void)setShouldAllowStatusBar:(BOOL)shouldAllowStatusBar
{
    _shouldAllowStatusBar = shouldAllowStatusBar;
}

-(void)setIsInRecorderContext:(BOOL)isInRecorderContext
{
    _isInRecorderContext = isInRecorderContext;
}

#pragma mark - App Info
+(NSString *)deviceModelName
{
    return machineName();
}

NSString* machineName()
{
    /*
     @"i386"      on 32-bit Simulator
     @"x86_64"    on 64-bit Simulator
     @"iPod1,1"   on iPod Touch
     @"iPod2,1"   on iPod Touch Second Generation
     @"iPod3,1"   on iPod Touch Third Generation
     @"iPod4,1"   on iPod Touch Fourth Generation
     @"iPhone1,1" on iPhone
     @"iPhone1,2" on iPhone 3G
     @"iPhone2,1" on iPhone 3GS
     @"iPad1,1"   on iPad
     @"iPad2,1"   on iPad 2
     @"iPad3,1"   on 3rd Generation iPad
     @"iPhone3,1" on iPhone 4
     @"iPhone4,1" on iPhone 4S
     @"iPhone5,1" on iPhone 5 (model A1428, AT&T/Canada)
     @"iPhone5,2" on iPhone 5 (model A1429, everything else)
     @"iPad3,4" on 4th Generation iPad
     @"iPad2,5" on iPad Mini
     @"iPhone5,3" on iPhone 5c (model A1456, A1532 | GSM)
     @"iPhone5,4" on iPhone 5c (model A1507, A1516, A1526 (China), A1529 | Global)
     @"iPhone6,1" on iPhone 5s (model A1433, A1533 | GSM)
     @"iPhone6,2" on iPhone 5s (model A1457, A1518, A1528 (China), A1530 | Global)
     @"iPad4,1" on 5th Generation iPad (iPad Air) - Wifi
     @"iPad4,2" on 5th Generation iPad (iPad Air) - Cellular
     @"iPad4,4" on 2nd Generation iPad Mini - Wifi
     @"iPad4,5" on 2nd Generation iPad Mini - Cellular
     @"iPhone7,1" on iPhone 6 Plus
     @"iPhone7,2" on iPhone 6
     */
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *model = [NSString stringWithCString:systemInfo.machine
                                         encoding:NSUTF8StringEncoding];
    return model;
}

-(BOOL)isSlowDevice
{
    if (_slowDeviceFlag) return [_slowDeviceFlag boolValue];
    NSString *deviceModel = self.deviceModel;
    _slowDeviceFlag = @NO;
    
    if ([deviceModel isEqualToString:@"iPhone3,1"]) {
        _slowDeviceFlag = @YES;
    }
        
    return [_slowDeviceFlag boolValue];
}


-(void)initRequiredServices
{
    HMGLogDebug(@"Initializing required 3rd party services.");
    #ifndef DEBUG
        // ----------------------------------------------------------
        // Release Build
        // ----------------------------------------------------------
        NSString *mixpanelToken = HMServer.sh.configurationInfo[@"ios_mixpanel_token"];
        if ([Mixpanel sharedInstance] == nil) {
            HMGLogDebug(@"Initializing mixpanel with token: %@", mixpanelToken);
            [Mixpanel sharedInstanceWithToken:mixpanelToken];
        } else {
            HMGLogDebug(@"Mixpanel already initialized.");
        }    
    #else
    // ----------------------------------------------------------
    // Debug Build
    // ----------------------------------------------------------
    NSString *mixpanelToken = HMServer.sh.configurationInfo[@"ios_mixpanel_token"];
    if ([Mixpanel sharedInstance] == nil) {
        HMGLogDebug(@"Initializing mixpanel with token: %@", mixpanelToken);
        [Mixpanel sharedInstanceWithToken:mixpanelToken];
    } else {
        HMGLogDebug(@"Mixpanel already initialized.");
    }
    #endif

    //TODO: fix crashlytics
    [Fabric with:@[[Crashlytics class]]];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel registerSuperProperties:@{
                                        @"Campaign ID":HMServer.sh.configurationInfo[@"campaign_id"],
                                        @"App":HMServer.sh.configurationInfo[@"application"]
                                        }];
}

-(void)preloadKeyboardView
{
    // This silly hack preloads keyboard so there's no lag on initial keyboard appearance.
    // Problem is a known silly bug by apple. iOS 7 + 8.
    // Apple? Why?! :-)
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
}

#pragma mark - Localisation
-(void)initLocalizationWithOptions:(NSDictionary *)options
{
    NSArray *preferredLocalizations = [[NSBundle mainBundle] preferredLocalizations];
    if (preferredLocalizations == nil || preferredLocalizations.count == 0) {
        _prefferedLanguage = nil;
        return;
    }
    _prefferedLanguage = preferredLocalizations[0];
}

@end
