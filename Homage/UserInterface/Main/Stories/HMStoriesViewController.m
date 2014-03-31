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

@interface HMStoriesViewController () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UICollectionView *storiesCV;
@property (weak, nonatomic) IBOutlet HMFontLabel *noStoriesLabel;
@property (weak,nonatomic) UIRefreshControl *refreshControl;
@property (weak,nonatomic) Story *introStory;

@end

@implementation HMStoriesViewController

#define DIVE_SCHOOL "52de83db8bc427751c000305";

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark lifecycle related
-(void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    [self initGUI];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self removeObservers];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self initObservers];
    [self initContent];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark initializations
-(void)initGUI
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    UIRefreshControl *tempRefreshControl = [[UIRefreshControl alloc] init];
    [self.storiesCV addSubview:tempRefreshControl];
    self.refreshControl = tempRefreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    self.title = NSLocalizedString(@"STORIES_TAB_HEADLINE_TITLE", nil);
    HMGLogDebug(@"title is: %@" , self.title);
    
    //self.view.backgroundColor = [UIColor clearColor];
    [self.storiesCV setBackgroundColor: [UIColor clearColor]];
    self.storiesCV.alwaysBounceVertical = YES;
    self.noStoriesLabel.text = NSLocalizedString(@"NO_STORIES", nil);
    [self.noStoriesLabel setHidden:YES];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}

-(void)initContent
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self refreshFromLocalStorage];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark - Observers
-(void)initObservers
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);

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
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_APPLICATION_STARTED object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORIES object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL object:nil];
}


#pragma mark - Observers handlers
-(void)onApplicationStartedNotification:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    //
    // Application notifies that local storage is ready and the app can start.
    //
    [self.refreshControl beginRefreshing];
    [self refetchStoriesFromServer];
   HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
}

-(void)onStoriesRefetched:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    //
    // Backend notifies that local storage was updated with stories.
    //
    [self.refreshControl endRefreshing];
    [self refreshFromLocalStorage];

    // A simple example:
    // in case you want to update the UI when the notification is reporting that something went wrong (with a request to the server, for example).
    if (notification.isReportingError) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong :-(\n\nTry to reload the stories later."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        NSLog(@">>> You also get the NSError object:%@", notification.reportedError.localizedDescription);
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onStoryThumbnailLoaded:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    UIImage *image = info[@"image"];
    
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (notification.isReportingError || !image) {
        story.thumbnail = [UIImage imageNamed:@"missingThumbnail"];
    } else {
        story.thumbnail = image;
    }
    
    // If row not visible, no need to update ui for this image.
    if (![self.storiesCV.indexPathsForVisibleItems containsObject:indexPath]) return;
    
    // Reveal the image animation
    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV cellForItemAtIndexPath:indexPath];
    cell.guiThumbImage.alpha = 0;
    cell.guiThumbImage.image = story.thumbnail;
    cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.7 animations:^{
        cell.guiThumbImage.alpha = 1;
        cell.guiThumbImage.transform = CGAffineTransformIdentity;
    }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onPulledToRefetch
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [[Mixpanel sharedInstance] track:@"UserPulledRefresh"];
    [self refetchStoriesFromServer];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
   HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    if ([segue.identifier isEqualToString:@"story details segue"]) {
        //
        // Segue to story details.
        //
        id<HMStoryPresenterProtocol>vc = (id<HMStoryPresenterProtocol>)segue.destinationViewController;
        
        vc.autoStartPlayingStory = YES;
        
        //user is going to shoot intro movie
        if (self.introStory) {
            vc.story = self.introStory;
            self.introStory = nil;
            [[Mixpanel sharedInstance] track:@"ShootIntroStory"];
        //user selected a story from the collection view
        } else {
            NSIndexPath *indexPath = [self.storiesCV indexPathForCell:(HMStoryCell *)sender];
            Story *story = (Story *)[self.fetchedResultsController objectAtIndexPath:indexPath];
            vc.story = story;
            [[Mixpanel sharedInstance] track:@"SelectedAStory" properties:@{@"storyName" : story.name , @"index" : [NSString stringWithFormat:@"%ld" , (long)indexPath.item]}];
        }        
    } else {
        HMGLogWarning(@"Segue not implemented:%@",segue.identifier);
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark - Refetching stories
-(void)refetchStoriesFromServer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [HMServer.sh refetchStories];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)refreshFromLocalStorage
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching stories. %@", error);
        return;
    }
    [self.storiesCV reloadData];
    [self handleNoRemakes];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}

