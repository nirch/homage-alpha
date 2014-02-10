//
//  Remake.h
//  Homage
//
//  Created by Tomer Harry on 2/10/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Footage, Story, User;

@interface Remake : NSManagedObject

@property (nonatomic, retain) NSDate * lastLocalUpdate;
@property (nonatomic, retain) NSString * sID;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) id texts;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * videoURL;
@property (nonatomic, retain) NSString * shareURL;
@property (nonatomic, retain) NSSet *footages;
@property (nonatomic, retain) Story *story;
@property (nonatomic, retain) User *user;
@end

@interface Remake (CoreDataGeneratedAccessors)

- (void)addFootagesObject:(Footage *)value;
- (void)removeFootagesObject:(Footage *)value;
- (void)addFootages:(NSSet *)values;
- (void)removeFootages:(NSSet *)values;

@end
