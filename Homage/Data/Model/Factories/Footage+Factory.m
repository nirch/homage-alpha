//
//  Footage+Factory.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage+Factory.h"
#import "DB.h"

@implementation Footage (Factory)

+(Footage *)newFootageWithSceneID:(NSNumber *)sID remake:(Remake *)remake inContext:(NSManagedObjectContext *)context
{
    // Ensure related story has the related sceneID
    if (![remake.story hasSceneWithID:sID]) {
        HMGLogError(@"Wrong scene ID (%@) for this remake (%@) when creatiing new footage.", sID, remake.sID);
        return nil;
    }

    // Create new footage related to the scene id and remake.
    Footage *footage = [NSEntityDescription insertNewObjectForEntityForName:HM_FOOTAGE inManagedObjectContext:context];
    footage.sceneID = sID;
    footage.remake = remake;
    return footage;
}

-(Scene *)relatedScene
{
    return [self.remake.story findSceneWithID:self.sceneID];
}

-(NSString *)generateNewRawFileName
{
    NSString *fileName = [NSString stringWithFormat:@"%@_%@_%f.mp4", self.remake.sID, self.sceneID, [[NSDate date] timeIntervalSince1970]];
    return fileName;
}

-(void)deleteRawLocalFile
{
    if (!self.rawLocalFile) return;

    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:self.rawLocalFile error:&error];
    if (error) {
        HMGLogWarning(@"Failed to delete local file %@", self.rawLocalFile);
    }
    self.rawLocalFile = nil;
}


@end
