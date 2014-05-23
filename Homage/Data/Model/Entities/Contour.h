//
//  Contour.h
//  Homage
//
//  Created by Yoav Caspin on 5/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Contour : NSManagedObject

@property (nonatomic, retain) NSString * remoteURL;
@property (nonatomic, retain) NSString * localURL;

@end
