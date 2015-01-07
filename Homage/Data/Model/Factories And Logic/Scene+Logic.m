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

+(NSString *)stringForSceneBySceneID:(NSNumber *)sceneID
{
    return [NSString stringWithFormat:@"%ld", (long)sceneID.integerValue];
}

-(NSString *)titleForSceneID
{
    return [Scene titleForSceneBySceneID:self.sID];
}

-(NSString *)stringForSceneID
{
    return [Scene stringForSceneBySceneID:self.sID];
}

-(NSString *)titleForTime
{
    double seconds = self.duration.doubleValue / 1000.0f;
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
    NSString *secondsString = [numberFormatter stringFromNumber:@(seconds)];
    return [NSString stringWithFormat:@"%@ SEC", secondsString];
}

-(NSString *)stringForTime
{
    double seconds = self.duration.doubleValue / 1000.0f;
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
    NSString *secondsString = [numberFormatter stringFromNumber:@(seconds)];
    return [NSString stringWithFormat:@"%@", secondsString];
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

-(CGPoint)focusCGPoint
{
    CGPoint focusPoint;
    
    if (!self.focusPointX || !self.focusPointY)
    {
        HMGLogWarning(@"No focus point provided for scene %d in story %@ hence fallback to default", self.sID.integerValue, self.story.name);
        focusPoint = CGPointMake(0.5f, 0.5f);
    }
    else
    {
        focusPoint = CGPointMake(self.focusPointX.doubleValue, self.focusPointY.doubleValue);
    }
    return focusPoint;
}

-(BOOL)usesAudioFilesInRecorder
{
    if (self.directionAudioURL || self.sceneAudioURL) return YES;
    return NO;
}

@end
