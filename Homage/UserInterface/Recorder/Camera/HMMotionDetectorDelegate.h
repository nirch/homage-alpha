//
//  HMMotionDetectorDelegate.h
//  Homage
//
//  Created by Yoav Caspin on 2/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMMotionDetectorDelegate <NSObject>

@optional
-(void)onCameraNotStable;

@end
