//
//  HMServer+Likes.m
//  Homage
//
//  Created by Aviv Wolf on 10/27/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+Likes.h"
#import "HMNotificationCenter.h"
#import "HMRemakeParser.h"

@implementation HMServer (Likes)

-(void)likeRemakeWithID:(NSString *)remakeID userID:(NSString *)userID
{
    [self postRelativeURLNamed:@"like remake"
                    parameters:@{@"remake_id":remakeID, @"user_id":userID}
              notificationName:HM_NOTIFICATION_SERVER_USER_LIKED_REMAKE
                          info:@{@"remake_id":remakeID, @"user_id":userID, @"liked_remake":@YES}
                        parser:[HMRemakeParser new]
     ];
}

-(void)unlikeRemakeWithID:(NSString *)remakeID userID:(NSString *)userID
{
    [self postRelativeURLNamed:@"unlike remake"
                    parameters:@{@"remake_id":remakeID, @"user_id":userID}
              notificationName:HM_NOTIFICATION_SERVER_USER_UNLIKED_REMAKE
                          info:@{@"remake_id":remakeID, @"user_id":userID, @"liked_remake":@NO}
                        parser:[HMRemakeParser new]
     ];
}

@end
