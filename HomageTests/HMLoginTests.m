//
//  HMLoginTests.m
//  Homage
//
//  Created by Yoav Caspin on 3/25/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HMNotificationCenter.h"
#import "HMServer+Users.h"
#import "DB.h"
#import "HMUserParser.h"

@interface HMLoginTests : XCTestCase

@property (strong,nonatomic) NSNotification *userCreatedNotification;
@property (strong,nonatomic) NSNotification *userUpdatedNotification;
@property dispatch_semaphore_t userCreatedSemaphore;
@property (strong,nonatomic) NSArray *usersToDelete;
@property (strong,nonatomic) NSArray *remakesToDelete;
@end


@implementation HMLoginTests

+(NSDictionary *)getDeviceInfo
{
    NSDictionary *deviceInfo = @{@"identifier_for_vendor" : @"598F006B-E51F-40E6-A6F7-FC39D8773C43" , @"model" : @"iPad_unit_test" , @"name" : @"unit_test" , @"push_token" :  @"83b2deb3 26d549ac 5d045055 697a43e5 b8c3e2fb ddd2b74e e2d903ac 8cafd570" , @"system_name" : @"Rafi" , @"system_version" : @"7.1"};
    
    return deviceInfo;
}

+(NSDictionary *)getFBDictionary
{
    NSDictionary *FBDictionary = @{@"birthday" : @"01/28/1983" , @"first_name" : @"Yoav" , @"id" : @"608706695" , @"last_name" : @"Caspin" , @"link" : @"https://www.facebook.com/yoav.caspin" , @"location" : @{@"id" : @106371992735156 , @"name" : @"Tel Aviv, Israel"} , @"name" : @"Yoav Caspin" , @"username" : @"yoav.caspin"};
    return  FBDictionary;
}

+(NSString *)getGuestUserID
{
   return @"533153a3f52d5c7edf00002a";
}

+(NSString *)getFBUserID
{
    return @"533153a3f52d5c7edf00002b";
}


+(NSDictionary *)getGuestDictionary
{
    NSDictionary *guestDictionary = @{@"is_public" : @NO , @"device" : [HMLoginTests getDeviceInfo]};
    return guestDictionary;
}

+(id)mockupGuestSuccesfulServerResponse
{
    NSDictionary *guestServerResponse = @{@"_id" : @{@"$oid" : [self getGuestUserID]} , @"created_at" : @"2014-03-25 10:00:03 UTC" , @"devices" : [HMLoginTests getDeviceInfo] , @"is_public" : @NO};
    return guestServerResponse;
}

+(id)mockupFacebookSuccesfulServerResponse
{
    NSDictionary *FBServerResponse = @{@"_id" : @{@"$oid" : @"533153a3f52d5c7edf00002b"} , @"created_at" : @"2014-03-25 10:00:03 UTC" , @"devices" : [HMLoginTests getDeviceInfo] , @"is_public" : @YES , @"email" : @"yoavcaspin@gmail.com" , @"facebook" : [HMLoginTests getFBDictionary]};
    return FBServerResponse;
}

+(id)mockupEmailSuccesfulServerResponse
{
    {
        NSDictionary *MailServerResponse = @{@"_id" : @{@"$oid" : @"533153a3f52d5c7edf00002c"} , @"created_at" : @"2014-03-25 10:00:03 UTC" , @"devices" : [HMLoginTests getDeviceInfo] , @"is_public" : @YES , @"email" : @"test2@homage.it" };
        return MailServerResponse;
    }
}

+(id)mockupFootages
{
    NSDictionary *scene1 = @{@"processed_video_s3_key" : @"Remakes/533061a0f52d5c6a14000007/processed_scene_1.mov" , @"                       raw_video_s3_key" : @"Remakes/533061a0f52d5c6a14000007/raw_scene_1.mov" , @"scene_id" : @1 , @"status" : @3};
    NSDictionary *scene2 = @{@"processed_video_s3_key" : @"Remakes/533061a0f52d5c6a14000007/processed_scene_2.mov" , @"                       raw_video_s3_key" : @"Remakes/533061a0f52d5c6a14000007/raw_scene_2.mov" , @"scene_id" : @2 , @"status" : @3};
    NSArray *footages = @[scene1,scene2];
    return  footages;
}

