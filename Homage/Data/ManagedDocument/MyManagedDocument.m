//
//  MyManagedDocument.m
//  
//
//  Created by Aviv Wolf on 10/15/12.
//

@import CoreData;
#import "MyManagedDocument.h"

@implementation MyManagedDocument

// Log when auto saving.
-(id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    HMGLogDebug(@"Auto-Saving Document.");
    return [super contentsForType:typeName error:outError];
}

// Capture errors.
- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSArray* errors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(errors != nil && errors.count > 0) {
        for (NSError *error in errors) {
            HMGLogWarning(@"MyManagedDocument Error:%@", [error localizedDescription]);
        }
    }
    [super handleError:error userInteractionPermitted:userInteractionPermitted];
}

-(NSURL *)fileURL
{
    NSURL *fileURL = [super fileURL];
    // Customize file url here if needed.
    //        NSURL* parentDirectory = [fileURL URLByDeletingLastPathComponent];
    //        NSString *fileName = [NSString stringWithFormat:@"%@DB", chosenLabelIdentifier];
    //        fileURL = [NSURL URLWithString:fileName relativeToURL:parentDirectory];
    return fileURL;
}

// Custom managed object contexts
-(NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *context = [super managedObjectContext];
    return context;
}

@end
