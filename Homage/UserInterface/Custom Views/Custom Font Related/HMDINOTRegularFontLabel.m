//
//  HMDINOTRegularFontLabel.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMDINOTRegularFontLabel.h"

@implementation HMDINOTRegularFontLabel

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
    [self setFont:[UIFont fontWithName:@"DINOT-Regular" size:self.font.pointSize]];
}

@end



