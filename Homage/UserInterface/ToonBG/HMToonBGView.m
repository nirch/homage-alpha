//
//  HMToonBGView.m
//  Homage
//
//  Created by Aviv Wolf on 10/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMToonBGView.h"
#import "HMToonBGStyleKit.h"

@interface HMToonBGView()

@property NSDate *timeStarted;
@property NSTimeInterval timePassed;

// Monster roars
@property CGFloat monsterRoarFraction;

@end

@implementation HMToonBGView

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.timeStarted = 0;
        self.timePassed = 0;
        
        self.monsterRoarFraction = 0;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Draw everything in the background.
    // Provide the fraction 0.0 - 1.0 of the mosters jaw opening.
    [HMToonBGStyleKit drawCanvas1WithMonsterPosition:150
                                 monsterRoarFraction:self.monsterRoarFraction];
}

@end
