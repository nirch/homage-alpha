//
//  HMTextUpdateParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMTextUpdateParser.h"
#import "DB.h"
#import "NSString+Utilities.h"

@implementation HMTextUpdateParser

// Parse an array of stories.
// Each story is a dictionary.
-(void)parse
{
    if (![self.objectToParse isKindOfClass:[NSDictionary class]]) {
        NSString *errorMessage = [NSString stringWithFormat:@"Unexpected data from server %@", self.objectToParse];
        [self.errors addObject:[NSError errorWithDomain:ERROR_DOMAIN_PARSERS
                                                   code:HMParserErrorUnexpectedData
                                               userInfo:@{NSLocalizedDescriptionKey:errorMessage}
                                ]
         ];
        return;
    }
    
    
    NSString *remakeID = self.parseInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (!remake) return;
    if (!remake.texts) return;

    NSNumber *textID = self.parseInfo[@"textID"];
    NSArray *serverTexts = self.objectToParse[@"texts"];
    NSInteger index = textID.integerValue - 1;
    NSDictionary *textInfo = serverTexts[index];
    NSString *text = textInfo[@"text"];
    if ([text isKindOfClass:[NSString class]]) {
        // Update the remake's texts
        NSMutableArray *texts = [remake.texts mutableCopy];
        if (index<[remake.texts count]) {
            texts[index] = [text stringWithATrim];
            remake.texts = texts;
        }
    }
    
    
    
    [DB.sh save];
}

@end
