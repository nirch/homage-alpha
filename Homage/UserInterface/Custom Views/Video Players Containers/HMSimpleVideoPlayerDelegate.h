//
//  HMSimpleVideoPlayerProtocol.h
//  Homage
//
//  Created by Yoav Caspin on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@protocol HMSimpleVideoPlayerDelegate <NSObject>

@optional
-(void)videoPlayerDidStop:(id)sender;
-(void)videoPlayerDidFinishPlaying;
-(void)videoPlayerWillPlay;
-(void)videoPlayerDidExitFullScreen;
-(void)videoPlayerWasFired;

@end
