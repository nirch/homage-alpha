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

[HMServer.sh updateOnSuccessFootageForRemakeID:footage.remake.sID sceneID:footage.sceneID];

*  @endcode
*  @param remakeID The remake id related to this footage.
*  @param sceneID  The scene id number related to this footage.
*/
-(void)updateOnSuccessFootageForRemakeID:(NSString *)remakeID sceneID:(NSNumber *)sceneID takeID:(NSString *)takeID attemptCount:(NSInteger)attemptCount isSelfie:(BOOL)isSelfie;
-(void)updateOnUploadStartFootageForRemakeID:(NSString *)remakeID sceneID:(NSNumber *)sceneID takeID:(NSString *)takeID attemptCount:(NSInteger)attemptCount isSelfie:(BOOL)isSelfie;
@end
