//
//  AWTimeProgressView.h
//  Aviv Wolf
//
//  Created by Aviv Wolf on 2/21/13.
//  Copyright (c) 2014 interactive Wolf. All rights reserved.
//

#import "AWTimeProgressDelegate.h"

@interface AWTimeProgressView : UIView

/**
 *  The color of the progress indicator.
 */
@property UIColor *indicatorTintColor;

///
/**
*  The duration from start till finish of the timed progress as NSTimeInterval.
*/
@property NSTimeInterval duration;

///
/**
 *  The duration for the animation after calling stopWithAnimation:YES
 */
@property NSTimeInterval durationForStopWithAnimation;

///
/**
*  Hides automatically when finished / stopped. NO by default.
*/
@property BOOL hidesAutomatically;

///
/**
*  A delegate conforming to the HMTimeProgressDelegate protocol.

*   Will call methods on the delegate on start, finish, stop and when events (if available) fire.
*/
@property id<AWTimeProgressDelegate> delegate;


///
/**
*  An optional array of NSNumber objects indicating timed events. Each number object represents the NSTimeInterval the event occurs on.
*/
@property NSArray *timedEvents;

///
/**
*  Read only property indicating if the timed progress is currently running (start was already called).
*/
@property (readonly) BOOL isRunning;

///
/**
*  Call to start the timed progress.
*   Make sure you initialize the duration first! (otherwise it is 60 seconds by default).
*/
-(void)start;

///
/**
*  Call to stop/cancel the progress before it is finished.
*/
-(void)stop;

///
/**
 *  Call to stop/cancel the progress before it is finished.
 *
 *  @param animated - A boolean value indicating if to animate the bar quickly to it's full state before stopping.
 *
 */
-(void)stopAnimated:(BOOL)animated;

@end