+(id)mockupRefetchingOfRemakes
{
    
    NSDictionary *remake1 = @{@"_id" : @{@"$oid" : @"000000000000000000000000"} , @"created_at" : @"2014-03-25 10:00:03 UTC"  , @"footages" : [HMLoginTests mockupFootages] , @"share_link" : @"http://play.homage.it/533061a0f52d5c6a14000007" , @"status" : @3 , @"story_id" : @{@"$oid" : @"53306186f52d5c6a14000006"} , @"thumbnail" : @"http://d293iqusjtyr94.cloudfront.net/Remakes/533061a0f52d5c6a14000007/Dive%20School_533061a0f52d5c6a14000007.jpg" , @"thumbnail_s3_key" : @"Remakes/533061a0f52d5c6a14000007/Dive School_533061a0f52d5c6a14000007.jpg" , @"user_id" : @{@"$oid" :[HMLoginTests getFBUserID]} , @"video" : @"http://d293iqusjtyr94.cloudfront.net/Remakes/533061a0f52d5c6a14000007/Dive%20School_533061a0f52d5c6a14000007.mp4" , @"video_s3_key" : @"Remakes/533061a0f52d5c6a14000007/Dive School_533061a0f52d5c6a14000007.mp4"};
   
    NSDictionary *remake2 = @{@"_id" : @{@"$oid" : @"111111111111111111111111"} , @"created_at" : @"2014-03-25 10:00:03 UTC"  , @"footages" : [HMLoginTests mockupFootages] , @"share_link" : @"http://play.homage.it/533061a0f52d5c6a14000007" , @"status" : @3 , @"story_id" : @{@"$oid" : @"53306186f52d5c6a14000006"} , @"thumbnail" : @"http://d293iqusjtyr94.cloudfront.net/Remakes/533061a0f52d5c6a14000007/Dive%20School_533061a0f52d5c6a14000007.jpg" , @"thumbnail_s3_key" : @"Remakes/533061a0f52d5c6a14000007/Dive School_533061a0f52d5c6a14000007.jpg" , @"user_id" : @{@"$oid" :[HMLoginTests getFBUserID]} , @"video" : @"http://d293iqusjtyr94.cloudfront.net/Remakes/533061a0f52d5c6a14000007/Dive%20School_533061a0f52d5c6a14000007.mp4" , @"video_s3_key" : @"Remakes/533061a0f52d5c6a14000007/Dive School_533061a0f52d5c6a14000007.mp4"};
    
    NSArray *remakesRefetchResponse = @[remake1,remake2];
    return remakesRefetchResponse;
}

-(void)initObservers
{
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserCreated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_CREATION
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserUpdated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_UPDATED
                                                     object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_UPDATED object:nil];
}


-(void)onUserCreated:(NSNotification *)notification
{
    self.userCreatedNotification = notification;
    //dispatch_semaphore_signal(self.userCreatedSemaphore);
}

-(void)onUserUpdated:(NSNotification *)notification
{
    self.userUpdatedNotification = notification;
}


- (void)setUp
{
    [super setUp];
    //[self initObservers];
    //self.userCreatedSemaphore = dispatch_semaphore_create(0);
}

- (void)tearDown
{
    //[self removeObservers];
    //self.userCreatedNotification = nil;
    //self.userUpdatedNotification = nil;
    User *currentUser = [User current];
    [currentUser logoutInContext:DB.sh.context];
    [DB.sh.context deleteObject:currentUser];
    [super tearDown];
    
}


