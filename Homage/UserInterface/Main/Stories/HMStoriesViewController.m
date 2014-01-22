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

@interface HMStoriesViewController ()

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end

@implementation HMStoriesViewController

@synthesize fetchedResultsController = _fetchedResultsController;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
    [self initObservers];
    [self initContent];
}

-(void)initGUI
{
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    self.view.backgroundColor = [UIColor clearColor];
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
}

#pragma mark - Observers handlers
-(void)onApplicationStartedNotification:(NSNotification *)notification
{
    //
    // Application notifies that local storage is ready and the app can start.
    //
    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height*2) animated:YES];
    [self refetchStoriesFromServer];
}

-(void)onStoriesRefetched:(NSNotification *)notification
{
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
    if (![self.tableView.indexPathsForVisibleRows containsObject:indexPath]) return;
    
    // Reveal the image animation
    HMStoryCell *cell = (HMStoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.guiThumbImage.alpha = 0;
    cell.guiThumbImage.image = story.thumbnail;
    cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.7 animations:^{
        cell.guiThumbImage.alpha = 1;
        cell.guiThumbImage.transform = CGAffineTransformIdentity;
    }];
}

-(void)onPulledToRefetch
{
    [self refetchStoriesFromServer];
}

#pragma mark - Navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"story details segue"]) {
        //
        // Segue to story details.
        //
        NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
        Story *story = (Story *)[self.fetchedResultsController objectAtIndexPath:indexPath];
        id<HMStoryPresenterProtocol>vc = (id<HMStoryPresenterProtocol>)segue.destinationViewController;
        vc.story = story;
        
    } else {
        HMGLogWarning(@"Segue not implemented:%@",segue.identifier);
    }
}

#pragma mark - Refresh stories
-(void)refetchStoriesFromServer
{
    // Refetch stories from the server
    [HMServer.sh refetchStories];
}

-(void)refreshFromLocalStorage
{
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching stories. %@", error);
        return;
    }
    [self.tableView reloadData];
}

#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
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
    return _fetchedResultsController;
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
}

#pragma mark - Table data source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fetchedResultsController.fetchedObjects.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Story Cell";
    HMStoryCell *cell = (HMStoryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(HMStoryCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.guiStoryNameLabel.text = story.name;
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.guiThumbImage.alpha = story.thumbnail ? 1:0;
    cell.guiThumbImage.image = [self thumbForStory:story forIndexPath:indexPath];
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

#pragma mark - Table delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!story) return;
    [self performSegueWithIdentifier:@"story details segue" sender:nil];
}

@end
