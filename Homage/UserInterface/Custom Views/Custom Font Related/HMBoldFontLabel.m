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

-(void)awakeFromNib
{
    [self initCustomFont];
}

-(void)initCustomFont
{
    // Get font name and size.
    NSString *fontName = [HMStyle.sh boldFontName];
    CGFloat fontSize = self.font.pointSize;
    
    // Default styles.
    CGFloat strokeSize = [HMStyle.sh regularFontDefaultStrokeSize];
    UIColor *strokeColor = [HMStyle.sh regularFontDefaultStrokeColor];
    
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
        self.text = LS(self.stringKey);
    }
    
    // Set the styles.
    self.strokeSize = strokeSize;
    self.strokeColor = strokeColor;
    [self setFont:[UIFont fontWithName:fontName size:fontSize]];
    self.contentMode = UIViewContentModeCenter;
}

@end



