//
//  NSDictionary+TypeSafeValues.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "NSDictionary+TypeSafeValues.h"

@implementation NSDictionary (TypeSafeValues)

-(NSString *)stringForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSString class]]) return value;
    return nil;
}

-(NSNumber *)numberForKey:(id)key
{
    id value = self[key];
    
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSDecimalNumber *number = [NSDecimalNumber decimalNumberWithString:value];
        if (number) return number;
    }
    return nil;
}

-(NSDecimalNumber *)decimalNumberForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSDecimalNumber class]]) return value;
    return nil;
}

-(NSNumber *)boolNumberForKey:(id)key
{
    id value = self[key];
    if ([value isKindOfClass:[NSNumber class]]) return @([value boolValue]);
    return @(NO);
}


@end
