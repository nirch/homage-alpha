//
//  HMServer+Footages.m
//  Homage
//
//  Created by Aviv Wolf on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Footages.h"
#import "HMNotificationCenter.h"
#import "HMRemakeParser.h"

@implementation HMServer (Footages)

-(void)updateOnSuccessFootageForRemakeID:(NSString *)remakeID
                                 sceneID:(NSNumber *)sceneID
                                  takeID:(NSString *)takeID
                            attemptCount:(NSInteger)attemptCount
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/footage
    // Updates server that the footage related to this remake and scene is ready.
    [self postRelativeURLNamed:@"footage"
                    parameters:@{@"remake_id":remakeID, @"scene_id":sceneID.stringValue , @"take_id" : takeID}
              notificationName:HM_NOTIFICATION_SERVER_FOOTAGE_UPLOAD_SUCCESS
                          info:@{@"remakeID":remakeID,@"sceneID":sceneID,@"takeID":takeID,@"attemptCount":@(attemptCount)}
                        parser:[HMRemakeParser new]];
}

-(void)updateOnUploadStartFootageForRemakeID:(NSString *)remakeID
                                     sceneID:(NSNumber *)sceneID
                                      takeID:(NSString *)takeID
                                attemptCount:(NSInteger)attemptCount
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/footage
    // Updates server that the footage related to this remake should be uploaded (and ignore previously uploaded videos)
    [self putRelativeURLNamed:@"footage"
                   parameters:@{@"remake_id":remakeID, @"scene_id":sceneID.stringValue , @"take_id" : takeID}
             notificationName:HM_NOTIFICATION_SERVER_FOOTAGE_UPLOAD_START
                         info:@{@"remakeID":remakeID,@"sceneID":sceneID,@"takeID":takeID, @"attemptCount":@(attemptCount)}
                       parser:[HMRemakeParser new]];
}

@end
