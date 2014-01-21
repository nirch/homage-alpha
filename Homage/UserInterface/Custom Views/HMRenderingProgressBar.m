//
//  HMRenderingProgressBar.m
//  Homage
//
//  Created by Yoav Caspin on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRenderingProgressBar.h"

@implementation HMRenderingProgressBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"RenderingInProgress" owner:self options:nil];
        [self addSubview:self.renderingView];
    }
    return self;
}


static float progress;

-(void)start
{
    progress = 0.0f;
    self.progressBar.progress  = progress;
    if (self.progressBar.progress < 1 )
        [self performSelector:@selector(increaseProgress) withObject:nil afterDelay:0.3];
}

-(void)increaseProgress {
    progress += 0.05f;
    self.progressBar.progress = progress;
    if( progress < 1 )
        [self performSelector:@selector(increaseProgress) withObject:nil afterDelay:0.3];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
