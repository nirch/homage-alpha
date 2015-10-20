//
//  HMStoriesViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoriesViewController.h"
#import "HMServer+Stories.h"
#import "HMStoryCell.h"
#import "HMServer+LazyLoading.h"
#import "HMStoryPresenterProtocol.h"
#import "HMNotificationCenter.h"
#import "HMGLog.h"
#import "HMStyle.h"
#import "Mixpanel.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMMainGUIProtocol.h"
#import "HMAppDelegate.h"
#import "HMCacheManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "IASKSettingsReader.h"
#import "HMServer+AppConfig.h"

@interface HMStoriesViewController () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout
>


@property (weak, nonatomic) IBOutlet UIImageView *guiPreloadingImagesView;

// The collection view displaying the list of stories
@property (weak, nonatomic) IBOutlet UICollectionView *storiesCV;

// A label indicating no stories in the list.
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *noStoriesLabel;

// The fetched results controller with the query to the list of stories
// Doesn't implement fetched results controller delegate.
// Just refetches and reloads all data when notification about update is recieved.
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

// A weak reference to the refresh controll (The owner will be it's superview - storiesCV)
@property (weak,nonatomic) UIRefreshControl *refreshControl;

// Text color for this screen
@property (weak, nonatomic) UIColor *textColor;

// TODO: make sure this is a correct implementation.
@property (weak,nonatomic) Story *preRequestedStory;

@end

@implementation HMStoriesViewController

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark lifecycle related
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.refreshControl endRefreshing];
    [self removeObservers];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initObservers];
    [self initContent];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateRenderingBarState];
    self.title = LS(@"NAV_STORIES");
}

-(void)setTitle:(NSString *)title
{
    [super setTitle:title];
    id<HMMainGUIProtocol> vc = (id<HMMainGUIProtocol>)[UIApplication sharedApplication].keyWindow.rootViewController;
    if ([vc respondsToSelector:@selector(updateTitle:)]) {
        [vc updateTitle:title];
    }
}

#pragma mark initializations
-(void)initGUI
{
    // Init pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.storiesCV addSubview:refreshControl];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    //self.refreshControl.tintColor = [HMColor.sh main2];
    CGRect f = [[refreshControl.subviews objectAtIndex:0] frame];
    f.origin.y += 32;
    [[refreshControl.subviews objectAtIndex:0] setFrame:f];
    refreshControl.layer.zPosition = -1;
    
    // Title of this screen.
    self.title = LS(@"STORIES_TAB_HEADLINE_TITLE");
    HMGLogDebug(@"title is: %@" , self.title);
    
    // Other UI initializations
    [self.storiesCV setBackgroundColor: [UIColor clearColor]];
    self.storiesCV.alwaysBounceVertical = YES;
    self.noStoriesLabel.text = LS(@"NO_STORIES");
    [self.noStoriesLabel setHidden:YES];
    
    // ************
    // *  STYLES  *
    // ************
    self.view.backgroundColor = [HMStyle.sh colorNamed:C_COMMON_SCREEN_VC_BG];
    self.textColor = [HMStyle.sh colorNamed:C_STORIES_TEXT];
    self.refreshControl.tintColor = [HMStyle.sh colorNamed:C_ACTIVITY_CONTROL_TINT];
}

-(void)initContent
{
    [self refreshFromLocalStorage];
}


#pragma mark - Observers
-(void)initObservers
{
    
    // Observe application start
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onApplicationStartedNotification:)
                                                       name:HM_NOTIFICATION_APPLICATION_STARTED
                                                     object:nil];
    
    // Observe refetching of stories
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onStoriesRefetched:)
                                                       name:HM_NOTIFICATION_SERVER_STORIES
                                                     object:nil];
    
    // Observe rendering bar
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRenderingBarStateChanged:)
                                                       name:HM_NOTIFICATION_UI_RENDERING_BAR_HIDDEN
                                                     object:nil];

    // Observe rendering bar
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRenderingBarStateChanged:)
                                                       name:HM_NOTIFICATION_UI_RENDERING_BAR_SHOWN
                                                     object:nil];
    
    // Observe settings changes
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onSettingsChanged:)
                                                       name:kIASKAppSettingChanged
                                                     object:nil];
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    //[nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORIES object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_UI_RENDERING_BAR_HIDDEN object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_UI_RENDERING_BAR_SHOWN object:nil];
}


#pragma mark - Observers handlers
-(void)onApplicationStartedNotification:(NSNotification *)notification
{
    
    //
    // Application notifies that local storage is ready and the app can start.
    //
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = YES;
    [self refetchStoriesFromServer];
   
    //
    // Refresh from local storage before updated by server.
    //
    [self refreshFromLocalStorage];
}

