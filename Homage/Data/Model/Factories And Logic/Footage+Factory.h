//
//  Footage+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage.h"

#define HM_FOOTAGE      @"Footage"

@interface Footage (Factory)

///
/**
*  Creates a new footage with scene ID
*
*  @param sID     The relates scene ID
*  @param remake  The related remake object.
*  @param context The managed object context.
*
*  @return Returns the newly created footage object.
*/
+(Footage *)newFootageWithSceneID:(NSNumber *)sID remake:(Remake *)remake inContext:(NSManagedObjectContext *)context;


@end
