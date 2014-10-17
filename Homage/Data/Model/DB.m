//
//  DB.m
//  General Project
//
//  Created by Aviv Wolf on 12/2/13.
//  Copyright (c) 2013 PostPCDeveloper. All rights reserved.
//

#import "DB.h"

@interface DB()

@property (nonatomic, readonly) NSManagedObjectModel *memoryMOM;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *memoryPSC;
@property (nonatomic, readonly) NSManagedObjectContext *memoryCTX;

@end

@implementation DB

// DB is a singleton
+(DB *)sharedInstance
{
    static DB *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DB alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(DB *)sh
{
    return [DB sharedInstance];
}

-(DB *)init
{
    self = [super init];
    if (self != nil) {
        // Allocate document object
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"Default DB"];
        _dbDocument = [[MyManagedDocument alloc] initWithFileURL:url];
        
        // Auto migrate options
        self.dbDocument.persistentStoreOptions = @{
                                                   NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                   NSInferMappingModelAutomaticallyOption:@YES
                                                   };
    }
    return self;
}

#pragma mark - NSManagedObjectContext
// Get the context of the used dbDocument
-(NSManagedObjectContext *)context
{
    return [self.dbDocument managedObjectContext];
}

#pragma mark - In memory context for tests
-(NSManagedObjectContext *)inMemoryContextForTestsFromBundles:(NSArray *)bundles
{
    if (self.memoryCTX) return self.memoryCTX;
    
    // Managed object model
    _memoryMOM = [NSManagedObjectModel mergedModelFromBundles:bundles];

    // Persistance store coordinator
    _memoryPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.memoryMOM];
    
    // Managed object context
    _memoryCTX = [[NSManagedObjectContext alloc] init];
    self.memoryCTX.persistentStoreCoordinator = self.memoryPSC;
    
    // Return the context
    return self.memoryCTX;
}

#pragma mark - NSDocument
-(void)useDocument
{
    [self useDocumentWithSuccessHandler:nil failHandler:nil];
}

-(void)useDocumentWithSuccessHandler:(void (^)())successHandler failHandler:(void (^)())failHandler
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.dbDocument.fileURL path]]) {

        //
        // File needs to be created.
        //
        [self.dbDocument saveToURL:self.dbDocument.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            if (success) {
                HMGLogDebug(@"Created managed document.");
                if (successHandler) successHandler();
            } else {
                HMGLogWarning(@"Failed creating managed document.");
                if (failHandler) failHandler();
            }
        }];

    } else if (self.dbDocument.documentState == UIDocumentStateClosed){
        
        //
        // File exists but closed, needs to be opened.
        //
        [self.dbDocument openWithCompletionHandler:^(BOOL success) {
            if (success) {
                HMGLogDebug(@"Opened managed document.");
                if (successHandler) successHandler();
            } else {
                HMGLogWarning(@"Failed opening managed document.");
                if (failHandler) failHandler();
            }
        }];
        
    } else if (self.dbDocument.documentState == UIDocumentStateNormal) {

        //
        // File already opened.
        //
        HMGLogDebug(@"Managed document is already opened.");
        if (successHandler) successHandler();

    }
}

-(void)save
{
    [self.dbDocument updateChangeCount:UIDocumentChangeDone];
}

#pragma mark - Easier fetches
-(NSManagedObject *)fetchSingleEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;
    NSArray *results = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        HMGLogWarning(@"Error while searching for entity. %@",[error localizedDescription]);
        return nil;
    }
    return [self firstResult:results];
}

-(NSManagedObject *)firstResult:(NSArray *)results
{
    if (!results) return nil;
    if (results.count > 0) {
        return results[0];
    }
    return nil;
}

-(id)fetchOrCreateEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
    id entity;

    // Check if existing entity already exist in the store with the given ID.
    entity =  [self fetchSingleEntityNamed:entityName withPredicate:predicate inContext:context];
    if (entity) return entity;
    
    // Doesn't exist so should create a new one with the given sID.
    entity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
    return entity;
}

@end
