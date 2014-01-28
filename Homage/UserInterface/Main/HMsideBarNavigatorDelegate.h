//
//  HMsideBarNavigatorDelegate.h
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMsideBarNavigatorDelegate <NSObject>

-(void)storiesButtonPushed;
-(void)meButtonPushed;
-(void)settingsButtonPushed;

@end