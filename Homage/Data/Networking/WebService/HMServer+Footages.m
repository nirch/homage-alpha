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

-(void)updateFootageForRemakeID:(NSString *)remakeID sceneID:(NSNumber *)sceneID
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/footage
    // Updates server that the footage related to this remake and scene is ready.
    [self postRelativeURLNamed:@"footage"
                    parameters:@{@"remake_id":remakeID, @"scene_id":sceneID.stringValue}
              notificationName:HM_NOTIFICATION_SERVER_FOOTAGE
                          info:@{@"remakeID":remakeID,@"sceneID":sceneID}
                        parser:[HMRemakeParser new]
     ];
}

@end
