//
//  HMCacheManager.h
//  Homage
//
//  Created by Aviv Wolf on 11/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//
//  For now, the download manager implementation is a very simplistic serialized downloading
//  of story video files.
//
//  1) Will download and cache story videos.
//  2) Will download user remakes.
//  3) Will only download if user didn't turn off stories caches.
//

#import <Foundation/Foundation.h>

@class Story;
@class Remake;
@class Footage;

@interface HMCacheManager : NSObject

@property (nonatomic, readonly) NSURL *cachePath;
@property (nonatomic, readonly) NSURL *storiesCachePath;
@property (nonatomic, readonly) NSURL *remakesCachePath;
@property (nonatomic, readonly) NSURL *audioCachePath;


// HMUploadManager is a singleton
+(HMCacheManager *)sharedInstance;

// Just an alias for sharedInstance for shorter writing.
+(HMCacheManager *)sh;

#pragma mark - clearing caches
-(void)clearTempFilesForRemake:(Remake *)remake;
-(void)clearCachedResourcesForRemake:(Remake *)remake;
-(void)clearTempFilesForFootage:(Footage *)footage;

#pragma mark - Caching resources
-(BOOL)isResourceBundledLocallyForURL:(NSString *)url;
-(BOOL)isResourceCachedLocallyForURL:(NSString *)url cachePath:(NSURL *)cachePath;
-(NSURL *)urlForCachedResource:(NSString *)url cachePath:(NSURL *)cachePath;
-(NSURL *)urlForAudioResource:(NSString *)resourceURL;

#pragma mark - download and cache resources
// Check if more resources should be downloaded and cached on the device
// in the background.
-(void)checkIfNeedsToDownloadAndCacheResources;
-(void)pauseDownloads;
-(void)clearVideosCache;
-(void)ensureAudioFilesAvailableForStory:(Story *)story;


@end
