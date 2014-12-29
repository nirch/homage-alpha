//
//  HMBoldFontLabel.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMBoldFontLabel.h"
#import "HMStyle.h"

@implementation HMBoldFontLabel

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
    NSString *fontName = [HMStyle.sh boldFontName];
    [self setFont:[UIFont fontWithName:fontName
                                  size:self.font.pointSize]];
    
    // Default styles.
    self.strokeSize = [HMStyle.sh boldFontDefaultStrokeSize];
    self.strokeColor = [HMStyle.sh boldFontDefaultStrokeColor];
}

-(void)customizeStrokeSize:(CGFloat)size
                     color:(UIColor *)color
{
    self.strokeSize = size;
    self.strokeColor = color;
}

@end



