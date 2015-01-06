//
//  HMSplashViewController.h
//  Homage
//
//  Created by Aviv Wolf on 10/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MONActivityIndicatorView/MONActivityIndicatorView.h>

@interface HMSplashViewController : UIViewController<
    MONActivityIndicatorViewDelegate
>


-(void)prepare;
-(void)start;
-(void)done;
-(void)showFailedToConnectMessage;

@end
