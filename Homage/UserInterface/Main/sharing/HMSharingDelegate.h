//
//  HMSharingDelegate.h
//  Homage
//
//  Created by Aviv Wolf on 1/26/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMSharingDelegate <NSObject>

-(void)sharingDidFinishWithShareBundle:(NSDictionary *)shareBundle;

@end
