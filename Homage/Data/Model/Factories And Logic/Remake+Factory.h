//
//  Remake+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Remake.h"

#define HM_REMAKE       @"Remake"

@interface Remake (Factory)

///
/**
*  Creates or fetches a remake with given id, related to given story and user.
*
*  @param sID     id of existing/new remake.
*  @param story   a story object the remake is related to.
*  @param user    the user related to the remake.
*  @param context The managed object context.
*
*  @return an existing remake (or a new one, if not found).
*/
+(Remake *)remakeWithID:(NSString *)sID story:(Story *)story user:(User *)user inContext:(NSManagedObjectContext *)context;

///
/**
*  Search for an existing remake by given id.
*
*  @param sID     id of the remake.
*  @param context The managed object context.
*
*  @return Returns existing remake with given id. returns nil if not found.
*/
+(Remake *)findWithID:(NSString *)sID inContext:(NSManagedObjectContext *)context;

@end