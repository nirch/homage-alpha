//
//  HMStoreBuyButton.m
//  Homage
//
//  Created by Aviv Wolf on 12/21/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoreBuyButton.h"

#import "HMStyle.h"

@implementation HMStoreBuyButton

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initGUI];
    }
    return self;
}

-(void)initGUI
{
    self.layer.borderColor = self.tintColor.CGColor;
    self.layer.borderWidth = 2;
    self.layer.cornerRadius = 5;
    
    // ************
    // *  STYLES  *
    // ************
    self.layer.borderColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_BUY_BUTTON_STROKE].CGColor;
    self.backgroundColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_BUY_BUTTON_BG];
    [self setTitleColor:[HMStyle.sh colorNamed:C_STORE_PRODUCT_BUY_BUTTON_TEXT] forState:UIControlStateNormal];
}

@end
