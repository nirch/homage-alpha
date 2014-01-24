//
//  Story+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Story.h"

#define HM_STORY        @"Story"

@interface Story (Factory)

+(Story *)storyWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context;

@end
