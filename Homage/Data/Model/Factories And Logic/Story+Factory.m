//
//  Story+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Story+Factory.h"
#import "DB.h"

@implementation Story (Factory)

+(Story *)storyWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"sID=%@",sID];
    Story *story = [DB.sh fetchOrCreateEntityNamed:HM_STORY withPredicate:predicate inContext:context];
    story.sID = sID;
    return story;
}

+(NSArray *)allActiveStoriesInContext:(NSManagedObjectContext  *)context
{
    // Create fetch request
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_STORY];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@", @(YES)];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"orderID" ascending:YES]];

    // Perform the fetch.
    NSError *error;
    NSArray *stories = [context executeFetchRequest:fetchRequest error:&error];
    if (error) return nil;
    
    // Return the array of story objects.
    return stories;
}

+(NSArray *)allActivePremiumStoriesInContext:(NSManagedObjectContext  *)context
{
    // Create fetch request
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_STORY];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND isPremium=%@", @(YES), @(YES)];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"orderID" ascending:YES]];
    
    // Perform the fetch.
    NSError *error;
    NSArray *stories = [context executeFetchRequest:fetchRequest error:&error];
    if (error) return nil;
    
    // Return the array of story objects.
    return stories;
}


@end
