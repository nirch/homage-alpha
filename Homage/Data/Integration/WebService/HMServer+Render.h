//
//  HMServer+Render.h
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Render)

///
/**
 *  Tells the server to start rendering a remake.
 *  @code
 
 
 *  @endcode
 *  @param remakeID The remake id for the remake we want to render.
 */
-(void)renderRemakeWithID:(NSString *)remakeID takeIDS:(NSArray *)takeIDS;


@end
