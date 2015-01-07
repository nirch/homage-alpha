//
//  HMWhileRecordingOverlayViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/21/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@import AVFoundation;

#import "HMWhileRecordingOverlayViewController.h"
#import "HMNotificationCenter.h"
#import "AWTimeProgressView.h"
#import "HMMotionDetectorDelegate.h"
#import "DB.h"
#import "HMMotionDetector.h"
#import "HMCacheManager.h"
#import "HMStyle.h"

@interface HMWhileRecordingOverlayViewController ()

@property (weak, nonatomic) IBOutlet AWTimeProgressView *guiTimeProgressView;
@property (weak, nonatomic) IBOutlet UIView *guiScriptContainer;
@property (weak, nonatomic) IBOutlet UILabel *guiScriptLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiProcessingActivity;
@property (weak, nonatomic) IBOutlet UILabel *guiProcessingLabel;

@property (nonatomic, readonly) Remake *remake;
@property (nonatomic, readonly) Scene *scene;

// Playing audio
@property (strong,nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) AVAudioPlayer *sceneAudioPlayer;

@end

@implementation HMWhileRecordingOverlayViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}


-(void)initGUI
{
    self.view.backgroundColor = [UIColor clearColor];

    // ************
    // *  STYLES  *
    // ************
    self.guiTimeProgressView.indicatorTintColor = [HMStyle.sh colorNamed:C_RECORDER_RECORDING_PROGRESS_BAR];
}

#pragma mark - Script UI
-(void)update
{
    _remake = [self.remakerDelegate remake];
    _scene = [self.remake.story findSceneWithID:[self.remakerDelegate currentSceneID]];
}

-(void)updateUI
{
    [self.guiProcessingActivity stopAnimating];
    self.guiProcessingLabel.hidden = YES;
    if (User.current.prefersToSeeScriptWhileRecording.boolValue && self.scene.hasScript) {
        self.guiScriptContainer.hidden = NO;
        self.guiScriptLabel.text = self.scene.script;
    } else {
        self.guiScriptContainer.hidden = YES;
        self.guiScriptLabel.text = @"";
    }
}

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
    
    [self update];
    [self updateUI];
    [self.guiTimeProgressView start];
    
    // Some scenes play audio in the background during recording.
    if (self.scene.sceneAudioURL)
        [self playSceneAudioWhileRecording];
}

-(void)playSceneAudioWhileRecording
{
    [self stopPlayingSceneAudio];
    if (self.scene.sceneAudioURL == nil) return;
    
    NSString *url = self.scene.sceneAudioURL;
    NSError *error;
    NSURL *soundURL = [HMCacheManager.sh urlForAudioResource:url];
    self.sceneAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    [self.sceneAudioPlayer prepareToPlay];
    [self.sceneAudioPlayer play];
}

-(void)stopPlayingSceneAudio
{
    if (self.sceneAudioPlayer) {
        [self.sceneAudioPlayer stop];
        self.sceneAudioPlayer = nil;
    }
}

-(void)onStopRecording:(NSNotification *)notification
{
    // If user requested to stop the recording, also force the timer to stop.
    NSDictionary *info = notification.userInfo;
    NSInteger recordStopReason = [info[HM_INFO_KEY_RECORDING_STOP_REASON] integerValue];
    if ( recordStopReason == HMRecordingStopReasonUserCanceled || recordStopReason == HMRecordingStopReasonCameraNotStable || recordStopReason == HMRecordingStopReasonAppWentToBackground) {
        [self.guiTimeProgressView stop];
    }

    // Some scenes play audio in the background during recording.
    if (self.scene.sceneAudioURL)
        [self stopPlayingSceneAudio];
}

-(void)playEndOfDurationSound
{
    NSError *error;
    NSURL *soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"recordingEnd" ofType:@"wav"]];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
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
//    NSDictionary *info = @{HM_INFO_KEY_RECORDING_STOP_REASON:@(HMRecordingStopReasonEndedSuccessfully)};
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_STOP_RECORDING
//                                                        object:self
//                                                      userInfo:info];
    
    
    // Play sound at the end of the duration
    [self playEndOfDurationSound];
    
    self.guiProcessingLabel.hidden = NO;
    [self.guiProcessingActivity startAnimating];
}

-(void)timeProgressWasCancelledAfterDuration:(NSTimeInterval)duration
{
}


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

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
