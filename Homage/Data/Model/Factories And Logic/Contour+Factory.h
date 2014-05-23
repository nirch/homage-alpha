//
//  Contour+Factory.h
//  Homage
//
//  Created by Yoav Caspin on 5/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Contour.h"

@interface Contour (Factory)

///
/**
 *  Creates or fetches a contour with given URL
 *  @param remoteURL     remote location of the contour file
 *  @param context The managed object context.
 *
 *  @return an existing contour (or a new one, if not found).
 */
+(Contour *)ContourWitRemoteURL:(NSString *)remoteURL inContext:(NSManagedObjectContext *)context;

+(Contour *)findWithRemoteURL:(NSString *)remoteURL inContext:(NSManagedObjectContext *)context;

@end
