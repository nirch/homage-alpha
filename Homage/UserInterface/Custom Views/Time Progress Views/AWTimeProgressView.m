//
//  AWTimeProgressView.m
//  Aviv Wolf
//
//  Created by Aviv Wolf on 2/21/13.
//  Copyright (c) 2014 interactive Wolf. All rights reserved.
//

@import QuartzCore.QuartzCore;

#import "AWTimeProgressView.h"

@interface AWTimeProgressView()

@property (nonatomic, weak) UIView *progressIndicator;
@property (nonatomic, weak) UIView *eventIndicatorTemplate;

// Timers for events
@property (nonatomic) NSTimer *mainTimer;
@property (nonatomic) NSMutableArray *timers;
@property (nonatomic) NSMutableArray *eventsIndicatorsViews;

// Utilities
@property (nonatomic, readonly) NSDate *startingTime;
@property (nonatomic, readonly) CGRect startingFrame;
@property (nonatomic, readonly) CGRect endFrame;
@property (nonatomic, readonly) double width;
@property (nonatomic, readonly) double height;


@end

@implementation AWTimeProgressView

-(id)initWithCoder:(NSCoder *)aDecoder
{
    HMGLogDebug(@"%s started in %p", __PRETTY_FUNCTION__ , &self);
    self = [super initWithCoder:aDecoder];
    if (self) {
        if (self.subviews.count>0) self.progressIndicator = self.subviews[0];
        if (self.subviews.count>1) self.eventIndicatorTemplate = self.subviews[1];
        self.durationForStopWithAnimation = 0.2f;
        
        //debug progress bar bug
        /*CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
        CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
        CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
        UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:0.7];
        [self.progressIndicator setBackgroundColor:color];*/
    }
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
    return self;
}

-(void)cleanup
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    // Main timer
    [self.mainTimer invalidate];
    self.mainTimer = nil;
    
    // Events timers
    if (self.timers) {
        for (NSTimer *timer in self.timers) {
            [timer invalidate];
        }
        [self.timers removeAllObjects];
        self.timers = nil;
    }
    
    // Events temp subviews
    if (self.eventsIndicatorsViews) {
        for (UIView *view in self.eventsIndicatorsViews) {
            [view removeFromSuperview];
        }
        [self.eventsIndicatorsViews removeAllObjects];
        self.eventsIndicatorsViews = nil;
    }
    
    // Lower the running flag.
    _isRunning = NO;
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

#pragma mark - Start and stop
-(void)start
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    // Ignore if already running.
    if (self.isRunning)
    {
      [self stop];  
    }
    
    _isRunning = YES;
    [self initGUI];
    [self initializeEvents];
    [self startAnimations];
    [self startTheClock];
    [self showAnimated:YES];

    // Starting time and inform delegate
    _startingTime = [NSDate date];
    [self.delegate timeProgressDidStartAtTime:self.startingTime forDuration:self.duration];
    HMGLogDebug(@"delegate: progress started at:%@ for duration:%.02f", self.startingTime, self.duration);
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)stop
{
    [self stopAnimated:NO];
}

-(void)stopAnimated:(BOOL)animated
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (!self.isRunning) return;
    [self.mainTimer invalidate];

    NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:self.startingTime];
    [self.delegate timeProgressWasCancelledAfterDuration:timePassed];
    HMGLogDebug(@"delegate: progress stopped after duration:%.02f", timePassed);
    
    if (!animated) {
        [self.progressIndicator.layer removeAllAnimations];
        if (self.hidesAutomatically) {
            [self hideAnimated:YES cleanUp:YES];
        } else {
            [self cleanup];
        }
        HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
        return;
    }
    
    self.progressIndicator.frame = [self.progressIndicator.layer.presentationLayer frame];
    [UIView animateWithDuration:self.durationForStopWithAnimation delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.progressIndicator.frame = self.endFrame;
    } completion:^(BOOL finished) {
        [self.progressIndicator.layer removeAllAnimations];
        if (self.hidesAutomatically) {
            [self hideAnimated:YES cleanUp:YES];
        } else {
            [self cleanup];
        }
        
        if ([self.delegate respondsToSelector:@selector(timeProgressDidFinishAnimationAfterStop)]) {
            [self.delegate timeProgressDidFinishAnimationAfterStop];
        }

        HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
        return;        
    }];
}

-(void)done
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:self.startingTime];
    [self.delegate timeProgressDidFinishAfterDuration:timePassed];
    HMGLogDebug(@"delegate: progress finished after duration:%.02f", timePassed);
    if (self.hidesAutomatically) {
        [self hideAnimated:YES cleanUp:YES];
    } else {
        [self cleanup];
    }
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)dealloc
{
    [self cleanup];
}

