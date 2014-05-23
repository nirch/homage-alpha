//
//  Contour+Factory.m
//  Homage
//
//  Created by Yoav Caspin on 5/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "Contour+Factory.h"
#import "DB.h"

#define HM_CONTOUR @"Contour"

@implementation Contour (Factory)

+(Contour *)ContourWitRemoteURL:(NSString *)remoteURL inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteURL=%@", remoteURL];
    
    Contour *contour = [DB.sh fetchOrCreateEntityNamed:HM_CONTOUR withPredicate:predicate inContext:context];
    contour.remoteURL = remoteURL;
    return contour;
}

+(Contour *)findWithRemoteURL:(NSString *)remoteURL inContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteURL=%@",remoteURL];
    return (Contour *)[DB.sh fetchSingleEntityNamed:HM_CONTOUR withPredicate:predicate inContext:context];    
}
@end
