//
//  HMDINOTRegularFontLabel.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRegularFontLabel.h"

@implementation HMRegularFontLabel

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
    [self setFont:[UIFont fontWithName:@"Bryant-MediumCompressed" size:self.font.pointSize]];
}

@end



