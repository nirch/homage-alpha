//
//  HMSharing.h
//  Homage
//
//  Created by Aviv Wolf on 10/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Remake;

#import <Foundation/Foundation.h>

@interface HMSharing : NSObject

-(void)shareRemake:(Remake *)remake parentVC:(UIViewController *)parentVC trackEventName:(NSString *)trackEventName;

@end
