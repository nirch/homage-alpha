//
//  HMRecorderPreviewViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSimpleVideoPlayerDelegate.h"

@class Footage;

@interface HMRecorderPreviewViewController : UIViewController<
    HMSimpleVideoPlayerDelegate
>

@property (nonatomic) NSString *videoURL;
@property (nonatomic) Footage *footage;

@end
