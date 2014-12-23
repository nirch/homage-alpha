 //
//  HMGoogleAPI.m
//  Homage
//
//  Created by Yoav Caspin on 6/21/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMGoogleAPI.h"
#import "HMNotificationCenter.h"

@interface HMGoogleAPI()

@property NSString *shortURL;

@end

@implementation HMGoogleAPI

#define GOOGLE_HOMAGE_API_KEY @"AIzaSyDXFEHpyYZRJBVQM_vi_1Yo8YjA4K6PGkU"

+(HMGoogleAPI *)sharedInstance
{
    static HMGoogleAPI *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMGoogleAPI alloc] init];
    });
    
    return sharedInstance;
}

+(HMGoogleAPI *)sh
{
   return [HMGoogleAPI sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [self initSessionManager];
    }
    return self;
}

-(void)initSessionManager
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURL *googleAPIURL = [NSURL URLWithString:@"https://www.googleapis.com"];
    _session = [[AFHTTPSessionManager alloc] initWithBaseURL: googleAPIURL sessionConfiguration:configuration];
    _session.requestSerializer = [AFJSONRequestSerializer serializer];
    //[[_session requestSerializer] setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

}

-(void)shortenURL:(NSString *)longURL info:(NSDictionary *)info
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    NSString *relativeURL = @"urlshortener/v1/url";
    
    NSDictionary *params = @{@"longUrl" : longURL , @"key" : GOOGLE_HOMAGE_API_KEY};
    HMGLogDebug(@"POST request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, params);
    
    [self.session POST:relativeURL parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //
        // Successful response from server.
        //
        
        NSDictionary *info = (NSDictionary *)responseObject;
        if (info[@"id"])
        {
            [moreInfo addEntriesFromDictionary:info];
            [moreInfo addEntriesFromDictionary:@{@"short_url" : info[@"id"]}];
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_SHORT_URL object:nil userInfo:moreInfo];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        HMGLogDebug(@"error in url shortening request");
        //
        // Failed request.
        //
        [moreInfo addEntriesFromDictionary:@{@"error" : error.description}];
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_SHORT_URL object:nil userInfo:moreInfo];
    }];
}




@end
