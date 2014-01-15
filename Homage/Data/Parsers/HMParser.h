//
//  HMBasicParser.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSDictionary+TypeSafeValues.h"

#define ERROR_DOMAIN_PARSERS @"Parser error"

typedef NS_ENUM(NSInteger, HMParserErrorCode) {
    HMParserErrorUnimplemented,
    HMParserErrorUnexpectedData
};

@interface HMParser : NSObject

// Reference to the context
@property (readonly, nonatomic, weak) NSManagedObjectContext *ctx;

// The object that should be parsed by the parser
@property (strong, nonatomic) id objectToParse;

// Array of all parsing errors
@property (nonatomic, readonly) NSMutableArray *errors;

// The last error
@property (nonatomic, readonly) NSError *error;

-(void)parse;

@end
