//
//  Text.h
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Story;

@interface Text : NSManagedObject

@property (nonatomic, retain) NSString * descriptionText;
@property (nonatomic, retain) NSNumber * maxCharacters;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * sID;
@property (nonatomic, retain) Story *story;

@end
