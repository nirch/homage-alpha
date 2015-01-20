//
//  HMRoundCountdownLabel.m
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRoundCountdownLabel.h"
#import "AWPieSliceView.h"
#import "HMAppDelegate.h"
#import "HMStyle.h"

@interface HMRoundCountdownLabel()

@property (nonatomic, readonly) NSTimer *timer;
@property (nonatomic, readonly) AWPieSliceView *pieSlice;
@property (nonatomic, readonly) UILabel *label;
@property (nonatomic, readonly) BOOL isSlowDevice;

@property (nonatomic) UIColor *colorRecorderRecordButtonCountDownBG1;
@property (nonatomic) UIColor *colorRecorderRecordButtonCountDownBG2;

@end

@implementation HMRoundCountdownLabel

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initGUI];
        self.countDownStartValue = self.text.integerValue;
        self.layer.cornerRadius = self.bounds.size.width/2.0f;
        self.text = @"";
        HMAppDelegate *app = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
        _isSlowDevice = [app isSlowDevice];
        [self initGUI];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.countDownStartValue = self.text.integerValue;
        self.layer.cornerRadius = self.bounds.size.width/2.0f;
        self.text = @"";
        HMAppDelegate *app = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
        _isSlowDevice = [app isSlowDevice];
        [self initGUI];
    }
    return self;
}

-(void)initGUI
{
    // ************
    // *  STYLES  *
    // ************
    self.colorRecorderRecordButtonCountDownBG1 = [HMStyle.sh colorNamed:C_RECORDER_RECORD_BUTTON_COUNT_DOWN_BG_1];
    self.colorRecorderRecordButtonCountDownBG2 = [HMStyle.sh colorNamed:C_RECORDER_RECORD_BUTTON_COUNT_DOWN_BG_2];
}

-(void)initCountdownState
{
    _countDown = self.countDownStartValue;
}

-(void)startTicking
{
    [self initCountdownState];
    if (self.timer) [self.timer invalidate];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                              target:self
                                            selector:@selector(onTimeTick:)
                                            userInfo:nil
                                             repeats:YES];
    [self update];
}

-(void)cancel
{
    [self.timer invalidate];
    _countDown = 0;
    [self update];
}

#pragma mark - Update
-(void)update
{
    // Remove old pie slice
    if (self.pieSlice) [self.pieSlice removeFromSuperview];
    if (self.label) [self.label removeFromSuperview];
    
    if (self.countDown<=0) {
        return;
    }
    
    // Add a new pie slice to the view

    if (!self.isSlowDevice) {
        _pieSlice = [[AWPieSliceView alloc] initWithFrame:self.bounds];
        self.pieSlice.value = 0.0f;
        self.pieSlice.backgroundColor = self.colorRecorderRecordButtonCountDownBG1;
        self.pieSlice.alpha = 0.6;
        [self addSubview:self.pieSlice];
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.pieSlice.value = 1.0f;
        });
    }
    
    // Add the label above it.
    _label = [[UILabel alloc] initWithFrame:self.bounds];
    self.label.text = [NSString stringWithFormat:@"%ld", (long)self.countDown];
    self.label.font = self.font;
    self.label.textAlignment = self.textAlignment;
    self.label.textColor = self.textColor;
    [self addSubview:self.label];
}

#pragma mark - Time tick
-(void)onTimeTick:(NSTimer *)timer
{
    _countDown--;
    if (self.countDown<=0) {
        //
        // Done.
        //
        [self.timer invalidate];
        [self.delegate countDownDidFinish];
    }
    [self update];
}

@end
