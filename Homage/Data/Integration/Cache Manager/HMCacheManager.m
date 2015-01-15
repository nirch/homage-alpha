//
//  HMDownloadManager.m
//  Homage
//
//  Created by Aviv Wolf on 11/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMCacheManager.h"
#import "DB.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import "HMNotificationCenter.h"
#import "HMServer+AppConfig.h"

@interface HMCacheManager()

@property (nonatomic) BOOL cfgShouldCacheStoriesVideos;
@property (nonatomic) BOOL cfgShouldCacheUserRemakesVideos;
@property (nonatomic) BOOL cfgShouldCacheAudio;
@property (nonatomic) NSInteger cfgCacheStoriesVideosMaxCount;

@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) BOOL shouldPauseDownloads;
@property (nonatomic) NSMutableDictionary *latestDownloadAttemptTimeForURL;

@property (strong, nonatomic) NSMutableDictionary *bundledResourcesURLS;
@property (strong, nonatomic) NSMutableDictionary *cachedResourcesURLS;
@property (strong, nonatomic) NSURL *cachePath;


@end

@implementation HMCacheManager

// HMUploadManager is a singleton
+(HMCacheManager *)sharedInstance
{
    static HMCacheManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMCacheManager alloc] init];
    });
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMCacheManager *)sh
{
    return [HMCacheManager sharedInstance];
}

#pragma mark - Initializations
-(id)init
{
    self = [super init];
    if (self) {
        HMGLogDebug(@"Starting download manager.");
        [self loadCFG];
        [self initPaths];
        [self initObservers];
    }
    return self;
}

-(void)loadCFG
{
    self.cfgShouldCacheStoriesVideos = [HMServer.sh.configurationInfo[@"cache_stories_videos"] boolValue];
    self.cfgShouldCacheUserRemakesVideos = [HMServer.sh.configurationInfo[@"cache_user_remakes_videos"] boolValue];
    self.cfgShouldCacheAudio = [HMServer.sh.configurationInfo[@"cache_audio"] boolValue];
    self.cfgCacheStoriesVideosMaxCount = [HMServer.sh.configurationInfo[@"cache_stories_videos_max_count"] integerValue];
}

-(void)initPaths
{
    self.latestDownloadAttemptTimeForURL = [NSMutableDictionary new];

    // The caches path Library/caches
    _cachePath = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];

    // Cache folder for stories videos
    _storiesCachePath = [_cachePath URLByAppendingPathComponent:@"stories"];
    _remakesCachePath = [_cachePath URLByAppendingPathComponent:@"remakes"];
    _audioCachePath = [_cachePath URLByAppendingPathComponent:@"audio"];
    
    // Ensure stories cache folder exists (create it if it doesn't)
    [self createFolderIfMissingAtURL:_storiesCachePath];

    // Ensure remakes cache folder exists (create it if it doesn't)
    [self createFolderIfMissingAtURL:_remakesCachePath];
    
    // Ensure audio cache folder exists (create it if it doesn't)
    [self createFolderIfMissingAtURL:_audioCachePath];
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // Observe closing animation
    [nc addUniqueObserver:self
                 selector:@selector(onVideoResourceDownloadFinished:)
                     name:HM_NOTIFICATION_DOWNLOAD_VIDEO_RESOURCE_FINISHED
                   object:nil];
}

-(void)onVideoResourceDownloadFinished:(NSNotification *)notification
{
    self.downloadTask = nil;
    if (self.shouldPauseDownloads) return;
    
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf _checkIfNeedsToDownloadAndCacheVideos];
    });
}

#pragma mark - Downloads Logic
-(void)checkIfNeedsToDownloadAndCacheResources
{
    HMGLogDebug(@"Checking if needs to download resources.");
    __weak id weakSelf = self;
    
    // Downloading and caching videos for stories and remakes.
    dispatch_async(dispatch_get_main_queue(), ^() {
        [weakSelf _checkIfNeedsToDownloadAndCacheVideos];
    });
    
    // Downloading and caching audio files for scenes of stories (that use them)
    dispatch_async(dispatch_get_main_queue(), ^() {
        [weakSelf _checkIfNeedsToDownloadAudioForStories];
    });
}

-(void)pauseDownloads
{
    if (!self.downloadTask) return;
    self.shouldPauseDownloads = YES;
    HMGLogDebug(@"Cancelling/pausing current downloads");
    [self.downloadTask cancel];
}

