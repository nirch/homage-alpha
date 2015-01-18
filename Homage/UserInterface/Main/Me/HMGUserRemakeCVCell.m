//
//  HMGUserRemakeCVCell.m
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMGUserRemakeCVCell.h"

@implementation HMGUserRemakeCVCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.layoutInitialized = NO;
    }
    return self;
}

-(void)closeAnimated:(BOOL)animated
{
    if (self.guiScrollView.contentOffset.x != 0) {
        [self.guiScrollView setContentOffset:CGPointMake(0, 0) animated:animated];
    }
}

-(void)disableInteractionForAShortWhile
{
    self.userInteractionEnabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.userInteractionEnabled = YES;
    });
}


/*- (void)awakeFromNib {
    [self.expandedView setHidden:YES];
    CGRect frame = self.bounds;
    frame.size.width = 121;
    self.bounds = frame;
}*/

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
