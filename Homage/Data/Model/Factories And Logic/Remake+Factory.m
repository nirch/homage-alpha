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

+(NSArray *)allRemakesForUser:(User *)user withStatus:(NSInteger)status inContext:(NSManagedObjectContext  *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_REMAKE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user=%@ AND status=%@", user, @(status)];
    
    // Perform the fetch.
    NSError *error;
    NSArray *remakes = [context executeFetchRequest:fetchRequest error:&error];
    if (error) return nil;
    
    // Return the array of story objects.
    return remakes;
}

+(Remake *)remakeWithID:(NSString *)sID story:(Story *)story user:(User *)user inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@ AND story=%@",sID, story];
    Remake *remake = [DB.sh fetchOrCreateEntityNamed:HM_REMAKE withPredicate:predicate inContext:context];
    
    //TODO: try to figure out why was this needed in the first place
    // Should never be owned by another user! This is a critical error!
    /*if (remake.user && [remake.user isNotThisUser:user]) {
        HMGLogError(@"Critical model/parsing error: remake already owned by user (%@). Why %@?", remake.user.userID, user.userID);
        return nil;
    }*/
    remake.sID = sID;
    remake.story = story;
    remake.user = user;

    // Add blank texts to the remake.
    if (!remake.texts && remake.story.texts.count > 0) remake.texts = [NSMutableArray new];
    if (remake.texts) {
        for (NSInteger i=[remake.texts count];i<remake.story.texts.count;i++){
            [remake.texts addObject:@""];
        }
    }

    return remake;
}

+(Remake *)findWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@",sID];
    return (Remake *)[DB.sh fetchSingleEntityNamed:HM_REMAKE withPredicate:predicate inContext:context];
}

@end