-(void)_checkIfNeedsToDownloadAndCacheVideos
{
    if (!self.cfgShouldCacheStoriesVideos && !self.cfgShouldCacheUserRemakesVideos)
        return;

    // Because of historical reasons, the user setting is store in user defaults as "cacheStoriesVideos"
    // but currently it also effects the downloading and caching of user's remakes videos.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *cacheVideosUserSetting = [defaults objectForKey:@"cacheStoriesVideos"];
    if (cacheVideosUserSetting && ![cacheVideosUserSetting boolValue]) {
        // User doesn't want to download and cache videos on the device.
        return;
    }
    
    // Serial downloads in this simple implementation.
    // Videos are downloaded one at a time.
    if (self.downloadTask) {
        HMGLogDebug(@"Currently downloading. Will not download any more videos now.");
        return;
    }
    
    HMGLogDebug(@"Checking if needs to download and cache videos.");
    self.shouldPauseDownloads = NO;
    NSDate *now = [NSDate date];
    
    //
    // Gather the resource objects.
    //
    
    // Resource objects list.
    NSMutableArray *resourcesObjects = [NSMutableArray new];
    
    // Add all active stories to the list (if setting is to cache stories)
    NSArray *stories;
    if (self.cfgShouldCacheStoriesVideos) {
        stories = [Story allActiveStoriesInContext:DB.sh.context];
        if (stories && stories.count > 0)
            [resourcesObjects addObjectsFromArray:stories];
    }
    
    // Add all user's "Done" remakes to the list (if setting is to cache remakes)
    User *currentUser = [User current];
    NSArray *remakes;
    if (currentUser) {
        remakes = [Remake allRemakesForUser:currentUser
                                 withStatus:HMGRemakeStatusDone
                                  inContext:DB.sh.context];
        if (remakes && remakes.count > 0)
            [resourcesObjects addObjectsFromArray:remakes];
    }

    //
    //  Iterate the resource objects.
    //
    
    for (id resourceObject in resourcesObjects) {
        // Skip if already available locally.
        if ([resourceObject isVideoAvailableLocally]) continue;
        
        // Get the url string of the resource.
        NSString *url = [[resourceObject videoURL] stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
        
        // Just a hack. Skip this long video (hard coded in test env).
        if ([[resourceObject videoURL] rangeOfString:@"Messi+Vs+Tomer"].location != NSNotFound) {
            continue;
        }
        
        // Ignore videos already tried to download lately
        NSDate *latestAttempt = self.latestDownloadAttemptTimeForURL[url];
        if (latestAttempt) {
            NSTimeInterval timePassed = [now timeIntervalSinceDate:latestAttempt];
            if (timePassed < 10000) continue;
        }

        //
        // Handling remakes videos.
        //
        
        // No limit to the number of user remakes videos to download.
        if ([resourceObject isKindOfClass:[Remake class]]) {
            [self downloadAndCacheVideoResourceFromURL:url
                                             cachePath:self.remakesCachePath];
            break;
        }
        
        //
        // Handling stories videos.
        //
        
        // If not over the limit, will just download the video.
        if (![self storiesCacheCountReachedLimit]) {
            [self downloadAndCacheVideoResourceFromURL:url
                                             cachePath:self.storiesCachePath];
            break;
        }
        
        // If over the limit size, will delete oldest video first and only than download the new one.
        // (The deleted video should be lower in the list than the one we want to cache - otherwise do nothing)
        NSInteger count = [self folderFilesCount:self.storiesCachePath.path];
        NSInteger filesToDeleteCount = count - self.cfgCacheStoriesVideosMaxCount + 1;
        
        if ([self couldRemoveCachedStories:stories
                               beforeStory:resourceObject
                                     count:filesToDeleteCount]) {

            
            // Could delete some videos. Download the newer one and cache it.
            [self downloadAndCacheVideoResourceFromURL:url
                                             cachePath:self.storiesCachePath];
            break;
        } else {

            // Cache over the limit and no older stories. Abort.
            HMGLogDebug(@"Over the limit and can't make enough room. Abort download.");
            return;
            
        }
    }
}

-(void)_checkIfNeedsToDownloadAudioForStories
{
    NSArray *stories = [Story allActiveStoriesInContext:DB.sh.context];
    for (Story *story in stories) {
        if (!story.usesAudioFilesInRecorder) continue;
        [self ensureAudioFilesAvailableForStory:story];
    }
}

-(BOOL)storiesCacheCountReachedLimit
{
    NSInteger count = [self folderFilesCount:self.storiesCachePath.path];
    if (count >= self.cfgCacheStoriesVideosMaxCount) return YES;
    return NO;
}

#pragma mark - Audio files
-(void)ensureAudioFilesAvailableForStory:(Story *)story
{
    // Ignore stories that don't use audio files.
    if (!story.usesAudioFilesInRecorder) return;
    
    // Iterate scenes and download missing audio files.
    for (Scene *scene in story.scenes) {
        if (![self isAudioResourceAvailableLocally:scene.sceneAudioURL]) {
            HMGLogDebug(@"Missing scene audio file: %@", scene.sceneAudioURL);
            [self downloadAndCacheAudioFile:scene.sceneAudioURL];
        }
        if (![self isAudioResourceAvailableLocally:scene.directionAudioURL]) {
            HMGLogDebug(@"Missing direction audio file: %@", scene.directionAudioURL);
            [self downloadAndCacheAudioFile:scene.directionAudioURL];
        }
        if (![self isAudioResourceAvailableLocally:scene.postSceneAudio]) {
            HMGLogDebug(@"Missing post scene audio file: %@", scene.postSceneAudio);
            [self downloadAndCacheAudioFile:scene.postSceneAudio];
        }
    }
}

-(BOOL)isAudioResourceAvailableLocally:(NSString *)url
{
    // Check if video is bundled locally.
    if ([self isResourceBundledLocallyForURL:url])
        return YES;
    
    // Check if video downloaded and cached locally.
    if ([self isResourceCachedLocallyForURL:url cachePath:self.audioCachePath])
        return YES;
    
    // Not bundled and not cached.
    return NO;
}

-(void)downloadAndCacheAudioFile:(NSString *)url
{
    // The request
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    // The download task
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {

        // The local url to download to.
        NSURL *path = [self.audioCachePath URLByAppendingPathComponent:[response suggestedFilename]];
        return path;
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        // When finished.
        if (error) {
            HMGLogError(@"Error while downloading audio resource. %@", [error localizedDescription]);
        }
        
        // Notify about finished upload.
        dispatch_async(dispatch_get_main_queue(), ^{
            HMGLogDebug(@"File downloaded and cached: %@", filePath);
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_DOWNLOAD_AUDIO_RESOURCE_FINISHED object:nil];
        });
        
    }];
    [downloadTask resume];
}

