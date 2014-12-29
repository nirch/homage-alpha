//
//  HMRegularFontButton.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRegularFontButton.h"
#import "HMStyle.h"
#import <THLabel/THLabel.h>

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
    NSString *fontName = [HMStyle.sh regularFontName];
    self.titleLabel.font = [UIFont fontWithName:fontName
                                           size:self.titleLabel.font.pointSize];
}

@end
