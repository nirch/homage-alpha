//
//  HMDetailedStoryRemakeVideoPlayerVC.h
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMSimpleVideoPlayerDelegate.h"

@interface HMDetailedStoryRemakeVideoPlayerVC : UIViewController <HMSimpleVideoPlayerDelegate>

@property (nonatomic) NSString *videoURL;

@end
