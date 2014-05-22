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

-(void)downloadFileFromURL:(NSString *)url
          notificationName:(NSNotification *)notificationName
                      info:(NSDictionary *)info
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"File downloaded to: %@", filePath);
    }];
    [downloadTask resume];
}




@end
