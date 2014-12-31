//
//  HMLoginSignupViewController.h
//  Homage
//
//  Created by Yoav Caspin on 3/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMLoginDelegate.h"

@interface HMLoginMainViewController : UIViewController

@property id<HMLoginDelegate> delegate;
+(HMLoginMainViewController *)instantiateLoginScreen;
-(void)onUserLogout;
-(void)onUserJoin;
-(void)onPresentLoginCalled;
-(void)registerLoginAnalyticsForUser:(User *)user;
-(void)loginAsGuest;

@end
