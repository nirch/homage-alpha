//
//  HMMainGUIProtocol.h
//  Homage
//
//  Created by Aviv Wolf on 10/21/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HMABTester;

@protocol HMMainGUIProtocol <NSObject>

-(BOOL)isRenderingViewShowing;
-(CGFloat)renderingViewHeight;
-(void)showStoriesTab;
-(void)updateTitle:(NSString *)title;

@end
