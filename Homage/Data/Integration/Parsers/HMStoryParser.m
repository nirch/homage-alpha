//
//  HMStoryParser.m
//  Homage
//
//  Created by Yoav Caspin on 7/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryParser.h"

@implementation HMStoryParser

-(void)parse
{
    // The info of a single story.
    NSDictionary *info = self.objectToParse;
    
    //
    // Parse a story.
    //
    NSString *sID = info[@"_id"][@"$oid"];
    
    Story *story = [Story storyWithID:sID inContext:self.ctx];

    NSNumber *isActive = [info boolNumberForKey:@"active"];
    if (![isActive isEqualToNumber:@YES]) {
        // The story is not active in all versions!.
        story.isActive = @NO;
    } else {
        story.isActive = @YES;
//        NSString *firstVersionActive = [info stringForKey:@"active_from"] ? [info stringForKey:@"active_from"] : nil;
//        NSString *lastVersionActive =  [info stringForKey:@"active_until"] ? [info stringForKey:@"active_until"] : nil;
//        NSString *currentVersion = 
//        story.isActive =               [self isActiveStory:story
//                                                forVersion:currentVersion
//                                        firstVersionActive:firstVersionActive
//                                         lastVersionActive:lastVersionActive];
    }

    story.remakesNumber =       [info numberForKey:@"remakes_num"];
    story.orderID =             [info numberForKey:@"order_id"];
    story.name =                [info stringForKey:@"name"];
    story.descriptionText =     [info stringForKey:@"description"];
    story.level =               [info numberForKey:@"level"];
    story.videoURL =            [info stringForKey:@"video"];
    story.thumbnailURL =        [info stringForKey:@"thumbnail"];
    story.shareMessage =        [info stringForKey:@"share_message"] ? [info stringForKey:@"share_message"] : nil;
    story.isPremium =           [info boolNumberForKey:@"is_premium"];
    
    // Parse the scenes of this story.
    BOOL allScenesAreSelfie = YES;
    for (NSDictionary *sceneInfo in info[@"scenes"]) {
        Scene *scene = [self parseSceneWithInfo:sceneInfo forStory:story];
        if (!scene.isSelfie.boolValue) allScenesAreSelfie = NO;
    }
    story.isSelfie = allScenesAreSelfie ? @YES : @NO;
    
    // Parse the texts of this story.
    for (NSDictionary *textInfo in info[@"texts"])
        [self parseTextWithInfo:textInfo forStory:story];
    
    
    HMGLogDebug(@"Parsed story '%@' scenes:%d texts:%d", story.name, story.scenes.count, story.texts.count);

    // Mark for saving.
    [DB.sh save];
}

