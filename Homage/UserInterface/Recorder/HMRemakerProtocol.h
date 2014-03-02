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
    HMRecordingStopReasonEndedSuccessfully,
    HMRecordingStopReasonCameraNotStable
};

typedef NS_ENUM(NSInteger, HMRemakerUpdateType) {
    HMRemakerUpdateTypeCreateMovie,
    HMRemakerUpdateTypeCreateMovieSuccessfulResponse,
    HMRemakerUpdateTypeScriptToggle,
    HMRemakerUpdateTypeRetakeScene,
    HMRemakerUpdateTypeCancelEditingTexts,
    HMRemakerUpdateTypeEpicFailErrorMessage,
    HMRemakerUpdateTypeSelectSceneAndPrepareToShoot
};

///
/**
*  Defines the flow of the recorder states.
*/
typedef NS_ENUM(NSInteger, HMRecorderState) {
    /**
     *  0 - The recorder was just opened.
     */
    HMRecorderStateJustStarted,
    /**
     *  1 - The introduction message displayed to the user.
     */
    HMRecorderStateGeneralMessage,
    /**
     *  2 - A description message for the user about the current scene to retake.
     */
    HMRecorderStateSceneContextMessage,
    /**
     *  3 - The user get controls of the flow where he can retake current or previous scenes.
     */
    HMRecorderStateMakingAScene,
    /**
     *  4 - The user created a take successfully for the current scene.
     */
    HMRecorderStateFinishedASceneMessage,
    /**
     *  5 - The user created takes for all the available scenes in this remake but she needs to edit texts.
     *  Before being able to create the movie.
     */
    HMRecorderStateEditingTexts,
    /**
     *  6 - The user created takes for all the available scenes in this remake.
     */
    HMRecorderStateFinishedAllScenesMessage,
    /**
    *  7 - Some user interaction requires the state machine to determine what next.
    */
    HMRecorderStateUserRequestToCheckWhatNext,
    /**
     * 8 - Help screen explaining some UI elements to the user
     */
    HMRecorderStateHelpScreens
};

@protocol HMRemakerProtocol <NSObject>

@property (nonatomic) Remake *remake;
@property (nonatomic, readonly) NSNumber *currentSceneID;
//THE HAND!!!
@property (nonatomic, readonly) BOOL showHand;

-(void)toggleOptions;

-(void)dismissOverlay;
-(void)dismissOverlayAdvancingState:(BOOL)advancingState;
-(void)dismissOverlayAdvancingState:(BOOL)advancingState info:(NSDictionary *)info;
-(void)dismissOverlayAdvancingState:(BOOL)advancingState fromState:(HMRecorderState)fromState info:(NSDictionary *)info;

@optional
-(CGAffineTransform)minimizedSceneDirectionTransform;
-(void)updateWithUpdateType:(HMRemakerUpdateType)updateType info:(NSDictionary *)info;
-(void)updateUIForCurrentScene;
-(void)selectSceneID:(NSNumber *)sceneID;
-(void)showSceneContextMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info;

@end
