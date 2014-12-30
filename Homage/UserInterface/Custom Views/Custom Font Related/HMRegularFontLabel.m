//
//  HMRegularFontLabel.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRegularFontLabel.h"
#import "HMStyle.h"

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
    NSString *fontName = [HMStyle.sh regularFontName];
    [self setFont:[UIFont fontWithName:fontName size:self.font.pointSize]];
    self.contentMode = UIViewContentModeCenter;
    
    // Default styles.
    self.strokeSize = [HMStyle.sh regularFontDefaultStrokeSize];
    self.strokeColor = [HMStyle.sh regularFontDefaultStrokeColor];
}

-(void)customizeStrokeSize:(CGFloat)size color:(UIColor *)color
{
    self.strokeSize = size;
    self.strokeColor = color;
}

@end



