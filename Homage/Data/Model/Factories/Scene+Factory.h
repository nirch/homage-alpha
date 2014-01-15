//
//  Scene+Factory.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Scene.h"

@interface Scene (Factory)

+(Scene *)sceneWithID:(NSNumber *)sID story:(Story *)story inContext:(NSManagedObjectContext *)context;


@end
