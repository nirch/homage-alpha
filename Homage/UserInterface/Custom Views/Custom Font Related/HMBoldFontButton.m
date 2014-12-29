//
//  HMBoldFontButton.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMBoldFontButton.h"
#import "HMStyle.h"
#import <THLabel/THLabel.h>

@implementation HMBoldFontButton

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        [self initCustomFont];
    }
    return self;
}

-(void)initCustomFont
{
    NSString *fontName = [HMStyle.sh boldFontName];
    self.titleLabel.font = [UIFont fontWithName:fontName
                                           size:self.titleLabel.font.pointSize];
    
}

@end
