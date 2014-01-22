//
//  HMRemakesParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakesParser.h"

@implementation HMRemakesParser

-(id)init
{
    self = [super init];
    if (self) {
        _shouldRemoveOlderRemakes = NO;
    }
    return self;
}

-(void)parse
{
    NSArray *remakesInfo = self.objectToParse;
    NSDate *updateTime = [NSDate date];
    for (NSDictionary *remakeInfo in remakesInfo) {
        [self parseRemake:remakeInfo updateTime:updateTime];
    }
    
    // If flag raised, delete all remakes older than updateTime.
    // (this flag is NO by default)
    if (self.shouldRemoveOlderRemakes) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:HM_REMAKE];
        request.sortDescriptors = @[];
        request.predicate = [NSPredicate predicateWithFormat:@"lastUpdate<%@",updateTime];
        NSError *error;
        NSArray *oldRemakes = [self.ctx executeFetchRequest:request error:&error];
        if (error) return;
        for (Remake *remake in oldRemakes) {
            [self.ctx deleteObject:remake];
        }
    }
    [DB.sh save];
}

@end
