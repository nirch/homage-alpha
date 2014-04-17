//
//  HMVideoPlayerDelegate.h
//  Homage
//
//  Created by Yoav Caspin on 2/27/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMVideoPlayerDelegate <NSObject>

@optional
-(void)videoPlayerStopped;
-(void)videoPlayerFinishedPlaying;

@end