-(void)testCreateGuest
{
    //[HMServer.sh createUserWithDictionary:[HMLoginTests getGuestDictionary]];
    id responseObject = [HMLoginTests mockupGuestSuccesfulServerResponse];
    HMParser *parser = [HMUserParser new];
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    parser.objectToParse = responseObject;
    parser.parseInfo = info;
    [parser parse];
    
    if (parser.error) {
        [info addEntriesFromDictionary:@{@"error":parser.error}];
    }
    
    [info addEntriesFromDictionary:parser.parseInfo];
    
    NSString *userID = info[@"userID"];
    XCTAssertNotNil(userID);
    
    User *user = [User userWithID:userID inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    XCTAssertNotNil(user);
    XCTAssertEqual(user.isPublic.intValue,0);
    XCTAssertEqual(user.remakes.count, 0);
    XCTAssertNil(user.email);
    XCTAssertNil(info[@"error"]);
}

-(void)testCreateFacebookUser
{
    id responseObject = [HMLoginTests mockupFacebookSuccesfulServerResponse];
    HMParser *parser = [HMUserParser new];
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    parser.objectToParse = responseObject;
    parser.parseInfo = info;
    [parser parse];
    
    if (parser.error) {
        [info addEntriesFromDictionary:@{@"error":parser.error}];
    }
    
    [info addEntriesFromDictionary:parser.parseInfo];
    
    NSString *userID = info[@"userID"];
    XCTAssertNotNil(userID);
    
    User *user = [User userWithID:userID inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    XCTAssertNotNil(user);
    XCTAssertEqual(user.isPublic.intValue,1);
    XCTAssertEqual(user.remakes.count, 0);
    XCTAssertNotNil(user.email);
    XCTAssertNotNil(user.fbID);
    XCTAssertNotNil(user.firstName);
    XCTAssertNil(info[@"error"]);
}

-(void)testCreateEmailUser
{
    id responseObject = [HMLoginTests mockupEmailSuccesfulServerResponse];
    HMParser *parser = [HMUserParser new];
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    parser.objectToParse = responseObject;
    parser.parseInfo = info;
    [parser parse];
    
    if (parser.error) {
        [info addEntriesFromDictionary:@{@"error":parser.error}];
    }
    
    [info addEntriesFromDictionary:parser.parseInfo];
    
    NSString *userID = info[@"userID"];
    XCTAssertNotNil(userID);
    
    User *user = [User userWithID:userID inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    XCTAssertNotNil(user);
    XCTAssertEqual(user.isPublic.intValue,1);
    XCTAssertEqual(user.remakes.count, 0);
    XCTAssertNotNil(user.email);
    XCTAssertNil(info[@"error"]);
}

-(void)testGuestToFacebook
{
    //login guest
    NSString *guestUserID = [HMLoginTests getGuestUserID];
    User *guestUser = [User userWithID:guestUserID inContext:DB.sh.context];
    [guestUser loginInContext:DB.sh.context];
    
    //fake remake for guest in local storage
    Story *story = [Story storyWithID:@"52c18c569f372005e0000286" inContext:DB.sh.context];
    [Remake remakeWithID:@"000000000000000000000000" story:story user:guestUser inContext:DB.sh.context];
    
    //logout guest user and login fb user
    [guestUser logoutInContext:DB.sh.context];
    NSString *FBUserID = [HMLoginTests getFBUserID];
    User *FBUser = [User userWithID:FBUserID inContext:DB.sh.context];
    [FBUser loginInContext:DB.sh.context];
    
    id responseObject = [HMLoginTests mockupRefetchingOfRemakes];
    HMParser *parser = [HMUserParser new];
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    parser.objectToParse = responseObject;
    parser.parseInfo = info;
    [parser parse];
    
    if (parser.error) {
        [info addEntriesFromDictionary:@{@"error":parser.error}];
    }
    
    [info addEntriesFromDictionary:parser.parseInfo];
    
    //after parsing of remakes, guest user should have 0 remakes, and fb user should have 2 remakes
    
    XCTAssertEqual(guestUser.remakes.count,0);
    XCTAssertEqual(FBUser.remakes.count,2);
}


@end
