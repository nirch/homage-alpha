//
//  HMRemakesParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakesParser.h"

@implementation HMRemakesParser

-(void)parse
{
    NSArray *remakesInfo = self.objectToParse;
    for (NSDictionary *remakeInfo in remakesInfo) {
        [self parseRemake:remakeInfo];
    }
}

@end
