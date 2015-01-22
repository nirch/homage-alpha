//
//  HMConfigurationParser.m
//  Homage
//
//  Created by Yoav Caspin on 10/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMConfigurationParser.h"

@implementation HMConfigurationParser

-(void)parse
{
    // Take as is. Just make sure not to include any nil/null values.
    if ([self.objectToParse isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *prunedDictionary = [NSMutableDictionary new];
        for (NSString * key in [self.objectToParse allKeys])
        {
            id value = self.objectToParse[key];
            if ([value isKindOfClass:[NSNull class]]) continue;
            prunedDictionary[key] = value;
        }
        self.parseInfo = prunedDictionary;
    }
}
  

@end