-(Scene *)parseSceneWithInfo:(NSDictionary *)info forStory:(Story *)story
{
    /**
     {
     context = "Darth Vader Just told you that he is your father";
     contour = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_1_Contour.ctr";
     duration = 8030;
     ebox = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_1_Ebox.ebox";
     id = 1;
     script = "You are in shock!!!";
     selfie = 1;
     silhouette = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/1/Star_Wars_Scene_1_Silhouette.png";
     thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/1/Star_Wars_Scene_1_Thumbnail.jpg";
     video = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/1/Star_Wars_Scene_1_Video.mp4";
     }
     */
    
    NSNumber *sceneID = [info numberForKey:@"id"];
    Scene *scene = [Scene sceneWithID:sceneID story:story inContext:self.ctx];
    scene.context =                 [info stringForKey:@"context"];
    scene.script =                  [info stringForKey:@"script"];
    scene.duration =                [info decimalNumberForKey:@"duration"];
    scene.videoURL =                [info stringForKey:@"video"];
    
    // Audio files (optional)
    scene.sceneAudioURL =           [info stringForKey:@"scene_audio"];
    scene.directionAudioURL =       [info stringForKey:@"direction_audio"];
    scene.postSceneAudio =          [info stringForKey:@"post_scene_audio"];

    // Contours
    if (info[@"contours"])
    {
        //new mongo configueration
        NSDictionary *resolutions = info[@"contours"];
        NSDictionary *resolution = resolutions[@"360"];
        NSString *contourNewRemoteURL = resolution[@"contour_remote"];
        if (![contourNewRemoteURL isEqualToString:scene.contourRemoteURL]) scene.contourLocalURL = nil;
        scene.contourRemoteURL = contourNewRemoteURL;
    } else
    {
        //old mongo configuration
        CLEAR_CACHE_CHECK(scene,contourRemoteURL,contourLocalURL,@"contour_remote"); // clear scene.contourLocalURL if remote url changed
        scene.contourRemoteURL =        [info stringForKey:@"contour_remote"];
    }
    
    scene.thumbnailURL =            [info stringForKey:@"thumbnail"];
    
    if (info[@"silhouettes"])
    {
        //new mongo configuration
        NSDictionary *silhouettes = info[@"silhouettes"];
        NSString *silhouetteNewURL = [silhouettes stringForKey:@"360"];
        scene.silhouetteURL = silhouetteNewURL;
    } else
    {
        //old mongo configuration
        scene.silhouetteURL =           [info stringForKey:@"silhouette"];
    }
    
    //at the moment, all the scenes are selfie enabled
    scene.isSelfie =                @YES;
    //orig: scene.isSelfie =                [info boolNumberForKey:@"selfie"];
    
    scene.focusPointX =             [info numberForKey:@"focus_point_x"];
    scene.focusPointY =             [info numberForKey:@"focus_point_y"];
    
    return scene;
}

-(void)parseTextWithInfo:(NSDictionary *)info forStory:(Story *)story
{
    /**
     {
     "id":1,
     "max_chars":4,
     "name":"Birth Year",
     "description":"Enter the year you were born"
     }*/
    NSNumber *textID = info[@"id"];
    Text *text = [Text textWithID:textID story:story inContext:self.ctx];
    text.maxCharacters =            [info numberForKey:@"max_chars"];
    text.name =                     [info stringForKey:@"name"];
    text.descriptionText =          [info stringForKey:@"description"];
}

-(NSNumber *)isActiveStory:(Story *)story
                forVersion:(NSString *)version
        firstVersionActive:(NSString *)firstVersionActive
         lastVersionActive:(NSString *)lastVersionActive
{
    // TODO: fix this strange logic when possible and be in sync with server side data.
    
    if (firstVersionActive == nil) return @NO;
    
    NSComparisonResult result = [version compare:firstVersionActive options:NSNumericSearch];
    
    if (( result == NSOrderedDescending || result == NSOrderedSame) && lastVersionActive == nil)
    {
        // firstVersionActive <= currentAppVersion and lastVersionActive == nil
        return @YES;
    }
    
    NSComparisonResult lowerBorderResult = [version compare:firstVersionActive options:NSNumericSearch];
    NSComparisonResult upperBorderResult = [lastVersionActive compare:version options:NSNumericSearch];
    
    if ((lowerBorderResult == NSOrderedDescending || lowerBorderResult == NSOrderedSame) && (upperBorderResult == NSOrderedDescending || upperBorderResult == NSOrderedSame)) {
        // firstVersionActive <= currentAppVersion <= lastVersionActive
        return @YES;
    }
    
    if ([firstVersionActive compare:version options:NSNumericSearch] == NSOrderedDescending)
    {
        //currentAppVersion < firstVersionActive
        return @NO;
    }
    
    if ([version compare:lastVersionActive options:NSNumericSearch] == NSOrderedDescending)
    {
        // lastVersionActive < currentAppVersion
        return @NO;
    }
    
    // unknown - (shouldn't happen. This is an error in the logic. debug this).
    HMGLogDebug(@"firstVersionActive: %@ , currentAppVersion: %@ lastVersionActive: %@" , firstVersionActive , version , lastVersionActive);
    return @NO;
    
}



