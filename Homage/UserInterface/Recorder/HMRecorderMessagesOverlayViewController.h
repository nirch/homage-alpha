//
//  HMRecorderMessagesOverlayViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderChildInterface.h"

typedef NS_ENUM(NSInteger, HMRecorderMessagesType) {
    HMRecorderMessagesTypeGeneral,
    HMRecorderMessagesTypeSceneContext,
    HMRecorderMessagesTypeFinishedScene,
    HMRecorderMessagesTypeAreYouSureYouWantToRetakeScene
};

@interface HMRecorderMessagesOverlayViewController : UIViewController<
    HMRecorderChildInterface
>

-(void)showMessageOfType:(HMRecorderMessagesType)messageType info:(NSDictionary *)info;

@end
