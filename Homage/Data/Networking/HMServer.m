//
//  HMServer.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"
#import "HMParser.h"
//#import "HMUploadManager.h"

@interface HMServer()

@property (strong, nonatomic) NSDictionary *cfg;
@property (strong, nonatomic, readonly) NSURL *serverURL;


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
}

-(void)testUploadManager
{
    //[HMUploadManager sh];
}

-(void)chooseSerializerForParser:(HMParser *)parser
{
//    if (parser) {
//        self.session.responseSerializer = [AFJSONResponseSerializer new];
//    } else {
//        self.session.responseSerializer = [AFHTTPResponseSerializer new];
//    }
    self.session.responseSerializer = [AFJSONResponseSerializer new];
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
    #ifndef DEBUG
        // Production server
        NSString *port = self.cfg[@"prod_port"];
        NSString *protocol = self.cfg[@"prod_protocol"];
        NSString *host = self.cfg[@"prod_host"];
    #else
        // Test server
        NSString *port = self.cfg[@"port"];
        NSString *protocol = self.cfg[@"protocol"];
        NSString *host = self.cfg[@"host"];
    #endif
    
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
                      info:(NSDictionary *)info
                    parser:(HMParser *)parser
{
    [self getRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
              parameters:(NSDictionary *)parameters
        notificationName:(NSString *)notificationName
                    info:(NSDictionary *)info
                  parser:(HMParser *)parser];
}



// The most basic GET request
-(void)getRelativeURL:(NSString *)relativeURL
           parameters:(NSDictionary *)parameters
     notificationName:(NSString *)notificationName
                 info:(NSDictionary *)info
               parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    //
    // send GET Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"GET request:%@/%@", self.session.baseURL, relativeURL);
    [self chooseSerializerForParser:parser];
    
    [self.session GET:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

        //
        // Successful response from server.
        //
        HMGLogDebug(@"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
    
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {

                //
                // Parser error.
                //
                HMGLogError(@"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;
                
            }
        }
        
        //
        // Successful request and parsing.
        //
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];

    
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //
        // Failed request.
        //
        HMGLogError(@"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    }];
}

#pragma mark - POST requests
// The most basic POST request
-(void)postRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser
{
    [self postRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
               parameters:(NSDictionary *)parameters
         notificationName:(NSString *)notificationName
                     info:(NSDictionary *)info
                   parser:(HMParser *)parser];
}

// The most basic POST request
-(void)postRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                  info:(NSDictionary *)info
                parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    //
    // send POST Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"POST request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    [self chooseSerializerForParser:parser];
    [self.session POST:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

        //
        // Successful response from server.
        //
        HMGLogDebug(@"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
        
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {
                
                //
                // Parser error.
                //
                HMGLogError(@"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;
                
            }
        }
        
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        
        //
        // Successful request and parsing.
        //
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        //
        // Failed request.
        //
        HMGLogError(@"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    }];
}

#pragma mark - POST requests
// The most basic DELETE request
-(void)deleteRelativeURLNamed:(NSString *)relativeURLName
                   parameters:(NSDictionary *)parameters
             notificationName:(NSString *)notificationName
                         info:(NSDictionary *)info
                       parser:(HMParser *)parser
{
    [self deleteRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser];
}

// The most basic DELETE request
-(void)deleteRelativeURL:(NSString *)relativeURL
              parameters:(NSDictionary *)parameters
        notificationName:(NSString *)notificationName
                    info:(NSDictionary *)info
                  parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    //
    // send DELETE Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"DELETE request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    [self chooseSerializerForParser:parser];
    [self.session DELETE:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
        //
        // Successful response from server.
        //
        HMGLogDebug(@"Response successful.\t%@\t%@\t(time:%f)", relativeURL, [responseObject class], [[NSDate date] timeIntervalSinceDate:requestDateTime]);
        HMGLogDebug(@"Response:%@", responseObject);
        if (parser) {
            //
            // Parse response.
            //
            parser.objectToParse = responseObject;
            parser.parseInfo = moreInfo;
            [parser parse];
            if (parser.error) {
                
                //
                // Parser error.
                //
                HMGLogError(@"Parsing failed with error.\t%@\t%@", relativeURL, [parser.error localizedDescription]);
                [moreInfo addEntriesFromDictionary:@{@"error":parser.error}];
                [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                return;
                
            }
        }
        
        //
        // Successful request and parsing.
        //
        [moreInfo addEntriesFromDictionary:parser.parseInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        //
        // Failed request.
        //
        HMGLogError(@"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
    }];
}


// TODO: REMOVE!!!!!!!!!!!!!!!!!!!!
-(void)ranHack
{
    // Ran always uses the Test server!!!!
    NSString *port = self.cfg[@"port"];
    NSString *protocol = self.cfg[@"protocol"];
    NSString *host = self.cfg[@"host"];
    
    if (port) {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@", protocol, host, port]];
    } else {
        _serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", protocol, host]];
    }
    
    [self initSessionManager];
}


@end
