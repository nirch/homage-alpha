//
//  HMRemakePresenterDelegate.h
//  Homage
//
//  Created by Aviv Wolf on 10/27/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMRemakePresenterDelegate <NSObject>

-(void)dismissPresentedRemake;

@optional;
-(void)userWantsToRemakeStory;

@end