/**
 Example for story info provided by the server.
 
 {
 "_id":{
 "$oid":"52c4341d220b10ce920001a7"
 },
 
 "order_id":1,
 "name":"Birthday",
 "description":"Create a video invitation to your Birthday!",
 "level":2,
 "video":"https://s3.amazonaws.com/homageapp/Stories/Birthday/Birthday_Thumbnail.jpg",
 "thumbnail":"https://s3.amazonaws.com/homageapp/Stories/Birthday/Birthday_Thumbnail.jpg",
 
 "scenes":[
 {
 "id":1,
 "context":"What are you up to today?",
 "script":"Take a funny video of yourself showing your friends what are you up to today",
 "duration":8000,
 "video":"https://s3.amazonaws.com/homageapp/Stories/Birthday/Scenes/1/Birthday_Scene_1_Video.mp4",
 "thumbnail":"https://s3.amazonaws.com/homageapp/Stories/Birthday/Scenes/1/Birthday_Scene_1_Thumbnail.jpg",
 "silhouette":null,
 "selfie":true
 }
 ],
 
 "texts":[
 {
 "id":1,
 "max_chars":4,
 "name":"Birth Year",
 "description":"Enter the year you were born"
 },
 {
 "id":2,
 "max_chars":15,
 "name":"Name",
 "description":"Enter your name"
 },
 {
 "id":3,
 "max_chars":10,
 "name":"Date",
 "description":"Enter the date of the event"
 }
 ]
 },
 */

/**
 
 Another example for a story.
 
 {
 "_id" =     {
 "$oid" = 52cddaf80fad07c3290001aa;
 };
 description = "Play Luke in the famous - I am your father - scene";
 level = 2;
 name = "Star Wars";
 "order_id" = 3;
 scenes =     (
 {
 context = "Darth Vader Just told you that he is your father";
 contour = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_1_Contour.ctr";
 duration = 8030;
 ebox = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_1_Ebox.ebox";
 id = 1;
 script = "You are in shock!!!";
 selfie = 1;
 silhouette = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/1/Star_Wars_Scene_1_Silhouette.png";
 thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/1/Star_Wars_Scene_1_Thumbnail.jpg";
 video = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/1/Star_Wars_Scene_1_Video.mp4";
 },
 {
 context = Noooooooooooooooooooooooooooooooooo;
 contour = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_2_Contour.ctr";
 duration = 8030;
 ebox = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_2_Ebox.ebox";
 id = 2;
 script = Nooooooooooooooooooooooooo;
 selfie = 1;
 silhouette = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/2/Star_Wars_Scene_2_Silhouette.png";
 thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/2/Star_Wars_Scene_2_Thumbnail.jpg";
 video = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/2/Star_Wars_Scene_2_Video.mp4";
 },
 {
 context = "You are loosing your grip";
 contour = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_3_Contour.ctr";
 duration = 3030;
 ebox = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_3_Ebox.ebox";
 id = 3;
 script = "No talking";
 selfie = 1;
 silhouette = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/3/Star_Wars_Scene_3_Silhouette.png";
 thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/3/Star_Wars_Scene_3_Thumbnail.jpg";
 video = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/3/Star_Wars_Scene_3_Video.mp4";
 },
 {
 context = "You are falling down the space ship";
 contour = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_4_Contour.ctr";
 duration = 3880;
 ebox = "C:/Users/Administrator/Documents/Stories/Star Wars/Star_Wars_Scene_4_Ebox.ebox";
 id = 4;
 script = "No talking";
 selfie = 1;
 silhouette = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/4/Star_Wars_Scene_4_Silhouette.png";
 thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/4/Star_Wars_Scene_4_Thumbnail.jpg";
 video = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Scenes/4/Star_Wars_Scene_4_Video.mp4";
 }
 );
 thumbnail = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Star_Wars_Thumbnail.png";
 video = "https://s3.amazonaws.com/homageapp/Stories/StarWars/Star_Wars_Video.mp4";
 }
 */





@end