//
//  HMServer.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "HMServer.h"
#import "HMParser.h"

@interface HMServer()

@property (strong, nonatomic) NSDictionary *cfg;
@property (strong, nonatomic, readonly) NSURL *serverURL;
@property (strong, nonatomic, readonly) AFHTTPSessionManager *session;

@end

@implementation HMServer

#pragma mark - Initialization
// A singleton
+(HMServer *)sharedInstance
{
    static HMServer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMServer alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMServer *)sh
{
    return [HMServer sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [self loadCFG];
        [self initSessionManager];
    }
    return self;
}

-(void)initSessionManager
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [[AFHTTPSessionManager alloc] initWithBaseURL:self.serverURL sessionConfiguration:configuration];
    self.session.responseSerializer = [[AFJSONResponseSerializer alloc] init];
    self.session.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html",@"application/json"]];
}

#pragma mark - URL named
-(NSString *)relativeURLNamed:(NSString *)relativeURLName
{
    NSString *relativeURL = self.cfg[@"urls"][relativeURLName];
    return relativeURL;
}

-(NSString *)relativeURLNamed:(NSString *)relativeURLName withSuffix:(NSString *)suffix
{
    NSString *relativeURL = self.cfg[@"urls"][relativeURLName];
    relativeURL = [NSString stringWithFormat:@"%@/%@", relativeURL, suffix];
    return relativeURL;
}

#pragma mark - Server CFG
-(void)loadCFG
{
    //
    // Loads networking info from the ServerCFG.plist file.
    //
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"ServerCFG" ofType:@"plist"];
    self.cfg = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    
    // Init the server NSURL
    NSString *port = self.cfg[@"port"];
    NSString *protocol = self.cfg[@"protocol"];
    NSString *host = self.cfg[@"host"];
    if (port) {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", protocol, host, port]];
    } else {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", protocol, host]];
    }
}

#pragma mark - GET requests
// The most basic GET request
-(void)getRelativeURLNamed:(NSString *)relativeURLName
                parameters:(NSDictionary *)parameters
          notificationName:(NSString *)notificationName
                    parser:(HMParser *)parser
{
    NSError *error;
    NSString *relativeURL = self.cfg[@"urls"][relativeURLName];
    //
    // Check if relative url with given name exists in ServerCFG.
    //
    if (!relativeURL) {
        
        //
        // URL missing error.
        //
        NSString *errorMessage = [NSString stringWithFormat:@"Missing url named:%@ . Check ServerCFG.plist.", relativeURLName];
        HMGLogWarning(errorMessage);
        error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK
                                    code:HMNetworkErrorMissingURL
                                userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:@{@"error":error}];
        return;
    }
    [self getRelativeURL:(NSString *)relativeURL
              parameters:(NSDictionary *)parameters
        notificationName:(NSString *)notificationName
                  parser:(HMParser *)parser];
}



// The most basic GET request
-(void)getRelativeURL:(NSString *)relativeURL
           parameters:(NSDictionary *)parameters
     notificationName:(NSString *)notificationName
               parser:(HMParser *)parser
{

    //
    // send GET Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"GET request:%@/%@", self.session.baseURL, relativeURL);

    [self.session GET:relativeURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {

        //
        // Successful response from server.
        //
        HMGLogDebug(@"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
    
        //
        // Parse response.
        //
        parser.objectToParse = responseObject;
        [parser parse];
        if (parser.error) {

            //
            // Parser error.
            //
            HMGLogError(@"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:@{@"error":parser.error}];
            return;
            
        }
        
        //
        // Successful request and parsing.
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];

    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //
        // Failed request.
        //
        HMGLogError(@"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:@{@"error":error}];
        
    }];
}

#pragma mark - POST requests
// The most basic POST request
-(void)postRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                     parser:(HMParser *)parser
{
    NSError *error;
    
    //
    // Check if relative url with given name exists in ServerCFG.
    //
    NSString *relativeURL = self.cfg[@"urls"][relativeURLName];
    if (!relativeURL) {
        
        //
        // URL missing error.
        //
        NSString *errorMessage = [NSString stringWithFormat:@"Missing url named:%@ . Check ServerCFG.plist.", relativeURLName];
        HMGLogWarning(errorMessage);
        error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK
                                    code:HMNetworkErrorMissingURL
                                userInfo:@{NSLocalizedDescriptionKey:errorMessage}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:@{@"error":error}];
        return;
    }
}

// The most basic POST request
-(void)postRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                parser:(HMParser *)parser
{
    //
    // send POST Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"POST request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    
    [self.session POST:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

        //
        // Successful response from server.
        //
        HMGLogDebug(@"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
        
        //
        // Parse response.
        //
        parser.objectToParse = responseObject;
        [parser parse];
        if (parser.error) {
            
            //
            // Parser error.
            //
            HMGLogError(@"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:@{@"error":parser.error}];
            return;
            
        }
        
        //
        // Successful request and parsing.
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        //
        // Failed request.
        //
        HMGLogError(@"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        
    }];
}


@end
