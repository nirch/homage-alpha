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

-(BOOL)hasSceneWithID:(NSNumber *)sID
{
    if ([self findSceneWithID:sID]) return YES;
    return NO;
}

-(Scene *)findSceneWithID:(NSNumber *)sID
{
    for (Scene *scene in self.scenes) {
        if ([scene.sID isEqualToNumber:sID]) return scene;
    }
    return nil;
}

@end
