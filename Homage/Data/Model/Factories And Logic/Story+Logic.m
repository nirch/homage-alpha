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

-(NSNumber *)isActiveInCurrentVersionFirstVersion:(NSString *)firstVersionActive LastVersionActive:(NSString *)lastVersionActive
{
    if (firstVersionActive == nil) return @NO;
    
    NSString *currentAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    NSComparisonResult result = [currentAppVersion compare:firstVersionActive options:NSNumericSearch];
    
    if (( result == NSOrderedDescending || result == NSOrderedSame) && lastVersionActive == nil)
    {
        // firstVersionActive <= currentAppVersion and lastVersionActive == nil
        return @YES;
    }
    
    NSComparisonResult lowerBorderResult = [currentAppVersion compare:firstVersionActive options:NSNumericSearch];
    NSComparisonResult upperBorderResult = [lastVersionActive compare:currentAppVersion options:NSNumericSearch];
    
    if ((lowerBorderResult == NSOrderedDescending || lowerBorderResult == NSOrderedSame) && (upperBorderResult == NSOrderedDescending || upperBorderResult == NSOrderedSame)) {
        // firstVersionActive <= currentAppVersion <= lastVersionActive
        return @YES;
    }
        
    if ([firstVersionActive compare:currentAppVersion options:NSNumericSearch] == NSOrderedDescending)
    {
        //currentAppVersion < firstVersionActive
        return @NO;
    }
        
    if ([currentAppVersion compare:lastVersionActive options:NSNumericSearch] == NSOrderedDescending)
    {
        // lastVersionActive < currentAppVersion
        return @NO;
    }
    
    //unknown - DEBUG
    HMGLogDebug(@"firstVersionActive: %@ , currentAppVersion: %@ lastVersionActive: %@" , firstVersionActive , currentAppVersion , lastVersionActive);
    return @NO;
    
}

-(BOOL)isVideoAvailableLocally
{
    // Check if video is bundled locally.
    if ([HMCacheManager.sh isResourceBundledLocallyForURL:self.videoURL])
        return YES;
    
    // Check if video downloaded and cached locally.
    if ([HMCacheManager.sh isResourceCachedLocallyForURL:self.videoURL cachePath:HMCacheManager.sh.storiesCachePath])
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
    return YES;
}

-(BOOL)usesAudioFilesInRecorder
{
    for (Scene *scene in self.scenes) {
        if ([scene usesAudioFilesInRecorder]) return YES;
    }
    return NO;
}


@end