#pragma mark - Download videos
-(void)downloadAndCacheVideoResourceFromURL:(NSString *)url cachePath:(NSURL *)cachePath
{
    HMGLogDebug(@"DL & cache video:%@", url);

    self.latestDownloadAttemptTimeForURL[url] = [NSDate date];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    // Download the file
    self.downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {

        // The local url to download to.
        NSURL *path = [cachePath URLByAppendingPathComponent:[response suggestedFilename]];
        return path;

    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {

        // When finished.
        if (error) {
            HMGLogError(@"Error while downloading video. %@", [error localizedDescription]);
        }
        
        // Notify about finished download.
        dispatch_async(dispatch_get_main_queue(), ^{
            HMGLogDebug(@"File downloaded and saved to cache: %@", filePath);
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_DOWNLOAD_VIDEO_RESOURCE_FINISHED object:nil];
        });
        
    }];
    [self.downloadTask resume];
}

#pragma mark - Caching resources
-(BOOL)isResourceBundledLocallyForURL:(NSString *)url
{
    NSURL *bundledResourceURL = [self urlForBundledResource:url];
    if (bundledResourceURL) return YES;
    return NO;
}

-(NSURL *)urlForBundledResource:(NSString *)url
{
    NSURL *bundledURL = self.bundledResourcesURLS[url];
    if (bundledURL) return bundledURL;
    
    // Check if bundled resource exists.
    NSString *file = [url lastPathComponent];
    NSArray *comp = [file componentsSeparatedByString:@"."];
    if (comp.count == 2) {
        NSString *fileName = comp[0];
        NSString *extension = comp[1];
        bundledURL = [[NSBundle mainBundle] URLForResource:fileName withExtension:extension];
        if (bundledURL) {
            self.bundledResourcesURLS[url] = bundledURL;
            return bundledURL;
        }
    }
    return nil;
}

