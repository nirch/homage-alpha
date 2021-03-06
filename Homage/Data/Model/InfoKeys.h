//
//  InfoKeys.h
//  Homage
//
//  Created by Aviv Wolf on 1/30/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

// User info
#define HM_INFO_REMAKE_ID                           @"remakeID"
#define HM_INFO_FILE_NAME                           @"fileName"
#define HM_INFO_SHOULD_RECORD_AUDIO                 @"shouldRecordAudio"
#define HM_INFO_SCENE_ID                            @"sceneID"
#define HM_INFO_FOOTAGE_IDENTIFIER                  @"footageIdentifier"    // A long identifier in the following format <remakeID>_<sceneID>
#define HM_INFO_DURATION_IN_SECONDS                 @"durationInSeconds"
#define HM_INFO_PROGRESS                            @"progress"
#define HM_INFO_FOCUS_POINT                         @"focusPoint"           // passed around as @[NSNumber,NSNumber]
#define HM_INFO_SHOULD_RECORD_AUDIO                 @"shouldRecordAudio"    // boolean value indicating if needs to record video or not.
#define HM_INFO_OUTPUT_RESOLUTION                   @"outputResolution"     // A NSNumber of output video height. Supported values: 360, 720, 1080