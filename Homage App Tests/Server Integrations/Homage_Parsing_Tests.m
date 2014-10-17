//
//  Homage_Parsing_Tests.m
//  Homage
//
//  Created by Aviv Wolf on 10/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "DB.h"
#import "HMStoriesParser.h"

@interface Homage_Parsing_Tests : XCTestCase

@property (nonatomic) NSManagedObjectContext *ctx;

@end

@implementation Homage_Parsing_Tests

+(void)setUp
{
    [super setUp];
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

-(void)testParseStories {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSManagedObjectContext *ctx = [DB.sh inMemoryContextForTestsFromBundles:@[bundle]];

    // Load stories json file
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"stories" ofType:@"json"];
    XCTAssert(filePath, @"Missing data for parsing stories.json");
    NSError *fileError;
    NSData *jsonData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:&fileError];
    XCTAssertNil(fileError, @"Error in parsing data stories.json : %@", [fileError localizedDescription]);
    XCTAssertNotNil(jsonData, @"Parsed data stories.json is nil");
    
    // Serialize the data
    NSError *serializationError;
    NSArray *objectToParse = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&serializationError];
    XCTAssertNil(serializationError, @"Error in serialization of stories.json : %@", [serializationError localizedDescription]);
    XCTAssertNotNil(objectToParse, @"Parsed data stories.json is nil after NSJSONSerialization");
    
    // Parse data to objects
    HMStoriesParser *parser = [[HMStoriesParser alloc] initWithContext:ctx];
    parser.objectToParse = objectToParse;
    [parser parse];

    // Check that some stories exist and all of them have info about scenes
    NSArray *stories = [Story allActiveStoriesInContext:ctx];
    XCTAssertNotNil(stories, @"Story array is nil after parsing");
    XCTAssertGreaterThan(stories.count, 0, "Story array contains no stories after parsing.");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
