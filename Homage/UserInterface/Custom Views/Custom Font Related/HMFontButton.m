//
//  HMFontButton.m
//  Homage
//
//  Created by Aviv Wolf on 1/19/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMFontButton.h"
#import "HMColor.h"

@implementation HMFontButton

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
    self.titleLabel.font = [UIFont fontWithName:@"DINOT-Regular" size:self.titleLabel.font.pointSize];
    [self setTitleColor:[HMColor.sh textImpact] forState:UIControlStateNormal];
}


@end
