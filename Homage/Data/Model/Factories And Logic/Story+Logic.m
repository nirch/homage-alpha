//
//  Story+Logic.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Story+Logic.h"
#import "DB.h"

@implementation Story (Logic)


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

-(NSArray *)scenesOrdered
{
    NSArray *scenes = self.scenes.allObjects;
    scenes = [scenes sortedArrayUsingComparator:^NSComparisonResult(Scene *scene1, Scene *scene2) {
        return [scene1.sID compare:scene2.sID];
    }];
    return scenes;
}

-(NSArray *)textsOrdered
{
    NSArray *texts = self.texts.allObjects;
    texts = [texts sortedArrayUsingComparator:^NSComparisonResult(Text *text1, Text *text2) {
        return [text1.sID compare:text2.sID];
    }];
    return texts;
}

-(BOOL)isADirector
{
    return !self.isASelfie;
}

-(BOOL)isASelfie
{
    return self.isSelfie.boolValue;
}

@end
