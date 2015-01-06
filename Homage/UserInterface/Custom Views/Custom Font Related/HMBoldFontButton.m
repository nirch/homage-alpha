//
//  HMBoldFontButton.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMBoldFontButton.h"
#import "HMStyle.h"
#import <THLabel/THLabel.h>

@implementation HMBoldFontButton

-(void)awakeFromNib
{
    [self initCustomFont];
}

-(void)initCustomFont
{
    // Get font name and size.
    NSString *fontName = [HMStyle.sh boldFontName];
    CGFloat fontSize = self.titleLabel.font.pointSize;
    
    // If a style class was set for this font, make some updates.
    if (self.styleClass) {
        // Get the style class.
        NSDictionary *styleAttrs = [HMStyle.sh styleClassForKey:self.styleClass];
        if (styleAttrs[S_FONT_RESIZE]) {
            fontSize += [styleAttrs[S_FONT_RESIZE] floatValue];
        }
    }
    
    // Localized strings
    if (self.stringKey) {
        [self setTitle:LS(self.stringKey) forState:UIControlStateNormal];
    }

    // Set the font name and size.
    self.titleLabel.font = [UIFont fontWithName:fontName
                                           size:fontSize];
    
}

@end
