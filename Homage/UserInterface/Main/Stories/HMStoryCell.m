//
//  HMStoryCell.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryCell.h"

@interface HMStoryCell()

@property (weak, nonatomic) IBOutlet UIView *guiBottomContainer;

@end

@implementation HMStoryCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
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
