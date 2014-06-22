//
//  HMGoogleAPI.h
//  Homage
//
//  Created by Yoav Caspin on 6/21/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

@interface HMGoogleAPI : NSObject

+(HMGoogleAPI *)sharedInstance;
+(HMGoogleAPI *)sh;

-(void)shortenURL:(NSString *)longURL info:(NSDictionary *)info;

// HTTP session manager
@property (strong, nonatomic, readonly) AFHTTPSessionManager *session;

@end
