//
//  HMStoriesParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoriesParser.h"
#import "HMStoryParser.h"

@implementation HMStoriesParser

// Parse an array of stories.
// Each story is a dictionary.
-(void)parse
{
    // Iterate all stories info
    NSArray *stories = self.objectToParse;
    for (NSDictionary *storyInfo in stories) {
        HMStoryParser *storyParser = [HMStoryParser new];
        storyParser.objectToParse = storyInfo;
        [storyParser parse];
    }
}

@end
