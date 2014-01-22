//
//  HMRoundCountdownLabel.h
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMCountDownDelegate.h"

@interface HMRoundCountdownLabel : UILabel

@property (nonatomic, readonly) NSInteger countDown;
@property (nonatomic) NSInteger countDownStartValue;
@property (weak, nonatomic) id<HMCountDownDelegate>delegate;

-(void)startTicking;
-(void)cancel;

@end
