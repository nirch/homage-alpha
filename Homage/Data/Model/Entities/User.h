//
//  User.h
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Remake;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSNumber * isFirstUse;
@property (nonatomic, retain) NSNumber * isLoggedIn;
@property (nonatomic, retain) NSNumber * isPublic;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSNumber * skipRecorderTutorial;
@property (nonatomic, retain) NSSet *remakes;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addRemakesObject:(Remake *)value;
- (void)removeRemakesObject:(Remake *)value;
- (void)addRemakes:(NSSet *)values;
- (void)removeRemakes:(NSSet *)values;

@end
