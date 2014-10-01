//
//  HMDINOTRegularFontButton.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRegularFontButton.h"
#import "HMColor.h"

@implementation HMRegularFontButton

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
