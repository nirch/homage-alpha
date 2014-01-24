//
//  HMTextUpdateParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMTextUpdateParser.h"
#import "DB.h"

@implementation HMTextUpdateParser

// Parse an array of stories.
// Each story is a dictionary.
-(void)parse
{
    NSString *remakeID = self.parseInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (!remake) return;
    if (!remake.texts) return;

    NSNumber *textID = self.parseInfo[@"textID"];
    NSArray *serverTexts = self.objectToParse[@"texts"];
    NSInteger index = textID.integerValue - 1;
    NSDictionary *textInfo = serverTexts[index];
    NSString *text = textInfo[@"text"];
    
    // Update the remake's texts
    NSMutableArray *texts = [remake.texts mutableCopy];
    if (index<[remake.texts count]) {
        texts[index] = text;
        remake.texts = texts;
    }
    
    
    [DB.sh save];
}

@end
