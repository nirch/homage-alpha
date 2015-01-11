//
//  HMRecorderDetailedOptionsBarViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderChildInterface.h"
#import "HMCountDownDelegate.h"
#import "HMSimpleVideoPlayerDelegate.h"

@interface HMRecorderDetailedOptionsBarViewController : UIViewController<
    HMRecorderChildInterface,
    UITableViewDataSource,
    UITableViewDelegate,
    UIScrollViewDelegate,
    HMCountDownDelegate,
    HMSimpleVideoPlayerDelegate
>

-(void)shouldLockRecordButton;
-(void)shouldUnlockRecordButton;

@end
