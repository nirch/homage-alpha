//
//  HMServer+LazyLoading.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMServer+LazyLoading.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@implementation HMServer (LazyLoading)

-(void)lazyLoadImageFromURL:(NSString *)url
           placeHolderImage:(UIImage *)placeHolderImage
           notificationName:(NSString *)notificationName
                       info:(NSDictionary *)info
{
    UIImageView *imageView = [[UIImageView alloc] init];
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]
                     placeholderImage:placeHolderImage

                              success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                  //
                                  // Successfully loaded image
                                  //
                                  [moreInfo addEntriesFromDictionary:@{@"image":image}];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                              }
     
                              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                  //
                                  // Failed loading image from server
                                  //
                                  [moreInfo addEntriesFromDictionary:@{@"error":error}];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                              }
     ];
}


@end
