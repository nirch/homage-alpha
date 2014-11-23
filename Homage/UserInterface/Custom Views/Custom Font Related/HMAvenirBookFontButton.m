//
//  HMFontButton.m
//  Homage
//
//  Created by Aviv Wolf on 1/19/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAvenirBookFontButton.h"
#import "HMColor.h"

@implementation HMAvenirBookFontButton

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
    self.titleLabel.font = [UIFont fontWithName:@"Bryant-MediumCompressed" size:self.titleLabel.font.pointSize];
}


@end
