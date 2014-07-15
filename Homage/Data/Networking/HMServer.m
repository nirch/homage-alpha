//
//  HMServer.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"
#import "HMParser.h"
#import "HMJSONResponseSerializerWithData.h"

//#import "HMUploadManager.h"

@interface HMServer()

@property (strong, nonatomic) NSDictionary *cfg;
@property (strong, nonatomic, readonly) NSURL *serverURL;
@property (strong,nonatomic) NSDictionary *context;
@property (strong,nonatomic) NSString *appVersionInfo;
@property (strong,nonatomic) NSString *appBuildInfo;


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
        [self loadAppDetails];
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
    self.session.responseSerializer = [HMJSONResponseSerializerWithData new];
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

#pragma mark - provide server woth request context
-(void)updateServerContext:(NSString *)userID
{
    self.context = @{@"user_id" : userID , @"version" : self.appVersionInfo , @"build" : self.appBuildInfo};
}

-(void)loadAppDetails
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.appBuildInfo = appBuildString;
    self.appVersionInfo = appVersionString;
    self.context = @{@"version" : self.appVersionInfo , @"build" : self.appBuildInfo};
}

-(NSDictionary *)addAppDetailsToDictionary:(NSDictionary *)dict
{
    NSMutableDictionary *tmpDict = [[NSMutableDictionary alloc] initWithDictionary:dict];
    [tmpDict setValue:self.context forKey:@"app_info"];
    NSDictionary *newDict = [NSDictionary dictionaryWithDictionary:tmpDict];
    return newDict;
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
    
    NSDictionary *moreParams = [self addAppDetailsToDictionary:parameters];
    
    //
    // send GET Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"GET request:%@/%@", self.session.baseURL, relativeURL);
    [self chooseSerializerForParser:parser];
    
    [self.session GET:relativeURL parameters:moreParams success:^(NSURLSessionDataTask *task, id responseObject) {

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
    
    NSMutableDictionary *moreInfo = [info mutableCopy];
    if (!moreInfo[@"attempts_count"])
    {
        moreInfo[@"attempts_count"] = [NSNumber numberWithInt:1];
    }
    
    [self postRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
               parameters:(NSDictionary *)parameters
         notificationName:(NSString *)notificationName
                     info:(NSDictionary *)moreInfo
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
    int attmeptsCount = [moreInfo[@"attempts_count"] intValue];
    [moreInfo removeObjectForKey:@"attempts_counts"];
    
    NSDictionary *moreParams = [self addAppDetailsToDictionary:parameters];
    //
    // send POST Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"POST request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    [self chooseSerializerForParser:parser];
    [self.session POST:relativeURL parameters:moreParams success:^(NSURLSessionDataTask *task, id responseObject) {

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
        if (attmeptsCount > 1)
        {
            [moreInfo addEntriesFromDictionary:@{@"attempts_count":[NSNumber numberWithInt:attmeptsCount-1]}];
            [self postRelativeURL:relativeURL
                       parameters:parameters
                 notificationName:notificationName
                             info:moreInfo
                           parser:parser];
        } else
        {
            HMGLogError(@"Request failed with error.\t%@\t(time:%f)\t%@", relativeURL, [[NSDate date] timeIntervalSinceDate:requestDateTime], [error localizedDescription]);
            
            [moreInfo addEntriesFromDictionary:@{@"error":error}];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        }
    }];
}

#pragma mark - DELETE requests
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
    
    NSDictionary *moreParams = [self addAppDetailsToDictionary:parameters];
    //
    // send DELETE Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"DELETE request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    [self chooseSerializerForParser:parser];
    [self.session DELETE:relativeURL parameters:moreParams success:^(NSURLSessionDataTask *task, id responseObject) {
        
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


// The most basic PUT request
-(void)putRelativeURLNamed:(NSString *)relativeURLName
                 parameters:(NSDictionary *)parameters
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
                     parser:(HMParser *)parser
{
    [self putRelativeURL:(NSString *)[self relativeURLNamed:relativeURLName]
               parameters:(NSDictionary *)parameters
         notificationName:(NSString *)notificationName
                     info:(NSDictionary *)info
                   parser:(HMParser *)parser];
}


// The most basic PUT request
-(void)putRelativeURL:(NSString *)relativeURL
            parameters:(NSDictionary *)parameters
      notificationName:(NSString *)notificationName
                  info:(NSDictionary *)info
                parser:(HMParser *)parser
{
    NSMutableDictionary *moreInfo = [info mutableCopy];
    NSDictionary *moreParams = [self addAppDetailsToDictionary:parameters];
    //
    // send PUT Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"PUT request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    [self chooseSerializerForParser:parser];
    [self.session PUT:relativeURL parameters:moreParams success:^(NSURLSessionDataTask *task, id responseObject) {
        
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

@end
