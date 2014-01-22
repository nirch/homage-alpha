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
                                  if (image) {
                                      HMGLogDebug(@"Lazy loaded image from URL:%@", request.URL);
                                      [moreInfo addEntriesFromDictionary:@{@"image":image}];
                                  } else {
                                      // For some reason success in response, but no image object returned?
                                      NSString *errorDescription = [NSString stringWithFormat:@"Lazy Loading returned nil image from URL:%@", request.URL];
                                      NSError *error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:HMNetworkErrorImageLoadingFailed userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
                                      [moreInfo addEntriesFromDictionary:@{@"error":error}];
                                      HMGLogDebug(errorDescription);
                                  }
                                  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                              }
     
                              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                  //
                                  // Failed loading image from server
                                  //
                                  HMGLogDebug(@"Failed lazy Loading image from URL:%@ %@", request.URL, error.localizedDescription);
                                  [moreInfo addEntriesFromDictionary:@{@"error":error}];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
                              }
     ];
}


@end
