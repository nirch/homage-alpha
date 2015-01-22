//
//  NSDictionary+TypeSafeValues.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface NSDictionary (TypeSafeValues)

-(NSString *)stringForKey:(id)key;
-(NSNumber *)numberForKey:(id)key;
-(NSDecimalNumber *)decimalNumberForKey:(id)key;
-(NSNumber *)boolNumberForKey:(id)key;

@end