#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    // If already exists, just return it.
    if (_fetchedResultsController) return _fetchedResultsController;
    
    // Define fetch request.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_STORY];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@", @(YES)];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"orderID" ascending:YES]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return _fetchedResultsController;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
}

#pragma mark - stories collection view 
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    HMGLogDebug(@"%s started and finished" , __PRETTY_FUNCTION__);
    HMGLogDebug(@"number of items in fetchedObjects: %d" , self.fetchedResultsController.fetchedObjects.count);
    return self.fetchedResultsController.fetchedObjects.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    static NSString *cellIdentifier = @"Story Cell";
    HMStoryCell *cell = (HMStoryCell *)[self.storiesCV dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)configureCell:(HMStoryCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    //cell border design
    /*[cell.layer setBorderColor:[HMColor.sh main2].CGColor];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setCornerRadius:7.5f];
    [cell.layer setShadowOffset:CGSizeMake(0, 1)];
    [cell.layer setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [cell.layer setShadowRadius:8.0];
    [cell.layer setShadowOpacity:0.8];
    //*/
    
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.guiStoryNameLabel.text = story.name;
    HMGLogDebug(@"story name: %@" , story.name);
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.guiThumbImage.alpha = story.thumbnail ? 1:0;
    cell.guiThumbImage.image = [self thumbForStory:story forIndexPath:indexPath];
    
    cell.guiLevelOfDifficulty.image = [self getDifficultyLevelThumbForStory:story];
    
    if (story.isASelfie) {
        cell.guiShotMode.image = [UIImage imageNamed:@"selfie"];
    } else {
        cell.guiShotMode.image = [UIImage imageNamed:@"director"];
    }
    
    NSUInteger remakesNum = [story.remakes count];
    cell.guiNumOfRemakes.text = [NSString stringWithFormat:@"#%lu" , (unsigned long)remakesNum];
    
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(UIImage *)getDifficultyLevelThumbForStory:(Story *)story
{
    UIImage *image;
    switch (story.level.integerValue)
    {
        case HMStoryLevelEasy:
            image = [UIImage imageNamed:@"easy"];
            break;
        case HMStoryLevelMedium:
            image = [UIImage imageNamed:@"medium"];
            break;
        case HMStoryLevelHard:
            image = [UIImage imageNamed:@"hard"];
            break;
    }
    return image;
}

-(void)handleNoRemakes
{
    if ([self.storiesCV numberOfItemsInSection:0] == 0) {
        [self.noStoriesLabel setHidden:NO];
    } else {
        [self.noStoriesLabel setHidden:YES];
    }
}

#pragma mark - Lazy loading
-(UIImage *)thumbForStory:(Story *)story forIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (story.thumbnail) return story.thumbnail;
    [HMServer.sh lazyLoadImageFromURL:story.thumbnailURL
                     placeHolderImage:nil
                     notificationName:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
                                 info:@{@"indexPath":indexPath, @"storyID":story.sID}
    ];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return nil;
}

-(void)prepareToShootIntroStory
{
    NSString *storyID = @DIVE_SCHOOL;
    self.introStory = [Story storyWithID:storyID inContext:DB.sh.context];
    [self performSegueWithIdentifier:@"story details segue" sender:nil];
}

@end
