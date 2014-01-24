//
//  Footage+Logic.m
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage+Logic.h"
#import "DB.h"

@implementation Footage (Logic)


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
