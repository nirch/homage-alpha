//
//  HMBoldFontLabel.m
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMLabel.h"
#import "HMStyle.h"

@implementation HMLabel

-(void)awakeFromNib
{
    [self initLabel];
}

-(void)initLabel
{
    // Localized strings
    if (self.stringKey) {
        self.text = LS(self.stringKey);
    }
}

@end



