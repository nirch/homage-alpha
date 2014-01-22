//
//  AWTimeProgressDelegate.h
//  Aviv Wolf
//
//  Created by Aviv Wolf on 2/21/13.
//  Copyright (c) 2014 interactive Wolf. All rights reserved.
//

@protocol AWTimeProgressDelegate <NSObject>

-(void)timeProgressDidStartAtTime:(NSDate *)time forDuration:(NSTimeInterval)duration;
-(void)timeProgressWasCancelledAfterDuration:(NSTimeInterval)duration;
-(void)timeProgressDidFinishAfterDuration:(NSTimeInterval)duration;

@optional
-(void)timeProgressDidEncounterEventIndex:(NSInteger)index afterDuration:(NSTimeInterval)duration;

@end
