//
//  Homage_LocalStorage_Tests.m
//  Homage
//
//  Created by Aviv Wolf on 10/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DB.h"

@interface Homage_LocalStorage_Tests : XCTestCase

@end

@implementation Homage_LocalStorage_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLocalStorageJustOpen {
    __block NSString *failedMessage = @"";
    __block BOOL success = NO;

    // Attempt to open local storage
    XCTestExpectation *expectingOpenedLocalStorage = [self expectationWithDescription:@"local storage"];
    [DB.sh useDocumentWithSuccessHandler:^{
        success = YES;
        [expectingOpenedLocalStorage fulfill];
    } failHandler:^{
        success = NO;
        [expectingOpenedLocalStorage fulfill];
    }];
    [self waitForExpectationsWithTimeout:1.500 handler:^(NSError *error) {
        success = error ? NO : YES;
        failedMessage = @"opening local storage";
    }];
    
    // Fail if couldn't open local storage.
    if (!success) XCTFail(@"failed: %@", failedMessage);
}


@end
