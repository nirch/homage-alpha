//
//  HMDownloadDelegate.h
//  Homage
//
//  Created by Aviv Wolf on 1/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMDownloadDelegate <NSObject>

-(void)downloadFinishedSuccessfullyWithInfo:(NSDictionary *)info;
-(void)downloadFinishedWithError:(NSError *)error info:(NSDictionary *)info;

@end
