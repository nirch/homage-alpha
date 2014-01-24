//
//  HMServer+Footages.h
//  Homage
//
//  Created by Aviv Wolf on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Footages)

///
/**
*  Updates the server that a footage is ready.
*  @code

[HMServer.sh updateFootageForRemakeID:footage.remake.sID sceneID:footage.sceneID];

*  @endcode
*  @param remakeID The remake id related to this footage.
*  @param sceneID  The scene id number related to this footage.
*/
-(void)updateFootageForRemakeID:(NSString *)remakeID sceneID:(NSNumber *)sceneID;

@end
