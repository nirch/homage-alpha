//
//  Scene+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Scene+Factory.h"
#import "DB.h"

@implementation Scene (Factory)

+(Scene *)sceneWithID:(NSNumber *)sID story:(Story *)story inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@ AND story=%@",sID, story];
    Scene *scene = [DB.sh fetchOrCreateEntityNamed:HM_SCENE withPredicate:predicate inContext:context];
    scene.sID = sID;
    scene.story = story;
    return scene;
}

@end
