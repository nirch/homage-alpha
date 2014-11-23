//
//  DB.h
//  General Project
//
//  Created by Aviv Wolf on 12/2/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

@import CoreData;

#import "InfoKeys.h"

#import "MyManagedDocument.h"

#import "Story+Factory.h"
#import "Story+Logic.h"

#import "Remake+Factory.h"
#import "Remake+Logic.h"

#import "User+Factory.h"
#import "User+Logic.h"

#import "Scene+Factory.h"
#import "Scene+Logic.h"

#import "Text+Factory.h"
#import "Text+Logic.h"

#import "Footage+Factory.h"
#import "Footage+Logic.h"

#import "Contour+Factory.h"

@interface DB : NSObject

/* The managed document and managed object context used when buidling the core data stack. */
@property (readonly, nonatomic) MyManagedDocument *dbDocument;
@property (readonly, nonatomic) NSManagedObjectContext *context;

// Singleton
+(DB *)sharedInstance;
+(DB *)sh;

// Managed document create/open/save.
-(void)useDocument;
-(void)useDocumentWithSuccessHandler:(void (^)())successHandler failHandler:(void (^)())failHandler;
-(void)save;

// Helper methods
-(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
-(id)fetchOrCreateEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

// In memory context for testing the model in memory (no persistance)
-(NSManagedObjectContext *)inMemoryContextForTestsFromBundles:(NSArray *)bundles;


@end
