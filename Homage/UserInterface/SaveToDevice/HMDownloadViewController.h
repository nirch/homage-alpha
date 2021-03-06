//
//  HMDownloadViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMDownloadDelegate.h"

typedef NS_ENUM(NSInteger, HMDownloadFlow) {
    HMDownloadFlowSaveToCameraRoll,
    HMDownloadFlowShare
};


@interface HMDownloadViewController : UIViewController

@property (nonatomic) NSInteger downloadFlow;
@property (nonatomic) id<HMDownloadDelegate> delegate;
@property (nonatomic) NSDictionary *info;

+(HMDownloadViewController *)downloadVCInParentVC:(UIViewController *)parentVC;
-(id)initWithDefaultNibInParentVC:(UIViewController *)parentVC;
-(void)startDownloadResourceFromURL:(NSURL *)url toLocalFolder:(NSURL *)localFolder;
-(void)startSavingToCameraRoll;
-(void)cancel;
-(void)dismiss;

@end
