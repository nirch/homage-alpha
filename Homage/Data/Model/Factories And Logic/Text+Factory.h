//
//  Text+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Text.h"

#define HM_TEXT         @"Text"

@interface Text (Factory)

+(Text *)textWithID:(NSNumber *)sID story:(Story *)story inContext:(NSManagedObjectContext *)context;

@end
