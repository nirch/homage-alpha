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
*  Given an absolute url, will lazy load an image resource in the background.
*  @code
-(UIImage *)thumbForStory:(Story *)story forIndexPath:(NSIndexPath *)indexPath
{
    if (story.thumbnail) return story.thumbnail;
    [HMServer.sh lazyLoadImageFromURL:story.thumbnailURL
                     placeHolderImage:nil
                     notificationName:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
                                 info:@{@"indexPath":indexPath}
    ];
    return nil;
}
*  @endcode
*  @param url              Absolute url of the image to lazy load.
*  @param placeHolderImage A placeholder image.
*  @param notificationName The name of the notification posted using notification center, on success/failure.
*  @param info             A dictionary of information that will be passed back with the notification.
*   On success - @"image":image will be added to the info dictionary.
*   On failure - @"error":error will be added to the info dictionary.
*/
-(void)lazyLoadImageFromURL:(NSString *)url
           placeHolderImage:(UIImage *)placeHolderImage
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info;



@end
