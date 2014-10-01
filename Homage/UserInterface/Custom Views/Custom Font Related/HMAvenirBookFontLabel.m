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
    // TODO: remove this class. deprecated. use HMRegularFontLabel instead.
    [self setFont:[UIFont fontWithName:@"Bryant-MediumCompressed" size:self.font.pointSize]];
}

@end
