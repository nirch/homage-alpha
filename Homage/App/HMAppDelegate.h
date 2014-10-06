//
//  HMAppDelegate.h
//  Homage
//
//  Created by Homage on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#define IS_TEST_APP NO

typedef NS_ENUM(NSInteger, HMPushNotificationType) {
    HMPushMovieReady,
    HMPushMovieFailed,
    HMPushNewStory,
    HMGeneralMessage,
};

@interface HMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) NSDictionary *pushNotificationFromBG;
@property (nonatomic) NSData *pushToken;
@property (strong, nonatomic) NSString *currentSessionHomageID;
@property (nonatomic) BOOL sessionStartFlag;
@property (nonatomic) BOOL userJoinFlow;

@property (nonatomic) BOOL shouldAllowStatusBar;
@property (nonatomic) BOOL isInRecorderContext;

@property (nonatomic, readonly) NSString *deviceModel;

-(BOOL)isSlowDevice;

@end
