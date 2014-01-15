//
//  HMBasicParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMParser.h"
#import "DB.h"

@implementation HMParser

-(id)init
{
    self = [super init];
    if (self) {
        _ctx = DB.sh.context;
    }
    return self;
}

-(void)parse
{
    HMGLogError(@"parse not implemented for this parser. %@", [self class]);
    NSError *error = [NSError errorWithDomain:ERROR_DOMAIN_PARSERS
                                         code:HMParserErrorUnimplemented
                                     userInfo:@{NSLocalizedDescriptionKey:@"parse not implemented"}];
    [self.errors addObject:error];
}

-(NSError *)error
{
    if (self.errors && self.errors.count > 0) return [self.errors lastObject];
    return nil;
}

@end
