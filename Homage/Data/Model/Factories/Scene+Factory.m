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

+(NSString *)titleForSceneBySceneID:(NSNumber *)sceneID
{
    return [NSString stringWithFormat:@"SCENE %ld", (long)sceneID.integerValue];
}

-(NSString *)titleForSceneID
{
    return [Scene titleForSceneBySceneID:self.sID];
}

-(NSString *)titleForTime
{
    double seconds = self.duration.doubleValue / 1000.0f;
    return [NSString stringWithFormat:@"%3.1f", seconds];
}

-(NSTimeInterval)durationInSeconds
{
    return self.duration.doubleValue / 1000.f;
}

@end
