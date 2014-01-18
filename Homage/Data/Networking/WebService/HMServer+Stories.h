//
//  HMServer+Stories.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Stories)

///
/**
 *  A GET request to the server requesting info about the available stories.
 *  Notification name when done: HM_NOTIFICATION_SERVER_STORIES.
 *  Parser used: HMStoriesParser.
 *  @code
[HMServer.sh refetchStories];
 *  @endcode
 */
-(void)refetchStories;

@end