-(void)onStoriesRefetched:(NSNotification *)notification
{
    
    //
    // Backend notifies that local storage was updated with stories.
    //
    [self.refreshControl endRefreshing];
    UIApplication* app = [UIApplication sharedApplication];
    app.networkActivityIndicatorVisible = NO;
    [self refreshFromLocalStorage];

    // A simple example:
    // in case you want to update the UI when the notification is reporting that something went wrong (with a request to the server, for example).
    if (notification.isReportingError && HMServer.sh.isReachable ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong :-(\n\nTry to refresh feed in a few moements."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        HMGLogError(@">>> You also get the NSError object:%@", notification.reportedError.localizedDescription);
    }
    
    //
    // Check if needs to download and cache resources
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        [HMCacheManager.sh checkIfNeedsToDownloadAndCacheResources];
    });
    
    // Preload stories thumbs
    [self preloadStoriesThumbs];
}

-(void)preloadStoriesThumbs
{
    for (Story *story in self.fetchedResultsController.fetchedObjects) {
        NSURL *thumbURL =[NSURL URLWithString:story.thumbnailURL];
        [self.guiPreloadingImagesView sd_setImageWithURL:thumbURL placeholderImage:nil
                              options:SDWebImageRetryFailed|SDWebImageContinueInBackground|SDWebImageHighPriority
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                if (error) {
                                    HMGLogDebug(@"Failed preloading image from:%@ %@", imageURL, [error localizedDescription]);
                                } else {
                                    HMGLogDebug(@"Preloaded image from:%@", imageURL);
                                }
                            }];
    }
}


//-(void)onStoryThumbnailLoaded:(NSNotification *)notification
//{
//    
//    NSDictionary *info = notification.userInfo;
//    NSIndexPath *indexPath = info[@"indexPath"];
//    UIImage *image = info[@"image"];
//    
//    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    if (notification.isReportingError || !image) {
//        story.thumbnail = nil;
//    } else {
//        story.thumbnail = image;
//    }
//    
//    // If row not visible, no need to update ui for this image.
//    if (![self.storiesCV.indexPathsForVisibleItems containsObject:indexPath]) return;
//    
//    // Reveal the image animation
//    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV cellForItemAtIndexPath:indexPath];
//    cell.guiThumbImage.alpha = 0;
//    cell.guiThumbImage.image = image ? story.thumbnail : [UIImage imageNamed:@"missingThumbnail"];
//    cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
//    [UIView animateWithDuration:0.7 animations:^{
//        cell.guiThumbImage.alpha = 1;
//        cell.guiThumbImage.transform = CGAffineTransformIdentity;
//    }];
//    
//}

-(void)onPulledToRefetch
{
    
    [[Mixpanel sharedInstance] track:@"UserRefreshStories"];
    [self refetchStoriesFromServer];
    
}

-(void)onRenderingBarStateChanged:(NSNotification *)notification
{
    [self updateRenderingBarState];
}

-(void)onSettingsChanged:(NSNotification *)notification
{
    if (notification.userInfo[@"cacheStoriesVideos"]) {
        BOOL cacheStoriesVideos = [notification.userInfo[@"cacheStoriesVideos"] boolValue];
        if (!cacheStoriesVideos) [HMCacheManager.sh clearVideosCache];
    }
}

#pragma mark - Rendering bar states
-(void)updateRenderingBarState
{
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        if ([app.mainVC isRenderingViewShowing]) {
            UIEdgeInsets c = self.storiesCV.contentInset;
            c.top = [app.mainVC renderingViewHeight];
            self.storiesCV.contentInset = c;
            if (self.storiesCV.contentOffset.y == 0)
                [self.storiesCV scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
        } else {
            UIEdgeInsets c = self.storiesCV.contentInset;
            c.top = 0;
            self.storiesCV.contentInset = c;
        }
    } completion:^(BOOL finished) {
        
    }];
}


#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"story details segue"]) {
        
        //
        // Segue to story details.
        //
        id<HMStoryPresenterProtocol>vc = (id<HMStoryPresenterProtocol>)segue.destinationViewController;
        
        vc.autoStartPlayingStory = YES;
        Story *story;
        
        //user is going to shoot intro movie
        if (self.preRequestedStory) {
            story = self.preRequestedStory;
            vc.story = self.preRequestedStory;
            self.preRequestedStory = nil;
            [[Mixpanel sharedInstance] track:@"SelectedAStory" properties:@{@"storyName" : story.name}];
            //user selected a story from the collection view
        } else {
            NSIndexPath *indexPath = [self.storiesCV indexPathForCell:(HMStoryCell *)sender];
            story = (Story *)[self.fetchedResultsController objectAtIndexPath:indexPath];
            vc.story = story;
            [[Mixpanel sharedInstance] track:@"SelectedAStory" properties:@{@"story" : story.name , @"index" : [NSString stringWithFormat:@"%ld" , (long)indexPath.item]}];
        }
        
        self.title = vc.story.name;
        
    } else {
        HMGLogWarning(@"Segue not implemented:%@",segue.identifier);
    }
}

