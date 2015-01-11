//
//  HMServer+LazyLoading.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer.h"

@interface HMServer (LazyLoading)

///
/**
 *  Given an absolute url, will download a file from the server
 *  @param url              Absolute url of the file
 *  @param notificationName The name of the notification posted using notification center, on success/failure.
 *  @param info             A dictionary of information that will be passed back with the notification.
 *   On success - @"file_path": local url string of the file's local path.
 *   On failure - @"error":error will be added to the info dictionary.
 */

-(void)downloadFileFromURL:(NSString *)url
          notificationName:(NSString *)notificationName
                      info:(NSDictionary *)info;

@end
