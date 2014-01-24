//
//  HMServer+Texts.h
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (Texts)

///
/**
 *  Updates the server that a text of a remake was changed.
 *  @code
 
 
 *  @endcode
 *  @param text The new value of the text.
 *  @param remakeID The remake id related to this text.
 *  @param sceneID  The text id number related to this text.
 */
-(void)updateText:(NSString *)text forRemakeID:(NSString *)remakeID textID:(NSNumber *)textID;

@end
