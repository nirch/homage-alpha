//
//  HMDownloadManager.h
//  Homage
//
//  Created by Aviv Wolf on 11/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//
//  For now, the download manager implementation is a very simplistic serialized downloading
//  of story video files.
//
//  1) Will download only on wifi networks.
//  2) Will download story movies and save them to the caches folder.
//  3) Will only download if user didn't turn off stories caches.
//  4) Pause downloads when streaming videos.
//

#import <Foundation/Foundation.h>

@interface HMCacheManager : NSObject

@property (nonatomic, readonly) NSURL *cachePath;
@property (nonatomic, readonly) NSURL *storiesCachePath;


// HMUploadManager is a singleton
+(HMCacheManager *)sharedInstance;

// Just an alias for sharedInstance for shorter writing.
+(HMCacheManager *)sh;


#pragma mark - Caching resources
-(BOOL)isResourceBundledLocallyForURL:(NSString *)url;
-(BOOL)isResourceCachedLocallyForURL:(NSString *)url cachePath:(NSURL *)cachePath;
-(NSURL *)urlForCachedResource:(NSString *)url cachePath:(NSURL *)cachePath;

#pragma mark - download and cache resources
// Check if more resources should be downloaded and cached on the device
// in the background.
-(void)checkIfNeedsToDownloadAndCacheResources;
-(void)pauseDownloads;
-(void)clearStoriesCache;


@end
