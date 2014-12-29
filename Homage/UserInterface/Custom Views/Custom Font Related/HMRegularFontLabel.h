//
//  HMRegularFontLabel.h
//  Homage
//
//  Created by Tomer Harry on 2/4/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <THLabel/THLabel.h>

@interface HMRegularFontLabel : THLabel

// Optional customized stroke. If not set, uses default values set in style.
-(void)customizeStrokeSize:(CGFloat)size color:(UIColor *)color;

@end
