//
//  Story+Logic.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Story+Logic.h"
#import "DB.h"
#import "HMCacheManager.h"
#import "HMAppStore.h"

@implementation Story (Logic)


-(BOOL)hasSceneWithID:(NSNumber *)sID
{
    if ([self findSceneWithID:sID]) return YES;
    return NO;
}

-(Scene *)findSceneWithID:(NSNumber *)sID
{
    
    if (!sID)
    {
        HMGLogError(@"got Wrong scene number");
        return nil;
    }
    
    for (Scene *scene in self.scenes) {
        
        if (!scene.sID)
        {
            HMGLogError(@"one of the scenes is empty");
            return nil;
        }
        
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

-(BOOL)isVideoAvailableLocally
{
    // Check if video is bundled locally.
    if ([HMCacheManager.sh isResourceBundledLocallyForURL:self.videoURL])
        return YES;
    
    // Check if video downloaded and cached locally.
    if ([HMCacheManager.sh isResourceCachedLocallyForURL:self.videoURL
                                               cachePath:HMCacheManager.sh.storiesCachePath])
        return YES;
    
    // Not bundled and not cached.
    return NO;
}

-(BOOL)isPremiumAndLocked
{
    BOOL premium = [self.isPremium boolValue];
    if (!premium) return NO;
    BOOL purchased = [self.wasPurchased boolValue];
    if (purchased) return NO;
    
    // Premium but was not purchased. Locked!
    return ![HMAppStore didUnlockStoryWithID:self.sID];
}

-(NSString *)productIdentifier
{
    if (self.isPremium == nil) return nil;
    if (self.isPremium.boolValue == NO) return nil;
    return [HMAppStore productIdentifierForID:self.sID];
}

-(BOOL)usesAudioFilesInRecorder
{
    for (Scene *scene in self.scenes) {
        if ([scene usesAudioFilesInRecorder]) return YES;
    }
    return NO;
}

-(NSTimeInterval)expectedRenderingTime
{
    if (self.estimatedRenderTime) return self.estimatedRenderTime.doubleValue;
    return 20.0f * self.scenes.count;
}


@end
