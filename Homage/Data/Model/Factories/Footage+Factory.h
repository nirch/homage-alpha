//
//  Footage+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Footage.h"

@interface Footage (Factory)

+(Footage *)newFootageWithSceneID:(NSNumber *)sID remake:(Remake *)remake inContext:(NSManagedObjectContext *)context;

@end
