//
//  HMIntroMovieDelegate.h
//  Homage
//
//  Created by Yoav Caspin on 1/31/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DB.h"

@protocol HMIntroMovieDelegate <NSObject>

-(void)onLoginPressedSkip;
-(void)onLoginPressedShootFirstStory;

@end
