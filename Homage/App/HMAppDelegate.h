//
//  HMAppDelegate.h
//  Homage
//
//  Created by Homage on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

typedef NS_ENUM(NSInteger, HMPushNotificationType) {
    HMPushMovieReady,
};

@interface HMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSDictionary *pushNotificationFromBG;
@property (nonatomic) NSData *pushToken;

@end
