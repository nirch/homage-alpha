//
//  HMRemakeParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakeParser.h"


@implementation HMRemakeParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    [self parseRemake:info];
    [DB.sh save];
}

-(void)parseRemake:(NSDictionary *)info
{
    [self parseRemake:info updateTime:nil];
}

-(void)parseRemake:(NSDictionary *)info updateTime:(NSDate *)updateTime
{
    NSString *remakeID = info[@"_id"][@"$oid"];
    NSString *storyID = info[@"story_id"][@"$oid"];
    
    NSString *userID;
    if ([info[@"user_id"] isKindOfClass: [NSDictionary class]])
    {
        userID = info[@"user_id"][@"$oid"];
    } else
    {
        userID = [info stringForKey:@"user_id"];
    }

    NSDate *lastLocalUpdate = updateTime ? updateTime : [NSDate date];
    Story *story = [Story storyWithID:storyID inContext:self.ctx];
    User *user = [User userWithID:userID inContext:self.ctx];
    
    Remake *remake = [Remake remakeWithID:remakeID story:story user:user inContext:self.ctx];
    remake.status = [info numberForKey:@"status"];
    
    CLEAR_CACHE_CHECK(remake,thumbnailURL,thumbnail,@"thumbnail"); // clear remake.thumbnail if url changed
    remake.thumbnailURL = [info stringForKey:@"thumbnail"];
    remake.videoURL = [info stringForKey:@"video"];
    remake.shareURL = [info stringForKey:@"share_link"];
    
    remake.lastLocalUpdate = lastLocalUpdate;
    self.parseInfo[@"remakeID"] = remakeID;
    
    for (NSDictionary *footageInfo in info[@"footages"]) {
        [self parseFootage:footageInfo forRemake:remake];
    }
}


-(void)parseFootage:(NSDictionary *)info forRemake:(Remake *)remake
{
    NSNumber *sceneID =                 [info numberForKey:@"scene_id"];
    Footage *footage =                  [remake footageWithSceneID:sceneID];
    if (!footage) return;
    
    footage.processedVideoS3Key =       [info stringForKey:@"processed_video_s3_key"];
    footage.rawVideoS3Key =             [info stringForKey:@"raw_video_s3_key"];
    footage.status =                    [info numberForKey:@"status"];
}

@end









