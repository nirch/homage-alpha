//
//  HMServer+Likes.h
//  Homage
//
//  Created by Aviv Wolf on 10/27/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Likes)

-(void)likeRemakeWithID:(NSString *)remakeID userID:(NSString *)userID;
-(void)unlikeRemakeWithID:(NSString *)remakeID userID:(NSString *)userID;

@end
