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
    // User info about the request/response
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    // Don't allow repeatedly lazy loading the same image url (when a request to that url is already in progress).
    if ([self.urlsCachedInfo objectForKey:url]) return;
    [self.urlsCachedInfo setObject:@YES forKey:url];
    
    // Build the url request
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    // HTTP request operation with Image response serializer
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    requestOperation.responseSerializer = [AFImageResponseSerializer serializer];
    
    // Success and failure blocks
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //
        // Successful response
        //
        if ([responseObject isKindOfClass:[UIImage class]]) {
            //
            // Successfully loaded image from server.
            //
            UIImage *image = (UIImage *)responseObject;
            HMGLogDebug(@"Lazy loaded image from URL:%@", url);
            [moreInfo addEntriesFromDictionary:@{@"image":image}];
        } else {
            //
            // For some reason success in response, but no image object returned?
            //
            NSString *errorDescription = [NSString stringWithFormat:@"Lazy Loading returned nil image from URL:%@", url];
            NSError *error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:HMNetworkErrorImageLoadingFailed userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
            [moreInfo addEntriesFromDictionary:@{@"error":error}];
            HMGLogDebug(errorDescription);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
        // Reallow requests to this url in the future.
        [self.urlsCachedInfo removeObjectForKey:url];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        //
        // Failed loading image from server
        //
        HMGLogDebug(@"Failed lazy Loading image from URL:%@ %@", url, error.localizedDescription);
        [moreInfo addEntriesFromDictionary:@{@"error":error}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
        
        // Reallow requests to this url in the future.
        [self.urlsCachedInfo removeObjectForKey:url];
    }];
    
    // Start the request
    [requestOperation start];
}





-(void)downloadFileFromURL:(NSString *)url
          notificationName:(NSString *)notificationName
                      info:(NSDictionary *)info
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSMutableDictionary *moreInfo = [info mutableCopy];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error)
        {
            //
            // Failed loading image from server
            //
            HMGLogDebug(@"Failed lazy Loading image from URL:%@ %@", request.URL, error.localizedDescription);
            [moreInfo addEntriesFromDictionary:@{@"error":error}];
            [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
            return;
        }
        
        HMGLogDebug(@"file downloaded to: " , [filePath absoluteString]);
        [moreInfo addEntriesFromDictionary:@{@"local_URL" : [filePath path]}];
        [moreInfo addEntriesFromDictionary:@{@"remote_URL" : url}];
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:moreInfo];
    
    }];
    [downloadTask resume];
}




@end