-(NSURL *)cachedResourceURLForURL:(NSString *)url cachePath:(NSURL *)cachePath
{
    if (url == nil) return nil;
    url = [url stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
    NSURL *cachedResourceURL = [self urlForCachedResource:url cachePath:cachePath];
    return cachedResourceURL;
}

-(BOOL)isResourceCachedLocallyForURL:(NSString *)url cachePath:(NSURL *)cachePath
{
    if (url == nil) return NO;
    NSURL *cachedResourceURL = [self cachedResourceURLForURL:url cachePath:cachePath];
    if (cachedResourceURL) return YES;
    return NO;
}

-(NSURL *)urlForCachedResource:(NSString *)url cachePath:(NSURL *)cachePath
{
    url = [url stringByReplacingOccurrencesOfString:@"%20" withString:@"+"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *cachedURL = self.cachedResourcesURLS[url];
    if (cachedURL) {
        if (![fileManager fileExistsAtPath:cachedURL.path]) return nil;
        return cachedURL;
    }
    
    // Use root caches path by default.
    if (cachePath == nil) cachePath = self.cachePath;
    
    // Check if cached resource exists.
    NSString *file = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@"%26" withString:@"_"];
    cachedURL = [cachePath URLByAppendingPathComponent:file];
    if (cachedURL) {
        if (![fileManager fileExistsAtPath:cachedURL.path]) return nil;
        self.cachedResourcesURLS[url] = cachedURL;
        return cachedURL;
    }
    
    return nil;
}

-(NSURL *)urlForAudioResource:(NSString *)resourceURL
{
    // If budled, return url pointing to resource in the bundle
    NSURL *url = [self urlForBundledResource:resourceURL];
    if (url) return url;
    
    // If cached, return url of the locally cached resource
    url = [self urlForCachedResource:resourceURL cachePath:self.audioCachePath];
    if (url) return url;
    
    // Not cached, return remote resource url
    url = [NSURL URLWithString:resourceURL];
    return url;
}

#pragma mark - folders
-(NSInteger)folderFilesCount:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    HMGLogDebug(@"files count:%@", @(filesArray.count));
    return filesArray.count;
}

- (unsigned long long int)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long int folderSize = 0;
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        folderSize += [fileDictionary fileSize];
    }
    return folderSize;
}

-(void)createFolderIfMissingAtURL:(NSURL *)url
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:url.path]) {
        NSError *error;
        [fm createDirectoryAtPath:url.path withIntermediateDirectories:NO
                       attributes:nil error:&error];
        if (error) {
            HMGLogError(@"Failed creating folder at:%@", url.path);
        }
    }
}

#pragma mark - Cleaning up
-(void)clearStoriesCache
{
    NSError *error;
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:self.storiesCachePath.path error:&error];
    if (error) {
        HMGLogError(@"clear cache error %@", [error localizedDescription]);
        return;
    }
    
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    while (fileName = [filesEnumerator nextObject]) {
        NSError *error = nil;
        NSString *path = [self.storiesCachePath.path stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error) {
            HMGLogError(@"Failed removing %@", path);
        } else {
            HMGLogDebug(@"Removed %@", path);
        }
    }
}

-(BOOL)couldRemoveCachedStories:stories beforeStory:(Story *)story count:(NSInteger)count
{
    NSInteger deletedStories = 0;
    for (Story *storyToDelete in [stories reverseObjectEnumerator]) {
        // Only stories lower on the list allowed to be deleted.
        if ([storyToDelete.sID isEqualToString:story.sID]) break;
        
        // Try to delete the story.
        NSURL *urlToDelete = [self urlForCachedResource:storyToDelete.videoURL cachePath:self.storiesCachePath];
        if (!urlToDelete) continue;
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:urlToDelete error:&error];
        if (error) {
            HMGLogError(@"Failed to remove story video:%@ %@", urlToDelete.path, [error localizedDescription]);
            continue;
        }
        HMGLogDebug(@"Removed story video: %@", urlToDelete.path);
        deletedStories++;
        
        if (deletedStories == count) return YES;
    }
    
    return NO;
}

-(void)clearTempFilesForFootage:(Footage *)footage
{
    NSFileManager *fm = [NSFileManager defaultManager];
    if (footage.rawLocalFile == nil) return;
    HMGLogDebug(@"Check if temp file exists @ %@", footage.rawLocalFile);
    if ([fm fileExistsAtPath:footage.rawLocalFile]) {
        HMGLogDebug(@"temp file exists @ %@", footage.rawLocalFile);
        [fm removeItemAtPath:footage.rawLocalFile error:nil];
        if (![fm fileExistsAtPath:footage.rawLocalFile]) {
            HMGLogDebug(@"temp file removed from %@", footage.rawLocalFile);
        }
    } else {
        HMGLogDebug(@"Not found :-(");
    }
}

-(void)clearTempFilesForRemake:(Remake *)remake
{
    NSArray *footages = [remake footagesOrdered];
    for (Footage *footage in footages) {
        [self clearTempFilesForFootage:footage];
    }
}

-(void)clearCachedResourcesForRemake:(Remake *)remake
{
    if ([remake isVideoAvailableLocally]) {
        HMGLogDebug(@"Cached video for remake should be removed @ %@", remake.videoURL);
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *resourceURL = [self cachedResourceURLForURL:remake.videoURL
                                                 cachePath:self.remakesCachePath];
        [fm removeItemAtURL:resourceURL error:nil];
        if (![remake isVideoAvailableLocally]) {
            HMGLogDebug(@"Removed cached video for remake from %@", remake.videoURL);            
        }
    }
}

@end
