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
#import "HMAppDelegate.h"

#import "HMUploadManager.h"

@interface HMServer()

@property (strong, nonatomic) NSDictionary *cfg;
@property (strong, nonatomic) NSString *defaultsFileName;
@property (strong, nonatomic, readonly) NSURL *serverURL;
@property (strong,nonatomic) NSDictionary *context;
@property (strong,nonatomic) NSString *appVersionInfo;
@property (strong,nonatomic) NSString *appBuildInfo;
@property (strong,nonatomic) NSString *currentUserID;

@end

@implementation HMServer

@synthesize configurationInfo = _configurationInfo;

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
        self.urlsCachedInfo = [NSCache new];
    }
    return self;
}

-(void)initSessionManager
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [[AFHTTPSessionManager alloc] initWithBaseURL:self.serverURL sessionConfiguration:configuration];
    
    self.session.responseSerializer = [HMJSONResponseSerializerWithData new];
    self.session.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html",@"application/json"]];

}

-(void)chooseSerializerForParser:(HMParser *)parser
{
    self.session.requestSerializer = [AFHTTPRequestSerializer new];
    [self.session.requestSerializer setValue:self.appBuildInfo forHTTPHeaderField:@"APP_BUILD_INFO"];
    [self.session.requestSerializer setValue:self.appVersionInfo forHTTPHeaderField:@"APP_VERSION_INFO"];
    
    if (self.currentUserID) {
         [self.session.requestSerializer setValue:self.currentUserID forHTTPHeaderField:@"USER_ID"];
    }
    
    self.session.responseSerializer = [HMJSONResponseSerializerWithData new];
    self.session.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html",@"application/json"]];
}

#pragma mark - URL named
-(NSString *)absoluteURLNamed:(NSString *)urlName
{
    NSString *url = self.cfg[@"urls"][urlName];
    if (!url) return nil;
    // Must start with http:// or https://
    if ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]) return url;
    return nil;
}

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
-(void)updateServerWithCurrentUser:(NSString *)userID
{
    self.currentUserID = userID;
}

-(void)updateConfiguration:(NSDictionary *)info
{
    self.configurationInfo = info;
}

-(void)setConfigurationInfo:(NSDictionary *)configurationInfo
{
    if (!configurationInfo) return;
    
    // Store in memory.
    _configurationInfo = configurationInfo;
    
    // Store in local storage for future use.
    [[NSUserDefaults standardUserDefaults] setValue:configurationInfo forKey:@"config"];
}

-(NSDictionary *)configurationInfo
{
    // If in memory, return configuration from memory.
    if (_configurationInfo) return _configurationInfo;
    
    // If not in memory, check if exists in local storage. If it does, put it in memory and return it.
    _configurationInfo = [[NSUserDefaults standardUserDefaults] valueForKey:@"config"];
    if (_configurationInfo) return _configurationInfo;
    
    // Not in memory and not in local storage. Load defaults, store and return;
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:self.defaultsFileName ofType:@"plist"];
    self.configurationInfo = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    return _configurationInfo;
}

-(void)loadAppDetails
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.appBuildInfo = appBuildString;
    self.appVersionInfo = appVersionString;
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
    NSString *port;
    NSString *protocol;
    NSString *host;

    #ifndef DEBUG
    if (IS_TEST_APP) {
        // Use test server on test apps
        // (even on "Release" compilation)
        port = self.cfg[@"port"];
        protocol = self.cfg[@"protocol"];
        host = self.cfg[@"host"];
        self.defaultsFileName = @"DefaultsCFGTest";
        HMGLogNotice(@"Using test server (release app):%@", host);
    } else {
        // Release app for production.
        // Use production server urls and settings
        port = self.cfg[@"prod_port"];
        protocol = self.cfg[@"prod_protocol"];
        host = self.cfg[@"prod_host"];
        self.defaultsFileName = @"DefaultsCFG";
        HMGLogNotice(@"Using prod server (release app):%@", host);
    }
    #else
        // Just debugging the app. Use test server.
        port = self.cfg[@"port"];
        protocol = self.cfg[@"protocol"];
        host = self.cfg[@"host"];
        self.defaultsFileName = @"DefaultsCFG";
        HMGLogNotice(@"Using test server (debug app):%@", host);
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
    if (!moreInfo) {
        moreInfo = [NSMutableDictionary new];
    }
    
    
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
    
    NSMutableDictionary *moreInfo = [info mutableCopy];    
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
    //
    // send PUT Request to server
    //
    NSDate *requestDateTime = [NSDate date];
    HMGLogDebug(@"PUT request:%@/%@ parameters:%@", self.session.baseURL, relativeURL, parameters);
    [self chooseSerializerForParser:parser];
    [self.session PUT:relativeURL parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        
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
