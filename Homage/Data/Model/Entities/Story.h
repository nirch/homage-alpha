//
//  Story.h
//  Homage
//
//  Created by Aviv Wolf on 1/25/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Remake, Scene, Text;

@interface Story : NSManagedObject

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * isPremium;
@property (nonatomic, retain) NSNumber * isSelfie;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * orderID;
@property (nonatomic, retain) NSNumber * remakesNumber;
@property (nonatomic, retain) NSString * shareMessage;
@property (nonatomic, retain) NSString * sID;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDecimalNumber * version;
@property (nonatomic, retain) NSString * videoURL;
@property (nonatomic, retain) NSNumber * wasPurchased;
@property (nonatomic, retain) NSNumber * sharingVideoAllowed;
@property (nonatomic, retain) NSSet *remakes;
@property (nonatomic, retain) NSSet *scenes;
@property (nonatomic, retain) NSSet *texts;
@end

@interface Story (CoreDataGeneratedAccessors)

- (void)addRemakesObject:(Remake *)value;
- (void)removeRemakesObject:(Remake *)value;
- (void)addRemakes:(NSSet *)values;
- (void)removeRemakes:(NSSet *)values;

- (void)addScenesObject:(Scene *)value;
- (void)removeScenesObject:(Scene *)value;
- (void)addScenes:(NSSet *)values;
- (void)removeScenes:(NSSet *)values;

- (void)addTextsObject:(Text *)value;
- (void)removeTextsObject:(Text *)value;
- (void)addTexts:(NSSet *)values;
- (void)removeTexts:(NSSet *)values;

@end
