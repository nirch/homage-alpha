//
//  Scene.h
//  Homage
//
//  Created by Aviv Wolf on 10/21/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Story;

@interface Scene : NSManagedObject

@property (nonatomic, retain) NSString * context;
@property (nonatomic, retain) NSString * contourLocalURL;
@property (nonatomic, retain) NSString * contourRemoteURL;
@property (nonatomic, retain) NSString * directionAudioURL;
@property (nonatomic, retain) NSDecimalNumber * duration;
@property (nonatomic, retain) NSNumber * focusPointX;
@property (nonatomic, retain) NSNumber * focusPointY;
@property (nonatomic, retain) NSNumber * isSelfie;
@property (nonatomic, retain) NSString * postSceneAudio;
@property (nonatomic, retain) NSString * sceneAudioURL;
@property (nonatomic, retain) NSString * script;
@property (nonatomic, retain) NSNumber * sID;
@property (nonatomic, retain) NSString * silhouetteURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * videoURL;
@property (nonatomic, retain) NSNumber * uploadedResolution;
@property (nonatomic, retain) Story *story;

@end
