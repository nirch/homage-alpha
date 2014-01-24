//
//  Text+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Text+Factory.h"
#import "DB.h"

@implementation Text (Factory)

+(Text *)textWithID:(NSNumber *)sID story:(Story *)story inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@ AND story=%@",sID, story];
    Text *text = [DB.sh fetchOrCreateEntityNamed:HM_TEXT withPredicate:predicate inContext:context];
    text.sID = sID;
    text.story = story;
    return text;
}

@end
