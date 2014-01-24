//
//  Scene+Logic.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Scene+Logic.h"
#import "DB.h"

@implementation Scene (Logic)


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

-(BOOL)hasScript
{
    if (self.script && self.script.length > 0) return YES;
    return NO;
}


@end
