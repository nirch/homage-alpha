//
//  HMRecorderChildInterface.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakerProtocol.h"

#define HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSING        @"Recorder detailed options closing"
#define HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED         @"Recorder detailed options closed"
#define HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENING        @"Recorder detailed options opening"
#define HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENED         @"Recorder detailed options opened"

#define HM_UI_NOTIFICATION_RECORDER_CURRENT_SCENE                   @"Recorder current scene"

// START and STOP mean a request to start a recording operation / a request to stop a recording operation.
// Can be sent by a user request, by a successful recording or by an error during recording.
// Don't use these notifications to inform that a recording was stopped.
#define HM_NOTIFICATION_RECORDER_START_RECORDING                    @"Recorder Start Recording"
#define HM_NOTIFICATION_RECORDER_STOP_RECORDING                     @"Recorder Stop Recording"
#define HM_NOTIFICATION_RECORDER_START_COUNTDOWN_BEFORE_RECORDING   @"Recorder Start Countdown Before Recording"
#define HM_NOTIFICATION_RECORDER_CANCEL_COUNTDOWN_BEFORE_RECORDING  @"Recorder Cancel Countdown Before Recording"


#define HM_NOTIFICATION_RECORDER_FLIP_CAMERA                        @"Recorder Flip Camera"
#define HM_NOTIFICATION_RECORDER_USING_FRONT_CAMERA                 @"Recorder Using Front Camera"
#define HM_NOTIFICATION_RECORDER_USING_BACK_CAMERA                  @"Recorder Using Back Camera"


#define HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE         @"Recorder Raw Footage Available"
#define HM_NOTIFICATION_RECORDER_EPIC_FAIL                          @"Recorder Epic Fail"

@protocol HMRecorderChildInterface <NSObject>

@optional

@property (nonatomic, weak) id<HMRemakerProtocol>remakerDelegate;


@end
