//
//  HMStoriesParser.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoriesParser.h"

@implementation HMStoriesParser

// Parse an array of stories.
// Each story is a dictionary.
-(void)parse
{
    // Iterate all stories info
    NSArray *stories = self.objectToParse;
    for (NSDictionary *storyInfo in stories) {
        [self parseStoryWithInfo:storyInfo];
    }
    
    // Mark for saving.
    [DB.sh save];
}

-(void)parseStoryWithInfo:(NSDictionary *)info
{
    /**
    {
        "_id":{"$oid":"52c4341d220b10ce920001a7"},
        "order_id":1,
        "name":"Birthday",
        "description":"Create a video invitation to your Birthday!",
        "level":2,
        "video":"https://s3.amazonaws.com/homageapp/Stories/Birthday/Birthday_Thumbnail.jpg",
        "thumbnail":"https://s3.amazonaws.com/homageapp/Stories/Birthday/Birthday_Thumbnail.jpg",
        "scenes":[...],
        "texts":[...]
    }
     */
    
    //
    // Parse a story.
    //
    NSString *sID = info[@"_id"][@"$oid"];
    
    Story *story = [Story storyWithID:sID inContext:self.ctx];
    story.isActive =            @YES; // TODO: Support this when server supports it.
    story.orderID =             [info numberForKey:@"order_id"];
    story.name =                [info stringForKey:@"name"];
    story.descriptionText =     [info stringForKey:@"description"];
    story.level =               [info numberForKey:@"level"];
    story.videoURL =            [info stringForKey:@"video"];
    story.thumbnailURL =        [info stringForKey:@"thumbnail"];
    
    
    // Parse the scenes of this story.
    BOOL allScenesAreSelfie = YES;
    for (NSDictionary *sceneInfo in info[@"scenes"]) {
        Scene *scene = [self parseSceneWithInfo:sceneInfo forStory:story];
        if (scene.isSelfie.boolValue) allScenesAreSelfie = NO;
    }
    story.isSelfie = allScenesAreSelfie ? @YES : @NO;
    
    // Parse the texts of this story.
    for (NSDictionary *textInfo in info[@"texts"])
        [self parseTextWithInfo:textInfo forStory:story];


    HMGLogDebug(@"Parsed story '%@' scenes:%d texts:%d", story.name, story.scenes.count, story.texts.count);
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
    
    CLEAR_CACHE_CHECK(scene,thumbnailURL,thumbnail,@"thumbnail"); // clear scene.thumbnail if url changed
    scene.thumbnailURL =            [info stringForKey:@"thumbnail"];
    
    CLEAR_CACHE_CHECK(scene,silhouetteURL,silhouette,@"silhouette"); // clear scene.thumbnail if url changed
    scene.silhouetteURL =           [info stringForKey:@"silhouette"];
    
    scene.isSelfie =                [info boolNumberForKey:@"selfie"];
    
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
