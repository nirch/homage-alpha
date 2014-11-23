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

    Story *story = [Story storyWithID:storyID inContext:self.ctx];
    User *user = [User userWithID:userID inContext:self.ctx];
    
    // If returned with statud deleted, just delete the remake from local storage (if exists).
    NSNumber *status = [info numberForKey:@"status"];
    if (status.integerValue == HMGRemakeStatusDeleted) {
        // Delete remake from local storage (if exists)
        Remake *remakeToDelete = [Remake findWithID:remakeID inContext:self.ctx];
        if (!remakeToDelete) return;
        [self.ctx deleteObject:remakeToDelete];
        [DB.sh save];
        return;
    }
    
    Remake *remake = [Remake remakeWithID:remakeID story:story user:user inContext:self.ctx];
    remake.status = [info numberForKey:@"status"];
    remake.thumbnailURL = [info stringForKey:@"thumbnail"];
    remake.videoURL = [info stringForKey:@"video"];
    remake.shareURL = [info stringForKey:@"share_link"];
    remake.grade = [info numberForKey:@"grade"] ? [info numberForKey:@"grade"] : [NSNumber numberWithInt:0];
    remake.stillPublic = @YES;
    remake.viewsCount = [info numberForKey:@"views"];
    remake.userFullName = [info stringForKey:@"user_fullname"];
    
    NSDate *lastLocalUpdate = updateTime ? updateTime : [NSDate date];
    remake.lastLocalUpdate = lastLocalUpdate;
    
    remake.createdAt = [self parseDateOfString:[info stringForKey:@"created_at"]];
    
    self.parseInfo[@"remakeID"] = remakeID;
    
    for (NSDictionary *footageInfo in info[@"footages"]) {
        [self parseFootage:footageInfo forRemake:remake];
    }
    
    //
    // Social
    //
    remake.likesCount = [info numberForKey:@"like_count"];
    
    // Likes for user
    // Used when parsing lots of remakes and checking if likes by a user id.
    NSString *likesForUserID = self.parseInfo[@"likesForUserID"];
    if (likesForUserID) {
        BOOL likedByThisUser = [[info boolNumberForKey:@"is_liked"] boolValue];
        if (likedByThisUser) {
            [remake likedByUserID:likesForUserID];
        } else {
            [remake unlikedByUserID:likesForUserID];
        }
    }
    
    // Liked / Unliked by user
    // Used when user just liked / unliked a specific remake
    NSNumber *justLikedOrUnlikedRemake = self.parseInfo[@"liked_remake"];
    if (justLikedOrUnlikedRemake) {
        BOOL isLiked = justLikedOrUnlikedRemake.boolValue;
        User *currentUser = User.current;
        if (isLiked) {
            [remake likedByUserID:currentUser.userID];
        } else {
            [remake unlikedByUserID:currentUser.userID];
        }
    }
}

-(NSDate *)parseDateOfString:(NSString *)dateString
{
    //"created_at" = "2014-03-09 14:30:13 UTC" <-- deprecated on server side
    //"created_at" = "2014-09-15T13:12:19.644Z" <-- changed to this on server side
    NSDate *date;
    
    dateString = [dateString substringToIndex:19];
    
    // Prase the string to nsdate using the dateFormatter
    date = [self.dateFormatter dateFromString:dateString];
    if (date) return date;
    
    // Failed parsing date. Try again using the fallback dateformatter.
    date = [self.dateFormatterFallback dateFromString:dateString];
    return date;
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









