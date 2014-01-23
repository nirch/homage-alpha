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

@interface HMStoriesViewController () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) IBOutlet UICollectionView *storiesCV;
@property (weak, nonatomic) IBOutlet HMFontLabel *noStoriesLabel;
@property (weak, nonatomic) IBOutlet HMFontLabel *headLine;

@property (weak,nonatomic) UIRefreshControl *refreshControl;

@end

@implementation HMStoriesViewController

@synthesize fetchedResultsController = _fetchedResultsController;

-(void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    
    [self initGUI];
    [self initObservers];
    [self initContent];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)initGUI
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    UIRefreshControl *tempRefreshControl = [[UIRefreshControl alloc] init];
    [self.storiesCV addSubview:tempRefreshControl];
    self.refreshControl = tempRefreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    
    //self.view.backgroundColor = [UIColor clearColor];
    [self.storiesCV setBackgroundColor: [UIColor clearColor]];
    self.storiesCV.alwaysBounceVertical = YES;
    
    self.noStoriesLabel.text = NSLocalizedString(@"NO_STORIES", nil);
    [self.noStoriesLabel setHidden:YES];
    
    UIColor *homageColor = [UIColor colorWithRed:255 green:125 blue:95 alpha:1];
    self.headLine.text = NSLocalizedString(@"STORIES_TAB_HEADLINE_TITLE", nil);
    [self.headLine setTextColor:homageColor];
    
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
        [alert show];
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
        story.thumbnail = nil;
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
        NSIndexPath *indexPath = [self.storiesCV indexPathForCell:(HMStoryCell *)sender];
        Story *story = (Story *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        id<HMStoryPresenterProtocol>vc = (id<HMStoryPresenterProtocol>)segue.destinationViewController;
        vc.story = story;
        
    } else {
        HMGLogWarning(@"Segue not implemented:%@",segue.identifier);
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark - Refresh stories
-(void)refetchStoriesFromServer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    // Refetch stories from the server
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

#pragma mark - Table data source
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
    [cell.layer setBorderColor:[UIColor colorWithRed:213.0/255.0f green:210.0/255.0f blue:199.0/255.0f alpha:1.0f].CGColor];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setCornerRadius:7.5f];
    [cell.layer setShadowOffset:CGSizeMake(0, 1)];
    [cell.layer setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [cell.layer setShadowRadius:8.0];
    [cell.layer setShadowOpacity:0.8];
    //
    
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.guiStoryNameLabel.text = story.name;
    HMGLogDebug(@"story name: %@" , story.name);
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.guiThumbImage.alpha = story.thumbnail ? 1:0;
    cell.guiThumbImage.image = [self thumbForStory:story forIndexPath:indexPath];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
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

#pragma mark - Table delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!story) return;
    [self performSegueWithIdentifier:@"story details segue" sender:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)handleNoRemakes
{
    if ([self.storiesCV numberOfItemsInSection:0] == 0) {
        [self.noStoriesLabel setHidden:NO];
    } else {
        [self.noStoriesLabel setHidden:YES];
    }
}

@end
