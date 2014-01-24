//
//  HMServer+Render.m
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Render.h"
#import "HMNotificationCenter.h"

@implementation HMServer (Render)

-(void)renderRemakeWithID:(NSString *)remakeID
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/render
    // Updates server that the user want the movie to be rendered.
    [self postRelativeURLNamed:@"render"
                    parameters:@{@"remake_id":remakeID}
              notificationName:HM_NOTIFICATION_SERVER_RENDER
                          info:@{@"remakeID":remakeID}
                        parser:nil
     ];
}

@end
