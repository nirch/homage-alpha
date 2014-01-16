//
//  HMRemakerProtocol.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Remake;

@protocol HMRemakerProtocol <NSObject>

@property (nonatomic) Remake *remake;
@property (nonatomic, readonly) NSNumber *currentSceneID;

-(void)toggleOptions;
-(void)dismissMessagesOverlay;

@end
