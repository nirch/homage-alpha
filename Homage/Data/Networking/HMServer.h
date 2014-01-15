//
//  HMServer.h
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class HMParser;

#define ERROR_DOMAIN_NETWORK @"Network error"

typedef NS_ENUM(NSInteger, HMNetworkErrorCode) {
    HMNetworkErrorMissingURL,
    HMNetworkErrorGetRequestFailed,
    HMNetworkErrorPostRequestFailed
};


@interface HMServer : NSObject

+(HMServer *)sharedInstance;
+(HMServer *)sh;

#pragma mark - Get requests

// The most basic GET request.
-(void)getRelativeURLNamed:(NSString *)relativeURLName
          notificationName:(NSString *)notificationName
                    parser:(HMParser *)parser;

#pragma mark - Post requests

// The most basic POST request.
-(void)postRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                     parser:(HMParser *)parser;

@end
