//
//  Remake+Logic.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake+Logic.h"
#import "DB.h"
#import "NSString+Utilities.h"

@implementation Remake (Logic)


-(Footage *)footageWithSceneID:(NSNumber *)sID
{
    // Ensure related story has the related sceneID
    if (![self.story hasSceneWithID:sID]) {
        HMGLogError(@"Wrong scene ID (%@) for this remake (%@)", sID, self.sID);
        return nil;
    }
    
    // Find and return existing.
    Footage *footage = [self findFootageWithSceneID:sID];
    if (footage) return footage;
    
    // Create a new one if doesn't exist.
    return [Footage newFootageWithSceneID:sID remake:self inContext:self.managedObjectContext];
}

-(Footage *)findFootageWithSceneID:(NSNumber *)sID
{
    for (Footage *footage in self.footages) {
        if ([footage.sceneID isEqualToNumber:sID]) return footage;
    }
    return nil;
}

-(NSArray *)footagesOrdered
{
    NSArray *footages = self.footages.allObjects;
    footages = [footages sortedArrayUsingComparator:^NSComparisonResult(Footage *footage1, Footage *footage2) {
        return [footage1.relatedScene.sID compare:footage2.relatedScene.sID];
    }];
    return footages;
}

-(NSArray *)footagesReadyStates
{
    NSMutableArray *states = [NSMutableArray new];
    HMFootageReadyState readyState = HMFootageReadyStateReadyForFirstRetake;
    for (Footage *footage in self.footagesOrdered) {
        if (!footage.rawLocalFile && footage.status.integerValue == HMFootageStatusStatusOpen) {
            [states addObject:@(readyState)];
            readyState = HMFootageReadyStateStillLocked;
        } else {
            [states addObject:@(HMFootageReadyStateReadyForSecondRetake)];
        }
    }
    return states;
}

-(NSNumber *)nextReadyForFirstRetakeSceneID
{
    NSArray *readyStates = self.footagesReadyStates;
    for (int i=0;i<readyStates.count;i++) {
        HMFootageReadyState state = [readyStates[i] integerValue];
        if (state == HMFootageReadyStateReadyForFirstRetake) {
            Scene *scene = self.story.scenesOrdered[i];
            return scene.sID;
        }
    }
    return nil;
}

-(BOOL)allScenesTaken
{
    NSNumber *nextReadySceneID = [self nextReadyForFirstRetakeSceneID];
    if (nextReadySceneID) return NO;
    return YES;
}

-(NSNumber *)lastSceneID
{
    Scene *lastScene = [self.story.scenesOrdered lastObject];
    return lastScene.sID;
}

-(BOOL)textsShouldBeEntered
{
    if (!self.texts) return NO;
    return YES;
}

-(NSString *)textWithID:(NSNumber *)textID
{
    NSInteger index = textID.integerValue - 1;
    NSArray *texts = self.texts;
    
    // Make sure not out of bounds
    if (index >= texts.count || index < 0) return nil;

    // Get the text and trim it.
    NSString *text = texts[index];
    text = [text stringWithATrim];
    return text;
}

-(BOOL)missingSomeTexts
{
    if (!self.texts) return NO;
    for (NSInteger textID=1;textID<=[self.texts count];textID++) {
        NSString *text = [self textWithID:@(textID)];
        if (!text || [text isEqualToString:@""]) return YES;
    }
    return NO;
}

@end
