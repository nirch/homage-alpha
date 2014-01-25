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
