//
//  HMRemakeParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRemakeParser.h"
#import "DB.h"

@implementation HMRemakeParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    [self parseRemake:info];
    [DB.sh save];
}

-(void)parseRemake:(NSDictionary *)info
{
    NSString *remakeID = info[@"_id"][@"$oid"];
    NSString *storyID = info[@"story_id"][@"$oid"];
    NSString *userID = [info stringForKey:@"user_id"];
    Story *story = [Story storyWithID:storyID inContext:self.ctx];
    User *user = [User userWithID:userID inContext:self.ctx];
    
    Remake *remake = [Remake remakeWithID:remakeID story:story user:user inContext:self.ctx];
    remake.status = [info numberForKey:@"status"];
    remake.thumbnailURL = [info stringForKey:@"thumbnail"];
    remake.videoURL = [info stringForKey:@"video"];
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

/**
{
    "_id" =     {
        "$oid" = 52d69383db254512f4000002;
    };
    footages =     (
                    {
                        "processed_video_s3_key" = "Remakes/52d69383db254512f4000002/processed_scene_1.mov";
                        "raw_video_s3_key" = "Remakes/52d69383db254512f4000002/raw_scene_1.mov";
                        "scene_id" = 1;
                        status = 0;
                    },
                    {
                        "processed_video_s3_key" = "Remakes/52d69383db254512f4000002/processed_scene_2.mov";
                        "raw_video_s3_key" = "Remakes/52d69383db254512f4000002/raw_scene_2.mov";
                        "scene_id" = 2;
                        status = 0;
                    },
                    {
                        "processed_video_s3_key" = "Remakes/52d69383db254512f4000002/processed_scene_3.mov";
                        "raw_video_s3_key" = "Remakes/52d69383db254512f4000002/raw_scene_3.mov";
                        "scene_id" = 3;
                        status = 0;
                    },
                    {
                        "processed_video_s3_key" = "Remakes/52d69383db254512f4000002/processed_scene_4.mov";
                        "raw_video_s3_key" = "Remakes/52d69383db254512f4000002/raw_scene_4.mov";
                        "scene_id" = 4;
                        status = 0;
                    }
                    );
    status = 0;
    "story_id" =     {
        "$oid" = 52cddaf80fad07c3290001aa;
    };
    thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Star_Wars_Thumbnail.png";
    "user_id" = @'test@gmail.com';
}
*/









