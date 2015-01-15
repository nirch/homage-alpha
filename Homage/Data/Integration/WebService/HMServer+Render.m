//
//  HMServer+Render.m
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Render.h"
#import "HMNotificationCenter.h"
#import "HMRemakeParser.h"

@implementation HMServer (Render)

-(void)renderRemakeWithID:(NSString *)remakeID takeIDS:(NSArray *)takeIDS
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/render
    // Updates server that the user want the movie to be rendered.

    // Build Parameters
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    parameters[@"remake_id"] = remakeID;
    if (takeIDS) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:takeIDS
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        if (!error) {
            parameters[@"take_ids"] = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    
    // Post request
    [self postRelativeURLNamed:@"render"
                    parameters:parameters
              notificationName:HM_NOTIFICATION_SERVER_RENDER
                          info:@{@"remakeID":remakeID}
                        parser:[HMRemakeParser new]
     ];
}

@end
