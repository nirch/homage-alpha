//
//  HMRoundButton.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRoundButton.h"

@implementation HMRoundButton

-(id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder: decoder])
    {
        [self initLook];
    }
    return self;
}

-(void)initLook
{
    double radius = self.bounds.size.width / 2.0;
    self.layer.cornerRadius = radius;
}

@end
