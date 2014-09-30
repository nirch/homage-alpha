//
//  HMDINOTRegularFontButton.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMDINOTRegularFontButton.h"
#import "HMColor.h"

@implementation HMDINOTRegularFontButton

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
}

@end
