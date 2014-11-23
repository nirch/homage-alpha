//
//  HMRemakeScreenViewController.h
//  Homage
//
//  Created by Aviv Wolf on 10/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HMSimpleVideoPlayerDelegate.h"

@class Remake;

#import "HMRemakePresenterDelegate.h"

@interface HMRemakeScreenViewController : UIViewController<
    HMSimpleVideoPlayerDelegate,
    UIScrollViewDelegate,
    UIAlertViewDelegate
>

@property (nonatomic, weak) id<HMRemakePresenterDelegate> delegate;
@property (nonatomic) NSString *debugForcedVideoURL;

-(void)prepareForRemake:(Remake *)remake animateFromRect:(CGRect)s fromCenter:(CGPoint)c;

@end
