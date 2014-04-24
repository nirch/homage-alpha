//
//  HMDINOTRegularFontButton+colorEffectes.m
//  Homage
//
//  Created by Yoav Caspin on 4/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMDINOTRegularFontButton+colorEffectes.h"

@implementation HMAvenirBookFontButton (colorEffectes)

- (void)setColor:(UIColor *)color forState:(UIControlState)state
{
    UIView *colorView = [[UIView alloc] initWithFrame:self.frame];
    colorView.backgroundColor = color;
    
    UIGraphicsBeginImageContext(colorView.bounds.size);
    [colorView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *colorImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self setBackgroundImage:colorImage forState:state];
    self.tintColor = color;
}

@end
