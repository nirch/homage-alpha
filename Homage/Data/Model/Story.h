//
//  Story.h
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Remake, Scene, Text;

@interface Story : NSManagedObject

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * orderID;
@property (nonatomic, retain) NSString * sID;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSDecimalNumber * version;
@property (nonatomic, retain) NSString * videoURL;
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
