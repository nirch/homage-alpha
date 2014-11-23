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