#pragma mark - Refetching stories
-(void)refetchStoriesFromServer
{
    [HMServer.sh refetchStories];
}


-(void)refreshFromLocalStorage
{
    //
    // Performs a fetch from local storage and reloads data of the collection.
    //
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching stories. %@", error);
        return;
    }
    [self.storiesCV reloadData];
    [self handleNoRemakes];
}

#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
    // If already exists, just return it.
    if (_fetchedResultsController) return _fetchedResultsController;
    
    // Define fetch request.
    // Fetches all stories with isActive=@(YES)
    // Orders them by orderID (ascending order)
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_STORY];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"orderID" ascending:YES]];
    fetchRequest.fetchBatchSize = 20;
    
    // Filtering result
    NSMutableArray *predicates = [NSMutableArray new];

    // Active stories.
    [predicates addObject:[NSPredicate predicateWithFormat:@"isActive=%@", @(YES)]];
    
    // If settings says it should hide premium stories, remove those marked as premium.
    if ([HMServer.sh shouldHidePremiumStories])
        [predicates addObject:[NSPredicate predicateWithFormat:@"isPremium<>%@", @(YES)]];
    
    // Predicates conjunction.
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
}

#pragma mark - UICollectionViewDelegateFlowLayout
-(CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 2.0f;
}

#pragma mark - UICollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    HMGLogDebug(@"number of items in fetchedObjects: %d" , self.fetchedResultsController.fetchedObjects.count);
    return self.fetchedResultsController.fetchedObjects.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Story Cell";
    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1 animations:^{
        cell.alpha = 0.5;
        cell.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            cell.alpha = 1.0;
            cell.transform = CGAffineTransformIdentity;
        }];
    }];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV cellForItemAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"story details segue" sender:cell];
}

#pragma mark - Cells configuration
-(void)configureCell:(HMStoryCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.guiStoryNameLabel.text = story.name;
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.guiThumbImage.alpha = 0;
    
    // Lazy load thumb image.
    NSURL *thumbURL =[NSURL URLWithString:story.thumbnailURL];
    [cell.guiThumbImage sd_setImageWithURL:thumbURL placeholderImage:nil
                                   options:SDWebImageRetryFailed|SDWebImageContinueInBackground|SDWebImageHighPriority
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     
        if (cacheType == SDImageCacheTypeNone) {
            
            // Reveal with animation
            cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
            [UIView animateWithDuration:0.4 animations:^{
                cell.guiThumbImage.alpha = 1;
                cell.guiThumbImage.transform = CGAffineTransformIdentity;
            }];
            
        } else {
            
            // Reveal with no animation.
            cell.guiThumbImage.alpha = 1;
            
        }
    }];

    // Number of remakes
    NSNumber *remakesNum = story.remakesNumber;
    cell.guiNumOfRemakes.text = [NSString stringWithFormat:@"%ld" , (long)remakesNum.integerValue];

    // Premium content.
    if (story.isPremiumAndLocked) {
        cell.guiStoryLockedContainer.hidden = NO;
    } else {
        cell.guiStoryLockedContainer.hidden = YES;
    }
    
    // ************
    // *  STYLES  *
    // ************
    cell.guiStoryNameLabel.textColor = self.textColor;
    cell.guiNumOfRemakes.textColor = self.textColor;
}

#pragma mark - Collection View configuration
-(void)handleNoRemakes
{
    //
    // Show indication in the UI in case no stories available.
    //
    if ([self.storiesCV numberOfItemsInSection:0] == 0) {
        [self.noStoriesLabel setHidden:NO];
    } else {
        [self.noStoriesLabel setHidden:YES];
    }
}

-(void)showStoryDetailedScreenForStory:(NSString *)storyID
{
    self.preRequestedStory = [Story storyWithID:storyID inContext:DB.sh.context];
    if (!self.preRequestedStory.videoURL)
    {
        HMGLogError(@"story %@ video not available" , storyID);
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong. \n\nTry to refresh in a few moments."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
    } else {
        [self performSegueWithIdentifier:@"story details segue" sender:nil];
    }
}

@end
