//
//  Story+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Story+Factory.h"
#import "DB.h"

@implementation Story (Factory)

+(Story *)storyWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@",sID];
    Story *story = [DB.sh fetchOrCreateEntityNamed:HM_STORY withPredicate:predicate inContext:context];
    story.sID = sID;
    return story;
}

@end
