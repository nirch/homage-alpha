//
//  HMRecorderMessagesOverlayViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderChildInterface.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, HMRecorderMessagesType) {
    HMRecorderMessagesTypeGeneral,
    HMRecorderMessagesTypeSceneContext,
    HMRecorderMessagesTypeFinishedScene,
    HMRecorderMessagesTypeFinishedAllScenes,
    HMRecorderMessagesTypeAreYouSureYouWantToRetakeScene,
    HMRecorderMessagesTypeBigImage
};

@interface HMRecorderMessagesOverlayViewController : UIViewController<
    HMRecorderChildInterface,
    AVAudioPlayerDelegate
>

///
/**
*   Shows an overlay of a specic type on top of the recorder. Used for different overlay UI on top of the recorder.
*
*  @param messageType             The type of the message. SeeH MRecorderMessagesType enum for options.
*  @param checkNextStateOnDismiss If yes, the delegate remaker will check it's next state on dismissal of this overlay.
*  @param info                    Some more details specific to each type of message type.
*/
-(void)showMessageOfType:(HMRecorderMessagesType)messageType checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info;



@end
