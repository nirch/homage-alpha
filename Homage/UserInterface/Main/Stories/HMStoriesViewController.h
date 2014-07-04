//
//  HMStoriesViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "DB.h"

@interface HMStoriesViewController : UIViewController<
    NSFetchedResultsControllerDelegate
>

-(void)showStoryDetailedScreenForStory:(NSString *)storyID;
-(void)refetchStoriesFromServer;

@end
