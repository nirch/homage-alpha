//
//  HMWhileRecordingOverlayViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/21/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMWhileRecordingOverlayViewController.h"
#import "HMNotificationCenter.h"
#import "AWTimeProgressView.h"

@interface HMWhileRecordingOverlayViewController ()

@property (weak, nonatomic) IBOutlet AWTimeProgressView *guiTimeProgressView;

@end

@implementation HMWhileRecordingOverlayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

#pragma mark - 
#pragma mark - Observers
-(void)initObservers
{
    // Observe started recording
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onStartRecording:)
                                                       name:HM_NOTIFICATION_RECORDER_START_RECORDING
                                                     object:nil];
    
    // Observe stop recording
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onStopRecording:)
                                                       name:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                     object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
}

#pragma mark - Observers handlers
-(void)onStartRecording:(NSNotification *)notification
{
    NSTimeInterval duration = [notification.userInfo[@"durationInSeconds"] doubleValue];
    self.guiTimeProgressView.duration = duration;
    self.guiTimeProgressView.delegate = self;

    // =======================================================================
    // An example of using the timed events feature of the AWTimeProgressView
    // self.guiTimeProgressView.timedEvents = @[@(1.5),@(2.6),@(4.5),@(7.2)];
    // =======================================================================
    
    [self.guiTimeProgressView start];
}

-(void)onStopRecording:(NSNotification *)notification
{
    // If user requested to stop the recording, also force the timer to stop.
    NSDictionary *info = notification.userInfo;
    if ([info[HM_INFO_KEY_RECORDING_STOP_REASON] integerValue] == HMRecordingStopReasonUserCanceled) {
        [self.guiTimeProgressView stop];
    }
}

#pragma mark - Timed Recording Progress (AWTimeProgressDelegate)
-(void)timeProgressDidStartAtTime:(NSDate *)time forDuration:(NSTimeInterval)duration
{
}

-(void)timeProgressDidFinishAfterDuration:(NSTimeInterval)duration
{
    //
    // User shot the video for the whole duration of the scene. Hazahh!
    // Need to notify everyone that "The recording should be stopped because it was successful".
    //
    NSDictionary *info = @{HM_INFO_KEY_RECORDING_STOP_REASON:@(HMRecordingStopReasonEndedSuccessfully)};
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                        object:self
                                                      userInfo:info];
    
}

-(void)timeProgressWasCancelledAfterDuration:(NSTimeInterval)duration
{
}

// =======================================================================
// An example of using the timed events feature of the AWTimeProgressView
//
//-(void)timeProgressDidEncounterEventIndex:(NSInteger)index afterDuration:(NSTimeInterval)duration
//{
//}
// =======================================================================


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedStopButton:(UIButton *)sender
{
    // If the user pressed the "Stop" button in the middle of recording,
    // then he in fact canceled that recording.
    // Post a notification for stopping the recording with the HM_INFO_KEY_RECORDING_STOPPED_REASON:@"" flag.
    NSDictionary *info = @{HM_INFO_KEY_RECORDING_STOP_REASON:@(HMRecordingStopReasonUserCanceled)};
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                        object:self
                                                      userInfo:info];
}



@end
