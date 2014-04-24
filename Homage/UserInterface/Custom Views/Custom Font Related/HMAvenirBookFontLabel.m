//
//  HMFontLabel.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAvenirBookFontLabel.h"

@implementation HMAvenirBookFontLabel

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
    [self setFont:[UIFont fontWithName:@"Avenir Book" size:self.font.pointSize]];
}

@end
