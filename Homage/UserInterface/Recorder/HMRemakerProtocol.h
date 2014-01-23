//
//  HMRemakerProtocol.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Remake;

#define HM_INFO_KEY_RECORDING_STOP_REASON    @"Recording Stop Reason"

typedef NS_ENUM(NSInteger, HMRecordingStopReason) {
    HMRecordingStopReasonUserCanceled,
    HMRecordingStopReasonEndedSuccessfully
};

typedef NS_ENUM(NSInteger, HMRecorderState) {
    HMRecorderStateJustStarted,
    HMRecorderStateGeneralMessage,
    HMRecorderStateSceneContextMessage,
    HMRecorderStateMakingAScene,
    HMRecorderStateFinishedASceneMessage,
    HMRecorderStateFinishedAllScenesMessage
};

@protocol HMRemakerProtocol <NSObject>

@property (nonatomic) Remake *remake;
@property (nonatomic, readonly) NSNumber *currentSceneID;

-(void)toggleOptions;
-(void)dismissMessagesOverlay;
-(void)dismissMessagesOverlayAndCheckNextState:(BOOL)checkNextState;
-(void)dismissMessagesOverlayWithRecorderState:(HMRecorderState)recorderState checkNextState:(BOOL)checkNextState;

@optional
-(void)updateUIForCurrentScene;
-(void)selectSceneID:(NSNumber *)sceneID;
-(void)showSceneContextMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss;

@end
