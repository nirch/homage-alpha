//
//  HMLoginDelegate.h
//  Homage
//
//  Created by Yoav Caspin on 3/19/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DB.h"

@protocol HMLoginDelegate <NSObject>

-(void)onUserSignedIn:(User *)user;

@end
