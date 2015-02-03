//
//  HMStoreManagerDelegate.h
//  Homage
//
//  Created by Aviv Wolf on 1/7/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMParentalControlDelegate <NSObject>

@required
-(void)parentalControlValidatedSuccessfully;

@optional
-(void)parentalControlActionWithInfo:(NSDictionary *)info;

@end
