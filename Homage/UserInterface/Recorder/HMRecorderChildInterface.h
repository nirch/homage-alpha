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


@protocol HMRecorderChildInterface <NSObject>

@property (nonatomic) id<HMRemakerProtocol>remakerDelegate;


@end
