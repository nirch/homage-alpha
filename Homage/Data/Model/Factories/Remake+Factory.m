//
//  Remake+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake+Factory.h"
#import "DB.h"

@implementation Remake (Factory)

+(Remake *)remakeWithID:(NSString *)sID story:(Story *)story user:(User *)user inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@ AND story=%@",sID, story];
    Remake *remake = [DB.sh fetchOrCreateEntityNamed:HM_REMAKE withPredicate:predicate inContext:context];
    
    // Should never be owned by another user! This is a critical error!
    if (remake.user && [remake.user isNotThisUser:user]) {
        HMGLogError(@"Critical model/parsing error: remake already owned by user (%@). Why %@?", remake.user.userID, user.userID);
        return nil;
    }
    remake.sID = sID;
    remake.story = story;
    remake.user = user;
    return remake;
}

+(Remake *)findWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@",sID];
    return (Remake *)[DB.sh fetchSingleEntityNamed:HM_REMAKE withPredicate:predicate inContext:context];
}

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
        if (!footage.rawLocalFile) {
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

-(NSNumber *)lastSceneID
{
    Scene *lastScene = [self.story.scenesOrdered lastObject];
    return lastScene.sID;
}

@end
