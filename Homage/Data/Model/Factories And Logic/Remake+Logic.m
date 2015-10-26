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
#import "HMCacheManager.h"

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

-(NSInteger)footagesUploadedCount
{
    NSInteger count = 0;
    for (Footage *footage in self.footages) {
        NSInteger status = footage.status.integerValue;
        if (status != 0 && status != 4) count ++;
    }
    return count;
}

-(NSInteger)footagesReadyCount
{
    NSInteger count = 0;
    for (Footage *footage in self.footages) {
        NSInteger status = footage.status.integerValue;
        if (status==3) count ++;
    }
    return count;
}

-(NSNumber *)nextReadyForFirstRetakeSceneID
{
    NSArray *readyStates = self.footagesReadyStates;
    for (int i=0;i<readyStates.count;i++) {
        HMFootageReadyState state = [readyStates[i] integerValue];
        if (state == HMFootageReadyStateReadyForFirstRetake) {
            Scene *scene = self.story.scenesOrdered[i];
            HMGLogDebug(@"scene.sID: %d" , scene.sID.intValue);
            return scene.sID;
        }
    }
    return nil;
}

-(BOOL)noFootagesTakenYet
{
    return [[self nextReadyForFirstRetakeSceneID] isEqualToNumber:@1];
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
    if (![text isKindOfClass:[NSString class]]) return @"";
    return [text stringWithATrim];
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

-(void)deleteRawLocalFiles
{
    return; // TODO: finish implementation of delete local files.
    for (Footage *footage in self.footages)
        [footage deleteRawLocalFile];
}

-(BOOL)isLikedByUserID:(NSString *)userID
{
    NSDictionary *likedByUsers = self.isLikedByUsers;
    if (!likedByUsers) return NO;
    if (likedByUsers[userID]) return YES;
    return NO;
}

-(BOOL)isLikedByCurrentUser
{
    return [self isLikedByUserID:User.current.userID];
}

-(void)likedByUserID:(NSString *)userID
{
    NSMutableDictionary *likes = self.isLikedByUsers;
    
    // Create mutable dictionary if missing.
    if (!likes) likes = [NSMutableDictionary new];
    
    // Add user as liking this remake
    likes[userID] = @YES;
    
    // Store it.
    self.isLikedByUsers = likes;
}

-(void)unlikedByUserID:(NSString *)userID
{
    NSMutableDictionary *likes = self.isLikedByUsers;

    // If not liked yet by this user, do nothing.
    if (!likes || !likes[userID]) return;

    // Unlike by this user
    [likes removeObjectForKey:userID];
    self.isLikedByUsers = likes;
}

-(NSArray *)allTakenTakesIDS
{
    NSMutableArray *takeIDS = [NSMutableArray new];
    NSArray *footages = [self footagesOrdered];
    NSArray *footagesReadyStates = [self footagesReadyStates];
    for (int i=0; i<footages.count; i++) {
        Footage *footage = footages[i];

        // Make sure footage in correct state.
        HMFootageReadyState readyState = [footagesReadyStates[i] integerValue];
        if (readyState != HMFootageReadyStateReadyForSecondRetake) {
            // Critical error - footage in wrong state.
            HMGLogError(@"Footage in wrong state (not ready): %@ scene:%@ state:%@", self.sID, @(i+1), @(readyState));
            return nil;
        }
        
        // Get the take id.
        NSString *takeID = [footage takeID];
        if (takeID == nil) {
            // Critical error - ready footage missing take id?
            HMGLogError(@"Ready footage missing take_id %@ %@", self.sID, @(i+1));
            return nil;
        }
        [takeIDS addObject:takeID];
    }
    return takeIDS;
}

-(BOOL)isVideoAvailableLocally
{
    if (self.videoURL == nil) return NO;

    // Check if video downloaded and cached locally.
    if ([HMCacheManager.sh isResourceCachedLocallyForURL:self.videoURL
                                               cachePath:HMCacheManager.sh.remakesCachePath])
        return YES;
    
    // Not bundled and not cached.
    return NO;
}

-(HMGRemakeBGQuality)footagesBGQuality
{
    NSArray *footages = [self footagesOrdered];
    
    BOOL someGood = NO;
    BOOL someBad = NO;
    for (Footage *footage in footages) {
        // All footages must already be taken or returns nil.
        if (footage.shotWithBadBG == nil)
            return HMGRemakeBGQualityUndefined;
        
        if ([footage.shotWithBadBG boolValue]) {
            someBad = YES;
        } else {
            someGood = YES;
        }
    }
    
    if (someGood) {
        if (someBad) {
            // Some takes with good backgrounds and some with good backgrounds.
            return HMGRemakeBGQualityOK;
        }
        
        // All takes with good backgrounds.
        return HMGRemakeBGQualityGood;
    }

    // All takes with bad background.
    return HMGRemakeBGQualityBad;
}

@end
