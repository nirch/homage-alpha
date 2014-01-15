//
//  DB.h
//  General Project
//
//  Created by Aviv Wolf on 12/2/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

@import CoreData;
#import "MyManagedDocument.h"

#import "Story+Factory.h"
#import "Remake+Factory.h"
#import "User+Factory.h"
#import "Scene+Factory.h"
#import "Text+Factory.h"
#import "Footage+Factory.h"

// Entities names
#define HM_SCENE        @"Scene"
#define HM_TEXT         @"Text"
#define HM_REMAKE       @"Remake"
#define HM_USER         @"User"
#define HM_FOOTAGE      @"Footage"

@interface DB : NSObject

/* The managed document and managed object context used when buidling the core data stack. */
@property (readonly, nonatomic) MyManagedDocument *dbDocument;
@property (readonly, nonatomic) NSManagedObjectContext *context;

+(DB *)sharedInstance;
+(DB *)sh;

-(void)useDocument;
-(void)useDocumentWithSuccessHandler:(void (^)())successHandler failHandler:(void (^)())failHandler;
-(void)save;

-(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
-(id)fetchOrCreateEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

@end
