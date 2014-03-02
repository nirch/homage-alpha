//
//  HMVideoPlayerVC.h
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMVideoPlayerDelegate.h"

@interface HMVideoPlayerVC : UIViewController 

@property (nonatomic) NSURL *videoURL;
@property (nonatomic) id<HMVideoPlayerDelegate> delegate;

@end