-(void)showAnimated:(BOOL)animated
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (!animated) {
        self.alpha = 1;
        return;
    }
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 1;
    }];
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)hideAnimated:(BOOL)animated cleanUp:(BOOL)cleanUp
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (!animated) {
        self.alpha = 0;
        return;
    }
    [UIView animateWithDuration:0.1 animations:^{
        self.alpha = 0;
    }];
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
    
}

-(void)hideAnimated:(BOOL)animated
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    [self hideAnimated:animated cleanUp:NO];
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

#pragma mark - Main Timer
-(void)startTheClock
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    [self.mainTimer invalidate];
    self.mainTimer = [NSTimer scheduledTimerWithTimeInterval:self.duration
                                                      target:self
                                                    selector:@selector(onMainTimerDone:)
                                                    userInfo:nil
                                                     repeats:NO
                                            ];
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)onMainTimerDone:(NSTimer *)timer
{
    [self done];
}

#pragma mark - GUI initializations
-(void)initGUI
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    self.eventIndicatorTemplate.hidden = YES;
    
    _width = self.bounds.size.width;
    _height = self.bounds.size.height;
    
    // Starting frame.
    CGRect f = self.progressIndicator.frame;
    f.size.width = 0;
    f.origin.x = 0;
    _startingFrame = f;
    
    // End frame
    f.size.width = self.width;
    _endFrame = f;
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

#pragma mark - Progress animation
-(void)startAnimations
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    self.progressIndicator.frame = self.startingFrame;
    HMGLogDebug(@"duration of animation is: %f. starting now!" , self.duration);
    [UIView animateWithDuration:self.duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.progressIndicator.frame = self.endFrame;
    } completion:^(BOOL finished)
     {
         HMGLogDebug(@"animation completed");
     }];
    
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

#pragma mark - Handle events
-(void)initializeEvents
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (!self.timedEvents) return;
    
    if (self.eventIndicatorTemplate) self.eventsIndicatorsViews = [NSMutableArray new];
    self.timers = [NSMutableArray new];
    
    for (NSInteger i=0;i<self.timedEvents.count;i++) {
        // Create a timer for each event.
        NSNumber *eventTimeNumber = self.timedEvents[i];
        NSTimeInterval eventTime = eventTimeNumber.doubleValue;
        [self scheduleEventAtTime:eventTime atIndex:i];
        
        // Create a simple view indicator for each event.
        [self addIndicatorAtTime:eventTime atIndex:i];
    }
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)scheduleEventAtTime:(NSTimeInterval)eventTime atIndex:(NSInteger)index
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:eventTime
                                                      target:self
                                                    selector:@selector(onEventEncountered:)
                                                    userInfo:@(index)
                                                     repeats:NO
                      ];
    [self.timers addObject:timer];
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)addIndicatorAtTime:(NSTimeInterval)eventTime atIndex:(NSInteger)index
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    if (!self.eventsIndicatorsViews) return;
    UIView *newView = [UIView new];
    UIView *tpl = self.eventIndicatorTemplate;
    
    // Copy some attributes
    newView.frame = tpl.bounds;
    newView.backgroundColor = tpl.backgroundColor;
    newView.alpha = tpl.alpha;
    newView.layer.cornerRadius = tpl.layer.cornerRadius;

    // Position the indicator
    double timePortion = eventTime / self.duration;
    double x = self.width * timePortion;
    double y = self.height / 2.0;
    newView.center = CGPointMake(x, y);
    
    [self.eventsIndicatorsViews addObject:newView];
    [self addSubview:newView];
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);
}

-(void)onEventEncountered:(NSTimer *)timer
{
    HMGLogDebug(@"%s started", __PRETTY_FUNCTION__);
    NSInteger index = [timer.userInfo integerValue];
    
    // Animate the event indicator.
    if (self.eventsIndicatorsViews) {
        UIView *view = self.eventsIndicatorsViews[index];
        [UIView animateWithDuration:0.1 animations:^{
            view.transform = CGAffineTransformMakeScale(1.5, 1.5);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                view.transform = CGAffineTransformMakeScale(0, 0);
                view.alpha = 0;
            } completion:^(BOOL finished) {
                view.hidden = YES;
            }];
        }];
    }
    
    // If delegate implemented the needed method, inform the delegate about the event encountered.
    if ([self.delegate respondsToSelector:@selector(timeProgressDidEncounterEventIndex:afterDuration:)]) {
        NSTimeInterval timePassed = [[NSDate date] timeIntervalSinceDate:self.startingTime];
        [self.delegate timeProgressDidEncounterEventIndex:index afterDuration:timePassed];
        HMGLogDebug(@"delegate: progress encountered event %d after duration:%.02f", index, timePassed);
    }
    HMGLogDebug(@"%s finished", __PRETTY_FUNCTION__);

}

@end
