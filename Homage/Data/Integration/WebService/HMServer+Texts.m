//
//  HMServer+Texts.m
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Texts.h"
#import "HMNotificationCenter.h"
#import "HMTextUpdateParser.h"

@implementation HMServer (Texts)

-(void)updateText:(NSString *)text forRemakeID:(NSString *)remakeID textID:(NSNumber *)textID;
{
    // A simple POST request to the server
    // Example URL: http://54.204.34.168:4567/footage
    // Updates server that the footage related to this remake and scene is ready.
    [self postRelativeURLNamed:@"text"
                    parameters:@{@"text":text, @"remake_id":remakeID, @"text_id":textID.stringValue}
              notificationName:HM_NOTIFICATION_SERVER_TEXT
                          info:@{@"text":text, @"remakeID":remakeID,@"textID":textID}
                        parser:[HMTextUpdateParser new]
     ];
}

@end
