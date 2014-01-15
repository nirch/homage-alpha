//
//  HMServer+LazyLoading.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (LazyLoading)

-(void)lazyLoadImageFromURL:(NSString *)url
           placeHolderImage:(UIImage *)placeHolderImage
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info;



@end
