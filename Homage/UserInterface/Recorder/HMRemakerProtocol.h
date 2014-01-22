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

@protocol HMRemakerProtocol <NSObject>

@property (nonatomic) Remake *remake;
@property (nonatomic, readonly) NSNumber *currentSceneID;

-(void)toggleOptions;
-(void)dismissMessagesOverlay;

@optional
-(void)selectSceneID:(NSNumber *)sceneID;
-(void)showSceneContextMessageForSceneID:(NSNumber *)sceneID;

@end
