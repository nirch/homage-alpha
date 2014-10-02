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
#import "HMColor.h"
#import "Mixpanel.h"
#import "HMServer+ReachabilityMonitor.h"

@interface HMStoriesViewController () <UICollectionViewDataSource,UICollectionViewDelegate>

// The collection view displaying the list of stories
@property (weak, nonatomic) IBOutlet UICollectionView *storiesCV;

// A label indicating no stories in the list.
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *noStoriesLabel;

// The fetched results controller with the query to the list of stories
// Doesn't implement fetched results controller delegate.
// Just refetches and reloads all data when notification about update is recieved.
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

// A weak reference to the refresh controll (The owner will be it's superview - storiesCV)
@property (weak,nonatomic) UIRefreshControl *refreshControl;

// TODO: make sure this is a correct implementation.
@property (weak,nonatomic) Story *preRequestedStory;

@end

@implementation HMStoriesViewController

#define DIVE_SCHOOL "52de83db8bc427751c000305";

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

#pragma mark initializations
-(void)initGUI
{
    // Init pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.storiesCV addSubview:refreshControl];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    self.refreshControl.tintColor = [HMColor.sh main2];
    CGRect f = [[refreshControl.subviews objectAtIndex:0] frame];
    f.origin.y += 32;
    [[refreshControl.subviews objectAtIndex:0] setFrame:f];
    
    // Title of this screen.
    self.title = LS(@"STORIES_TAB_HEADLINE_TITLE");
    HMGLogDebug(@"title is: %@" , self.title);
    
    // Other UI initializations
    [self.storiesCV setBackgroundColor: [UIColor clearColor]];
    self.storiesCV.alwaysBounceVertical = YES;
    self.noStoriesLabel.text = LS(@"NO_STORIES");
    [self.noStoriesLabel setHidden:YES];
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

    // Observe lazy loading thumbnails
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onStoryThumbnailLoaded:)
                                                       name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:nil];

}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    //[nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORIES object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:nil];
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
    
}

-(void)onStoryThumbnailLoaded:(NSNotification *)notification
{
    
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    UIImage *image = info[@"image"];
    
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (notification.isReportingError || !image) {
        story.thumbnail = nil;
    } else {
        story.thumbnail = image;
    }
    
    // If row not visible, no need to update ui for this image.
    if (![self.storiesCV.indexPathsForVisibleItems containsObject:indexPath]) return;
    
    // Reveal the image animation
    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV cellForItemAtIndexPath:indexPath];
    cell.guiThumbImage.alpha = 0;
    cell.guiThumbImage.image = image ? story.thumbnail : [UIImage imageNamed:@"missingThumbnail"];
    cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.7 animations:^{
        cell.guiThumbImage.alpha = 1;
        cell.guiThumbImage.transform = CGAffineTransformIdentity;
    }];
    
}

-(void)onPulledToRefetch
{
    
    [[Mixpanel sharedInstance] track:@"UserRefreshStories"];
    [self refetchStoriesFromServer];
    
}

-(void)onReachabilityStatusChange:(NSNotification *)notification
{
    [self setActionsEnabled:HMServer.sh.isReachable];
}

-(void)setActionsEnabled:(BOOL)enabled
{
    for (UICollectionViewCell *cell in [self.storiesCV visibleCells])
    {
        [cell setUserInteractionEnabled:enabled];
    }
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
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@", @(YES)];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"orderID" ascending:YES]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
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
    //HMGLogDebug(@"story name: %@" , story.name);
    
    cell.guiStoryNameLabel.text = story.name;
    cell.guiLevelOfDifficulty.image = [self getDifficultyLevelThumbForStory:story];
    
    // Get thumb image from local storage or lazy load it from server.
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.guiThumbImage.alpha = story.thumbnail ? 1:0;
    cell.guiThumbImage.image = [self thumbForStory:story forIndexPath:indexPath];
    
    // Is a selfie icon
    NSString *shotModeImageName = story.isASelfie ? @"selfie1" : @"director1";
    cell.guiShotMode.image = [UIImage imageNamed:shotModeImageName];
    
    // Number of remakes
    NSNumber *remakesNum = story.remakesNumber;
    cell.guiNumOfRemakes.text = [NSString stringWithFormat:@"%ld" , (long)remakesNum.integerValue];
}

#pragma mark - Collection View configuration
-(UIImage *)getDifficultyLevelThumbForStory:(Story *)story
{
    UIImage *image;
    switch (story.level.integerValue)
    {
        case HMStoryLevelEasy:
            image = [UIImage imageNamed:@"level1"];
            break;
        case HMStoryLevelMedium:
            image = [UIImage imageNamed:@"level2"];
            break;
        case HMStoryLevelHard:
            image = [UIImage imageNamed:@"level3"];
            break;
    }
    return image;
}

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

#pragma mark - Lazy loading
-(UIImage *)thumbForStory:(Story *)story forIndexPath:(NSIndexPath *)indexPath
{
    if (story.thumbnail) return story.thumbnail;
    [HMServer.sh lazyLoadImageFromURL:story.thumbnailURL
                     placeHolderImage:nil
                     notificationName:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
                                 info:@{@"indexPath":indexPath, @"storyID":story.sID}
     ];
    return nil;
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
