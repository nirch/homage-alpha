//
//  HMGMeTabVC.m
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMGMeTabVC.h"
#import "HMGLog.h"
#import "HMGUserRemakeCVCell.h"
#import "HMServer+Remakes.h"
#import "HMServer+LazyLoading.h"
#import "HMNotificationCenter.h"
#import "HMFontLabel.h"
//#import <InAppSettingsKit/IASKAppSettingsViewController.h>
//#import "HMSimpleVideoViewController.h"
//#import "HMSimpleVideoPlayerDelegate.h"
#import "HMRecorderViewController.h"
#import "HMColor.h"
#import "mixPanel.h"
#import "HMVideoPlayerVC.h"
#import "HMVideoPlayerDelegate.h"


@interface HMGMeTabVC () < UICollectionViewDataSource,UICollectionViewDelegate,HMRecorderDelegate,HMVideoPlayerDelegate>
//HMSimpleVideoPlayerDelegate removed

//@property (strong,nonatomic) IASKAppSettingsViewController *appSettingsViewController;
//@property (strong,nonatomic) HMSimpleVideoViewController *moviePlayer;
@property (weak, nonatomic) IBOutlet UICollectionView *userRemakesCV;
@property (weak,nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSInteger playingMovieIndex;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSString *currentFetchedResultsUser;
@property (weak,nonatomic) Remake *remakeToDelete;
@property (weak,nonatomic) Remake *remakeToContinueWith;
@property (weak,nonatomic) Remake *remakeToShare;
@property (weak, nonatomic) IBOutlet HMFontLabel *noRemakesLabel;
@property (nonatomic, strong) HMVideoPlayerVC *moviePlayer;

@end

@implementation HMGMeTabVC

#define REMAKE_ALERT_VIEW_TAG 100
#define TRASH_ALERT_VIEW_TAG  200
#define SHARE_ALERT_VIEW_TAG  300

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark lifecycle related
- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    //[self.refreshControl beginRefreshing];
    [self initGUI];
    [self initContent];
    self.playingMovieIndex = -1;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
    
}

-(void)viewWillAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [[Mixpanel sharedInstance] track:@"MEEnterTab"];
    [self initObservers];
    [self refetchRemakesFromServer];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidAppear:(BOOL)animated
{
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self removeObservers];
    //[self.moviePlayer done];
    
    //no movie is playing. nothing should happen
    if (self.playingMovieIndex == -1) return;
    
    HMGUserRemakeCVCell *otherRemakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
    [self closeMovieInCell:otherRemakeCell];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark initializations
-(void)initGUI
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    //init refresh control
    UIRefreshControl *tempRefreshControl = [[UIRefreshControl alloc] init];
    [self.userRemakesCV addSubview:tempRefreshControl];
    self.refreshControl = tempRefreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    
    //self.view.backgroundColor = [UIColor clearColor];
    [self.userRemakesCV setBackgroundColor:[UIColor clearColor]];
    self.userRemakesCV.alwaysBounceVertical = YES;
    
    self.noRemakesLabel.text = NSLocalizedString(@"NO_REMAKES", nil);
    [self.noRemakesLabel setHidden:YES];
    self.noRemakesLabel.textColor = [HMColor.sh textImpact];
    self.title = NSLocalizedString(@"ME_TAB_HEADLINE_TITLE", nil);
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
    
    // Observe refetching of remakes
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakesRefetched:)
                                                       name:HM_NOTIFICATION_SERVER_USER_REMAKES
                                                     object:nil];
    
    // Observe lazy loading thumbnails
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeThumbnailLoaded:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL
                                                     object:nil];
    // Observe deletion of remake
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeDeletion:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_DELETION
                                                     object:nil];
    
    //observe generation of remake
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeCreation:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_CREATION
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(refreshRemakes)
                                                       name:HM_REFRESH_USER_DATA
                                                     object:nil];

    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
}

-(void)removeObservers
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_REMAKES object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_DELETION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_REFRESH_USER_DATA object:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark - Observers handlers
-(void)onRemakesRefetched:(NSNotification *)notification
{
    //
    // Backend notifies that local storage was updated with remakes.
    //
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (notification.isReportingError) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong :-(\n\nTry to refresh later."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        
        HMGLogError(@">>> error in %s: %@", __PRETTY_FUNCTION__ , notification.reportedError.localizedDescription);
    } else {
        [self refreshFromLocalStorage];
    }
    [self.refreshControl endRefreshing];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)refreshRemakes
{
    [self refetchRemakesFromServer];
}

-(void)onRemakeThumbnailLoaded:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSDictionary *info = notification.userInfo;
    
    //need to check if this notification came from the same sender
    id sender = info[@"sender"];
    if (sender != self) return;
    
    NSIndexPath *indexPath = info[@"indexPath"];
    //NSError *error = info[@"error"];
    UIImage *image = info[@"image"];
    
    HMGLogDebug(@"if the bug reproduces, indexPath is: %d" , indexPath.item);
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (notification.isReportingError ) {
        HMGLogError(@">>> error in %s: %@", __PRETTY_FUNCTION__ , notification.reportedError.localizedDescription);
        remake.thumbnail = [UIImage imageNamed:@"missingThumbnail"];
    } else {
        remake.thumbnail = image;
    }
    
    // If row not visible, no need to show the image
    if (![self.userRemakesCV.indexPathsForVisibleItems containsObject:indexPath]) return;
    
    // Reveal the image
    HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)[self.userRemakesCV cellForItemAtIndexPath:indexPath];
    cell.guiThumbImage.alpha = 0;
    cell.guiThumbImage.image = remake.thumbnail;
    cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [UIView animateWithDuration:0.7 animations:^{
        cell.guiThumbImage.alpha = 1;
        cell.guiThumbImage.transform = CGAffineTransformIdentity;
    }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onRemakeDeletion:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSDictionary *info = notification.userInfo;
    NSString *remakeID = info[@"remakeID"];
    
    if (notification.isReportingError) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong :-(\n\nTry to delete the remake later."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        NSLog(@">>> You also get the NSError object:%@", notification.reportedError.localizedDescription);
    } else {
        [self refetchRemakesFromServer];
        Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
        [DB.sh.context deleteObject:remake];
        [remake deleteRawLocalFiles];
    }
    
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onRemakeCreation:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (notification.isReportingError || !remake) {
        [self remakeCreationFailMessage];
        
    }
    
    // Present the recorder for the newly created remake.
    [self initRecorderWithRemake:remake];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark - Refresh my remakes
-(void)refetchRemakesFromServer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [HMServer.sh refetchRemakesForUserID:User.current.userID];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)refreshFromLocalStorage
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    HMGLogDebug(@"num of fetched objects: %d" , self.fetchedResultsController.fetchedObjects.count);
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching remakes. %@", error);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                       [self.userRemakesCV reloadData];
                       [self handleNoRemakes];
                   });
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onPulledToRefetch
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [[Mixpanel sharedInstance] track:@"MEUserRefresh"];
    [self refetchRemakesFromServer];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    // If already exists, just return it.
    if (_fetchedResultsController && [self.currentFetchedResultsUser isEqualToString:[User current].userID]) {
        HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
        return _fetchedResultsController;
    }
    
    // Define fetch request.
    self.currentFetchedResultsUser = [User current].userID;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_REMAKE];
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"user=%@", [User current]];
    //show only inprogress and done remakes
    NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"(status=1 OR status=3 OR status=4)"];
    
    NSPredicate *compoundPredicate
    = [NSCompoundPredicate andPredicateWithSubpredicates:@[userPredicate,statusPredicate]];
    
    fetchRequest.predicate = compoundPredicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"sID" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return _fetchedResultsController;
}


#pragma mark user remakes collection view
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    HMGLogDebug(@"%s started and finished" , __PRETTY_FUNCTION__);
    HMGLogDebug(@"number of items in fetchedObjects: %d" , self.fetchedResultsController.fetchedObjects.count);
    return self.fetchedResultsController.fetchedObjects.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMGUserRemakeCVCell *cell = [self.userRemakesCV dequeueReusableCellWithReuseIdentifier:@"RemakeCell"
                                                                              forIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return cell;
}


- (void)updateCell:(HMGUserRemakeCVCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    //cell border design
    /*[cell.layer setBorderColor:[UIColor colorWithRed:213.0/255.0f green:210.0/255.0f blue:199.0/255.0f alpha:1.0f].CGColor];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setCornerRadius:7.5f];
    [cell.layer setShadowOffset:CGSizeMake(0, 1)];
    [cell.layer setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [cell.layer setShadowRadius:8.0];
    [cell.layer setShadowOpacity:0.8];*/
    //
    
    //saving indexPath of cell in buttons tags, for easy acsess to index when buttons pushed
    cell.shareButton.tag = indexPath.item;
    cell.actionButton.tag = indexPath.item;
    cell.remakeButton.tag = indexPath.item;
    cell.closeMovieButton.tag = indexPath.item;
    cell.deleteButton.tag = indexPath.item;
    cell.tag = indexPath.item;
    //
    
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    
    if (remake.thumbnail) {
        cell.guiThumbImage.image = remake.thumbnail;
        cell.guiThumbImage.alpha = 1;
    } else {
        cell.guiThumbImage.alpha = 0;
        cell.guiThumbImage.image = nil;
        [HMServer.sh lazyLoadImageFromURL:remake.thumbnailURL
                         placeHolderImage:nil
                         notificationName:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL
                                     info:@{@"indexPath":indexPath,@"sender":self}
         ];
    }
    
    cell.storyNameLabel.text = remake.story.name;
    [self updateUIOfRemakeCell:cell withStatus: remake.status];
    
    if (self.playingMovieIndex == indexPath.item)
    {
        [self configureCellForMoviePlaying:cell active:YES];
    } else {
        [self configureCellForMoviePlaying:cell active:NO];
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(void)updateUIOfRemakeCell:(HMGUserRemakeCVCell *)cell withStatus:(NSNumber *)status
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    UIImage *image;
    
    switch (status.integerValue)
    {
        case HMGRemakeStatusInProgress:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            //bgimage = [UIImage imageNamed:@"complete"];
            //[cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
        case HMGRemakeStatusDone:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            image = [UIImage imageNamed:@"play"];
            [cell.actionButton setImage:image forState:UIControlStateNormal];
            [cell.actionButton setHidden:NO];
            cell.actionButton.enabled = YES;
            [cell.shareButton setHidden:NO];
            cell.shareButton.enabled = YES;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
            
        case HMGRemakeStatusNew:
            //[cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            //bgimage = [UIImage imageNamed:@"underconsruction"];
            //[cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
            
        case HMGRemakeStatusRendering:
            //[cell.actionButton setTitle:@"R" forState:UIControlStateNormal];
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
            
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
}

-(void)handleNoRemakes
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if ([self.userRemakesCV numberOfItemsInSection:0] == 0) {
        [self.noRemakesLabel setHidden:NO];
    } else {
        [self.noRemakesLabel setHidden:YES];
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark cell action button

- (IBAction)actionButtonPushed:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HMGLogInfo(@"the user selected remake at index: %d" , indexPath.item);
    HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)[self.userRemakesCV cellForItemAtIndexPath:indexPath];
    switch (remake.status.integerValue)
    {
        case HMGRemakeStatusDone:
            [[Mixpanel sharedInstance] track:@"MEPlayRemake" properties:@{@"Story" : remake.story.name}];
            [self playRemakeVideoWithURL:remake.videoURL inCell:cell withIndexPath:indexPath];
            break;
        case HMGRemakeStatusInProgress:
            //TODO:connect to recorder at last non taken scene
            break;
        case HMGRemakeStatusNew:
            //TODO:connect to recorder at last non taken scene
            break;
        case HMGRemakeStatusRendering:
            //TODO: what to do?
            break;
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark video player
-(void)playRemakeVideoWithURL:(NSString *)videoURL inCell:(HMGUserRemakeCVCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
    
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (self.playingMovieIndex != -1) //another movie is being played in another cell
    {
        HMGUserRemakeCVCell *otherRemakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
        [self closeMovieInCell:otherRemakeCell];
    }
    
    self.playingMovieIndex = indexPath.item;
    HMVideoPlayerVC *videoPlayerVC = [[HMVideoPlayerVC alloc ] init];
    videoPlayerVC.delegate = self;
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    videoPlayerVC.videoURL = [NSURL URLWithString:remake.videoURL];
    self.moviePlayer = videoPlayerVC;
    [self presentViewController:videoPlayerVC animated:YES completion:nil];
    
    //old code for playing movie inside cell
    /*HMSimpleVideoViewController *vc;
     self.moviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMMeVideoPlayer" inParentVC:self containerView:cell.moviePlaceHolder];
     self.moviePlayer.delegate = self;
     self.moviePlayer.videoURL = videoURL;
     [self configureCellForMoviePlaying:cell active:YES];
     [self.moviePlayer play];
     [self.moviePlayer setScalingMode:@"aspect fit"];*/
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)configureCellForMoviePlaying:(HMGUserRemakeCVCell *)cell active:(BOOL)active
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (active)
    {
        //[cell.moviePlaceHolder insertSubview:self.moviePlayer.view belowSubview:cell.closeMovieButton];
        [cell.guiThumbImage setHidden:YES];
        [cell.buttonsView setHidden:YES];
        [cell.moviePlaceHolder setHidden:NO];
    } else
    {
        [cell.moviePlaceHolder setHidden:YES];
        [cell.guiThumbImage setHidden:NO];
        [cell.buttonsView setHidden:NO];
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

//HMSimpleVideoPlayerDelegate delegate function
-(void)videoPlayerDidStop
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (self.playingMovieIndex != -1)
        [self closeCurrentlyPlayingMovie];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)closeCurrentlyPlayingMovie
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
    [self closeMovieInCell:cell];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)closeMovieInCell:(HMGUserRemakeCVCell *)remakeCell
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    //self.moviePlayer = nil;
    [self configureCellForMoviePlaying:remakeCell active:NO];
    self.playingMovieIndex = -1; //we are good to go and play a movie in another cell
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark remaking
- (IBAction)deleteRemake:(UIButton *)sender
{
    
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag                                                                         inSection:0];
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.remakeToDelete = remake;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"DELETE_REMAKE", nil) message:NSLocalizedString(@"APPROVE_DELETION", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
    
    alertView.tag = TRASH_ALERT_VIEW_TAG;
    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(void)remakeCreationFailMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"Failed creating remake.\n\nTry again later."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}


- (IBAction)remakeButtonPushed:(UIButton *)button
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self closeCurrentlyPlayingMovie];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    
    self.remakeToContinueWith = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [[Mixpanel sharedInstance] track:@"MEDoRemake" properties:@{@"Story" : self.remakeToContinueWith.story.name}];
    HMGLogDebug(@"gonna remake story: %@" , self.remakeToContinueWith.story.name);
    
    if (self.remakeToContinueWith.status.integerValue != HMGRemakeStatusDone) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"CONTINUE_WITH_REMAKE", nil) message:NSLocalizedString(@"CONTINUE_OR_START_FROM_SCRATCH", nil) delegate:self cancelButtonTitle:LS(@"CANCEL") otherButtonTitles:LS(@"OLD_REMAKE"), LS(@"NEW_REMAKE") , nil];
        alertView.tag = REMAKE_ALERT_VIEW_TAG;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    } else {
        [HMServer.sh createRemakeForStoryWithID:self.remakeToContinueWith.story.sID forUserID:User.current.userID];
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark sharing
- (IBAction)shareButtonPushed:(UIButton *)button
{
    
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    
    Remake *remakeToShare = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if ([[User current] isGuestUser])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"SIGN_UP_NOW", nil) message:NSLocalizedString(@"ONLY_SIGN_IN_USERS_CAN_SHARE", nil) delegate:self cancelButtonTitle:LS(@"NOT_NOW") otherButtonTitles:LS(@"JOIN_NOW"), nil];
        alertView.tag = SHARE_ALERT_VIEW_TAG;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });

    } else [self shareRemake:remakeToShare];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)shareRemake:(Remake *)remake
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSString *shareString = @"Check out the cool video i created with #HomageApp";
    [[Mixpanel sharedInstance] track:@"MEShareRemake" properties:@{@"Story" : remake.story.name}];
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, remake.thumbnail,remake.shareURL , nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:shareString forKey:@"subject"];
    activityViewController.excludedActivityTypes = @[UIActivityTypeMessage,UIActivityTypePrint,UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:activityViewController animated:YES completion:^{}];
    });
 
}

#pragma mark recorder init
-(void)initRecorderWithRemake:(Remake *)remake
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    recorderVC.delegate = self;
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark UITextView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    //remake button pushed
    if (alertView.tag == REMAKE_ALERT_VIEW_TAG)
    {
        
        if (buttonIndex == 0)
        {
            
        }
        
        //continue with old remake
        if (buttonIndex == 1) {
            // Present the recorder for the newly created remake.
            [self initRecorderWithRemake:self.remakeToContinueWith];
            [[Mixpanel sharedInstance] track:@"MEOldRemake" properties:@{@"story" : self.remakeToContinueWith.story.name}];
        }
        //start new remake
        if (buttonIndex == 2) {
            NSString *remakeIDToDelete = self.remakeToContinueWith.sID;
            [[Mixpanel sharedInstance] track:@"MENewRemakeWithOld" properties:@{@"story" : self.remakeToContinueWith.story.name}];
            [HMServer.sh deleteRemakeWithID:remakeIDToDelete];
            [HMServer.sh createRemakeForStoryWithID:self.remakeToContinueWith.story.sID forUserID:User.current.userID];
            self.remakeToContinueWith = nil;
        }
        
        //trash button pushed
    } else if (alertView.tag == TRASH_ALERT_VIEW_TAG)
    {
        if (buttonIndex == 0) {
            self.remakeToDelete = nil;
        }
        if (buttonIndex == 1) {
            NSString *remakeID = self.remakeToDelete.sID;
            [[Mixpanel sharedInstance] track:@"MEDeleteRemake" properties:@{@"Story" : self.remakeToDelete.story.name}];
            [HMServer.sh deleteRemakeWithID:remakeID];
            //[DB.sh.context deleteObject:self.remakeToDelete];
            
            self.remakeToDelete = nil;
        }
    } else if (alertView.tag == SHARE_ALERT_VIEW_TAG)
    {
        //dont join
        if (buttonIndex == 0)
        {
            self.remakeToShare = nil;
        }
        //join now!
        if (buttonIndex == 1)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_USER_JOIN object:nil userInfo:nil];
        }
    
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark helper functions
-(void)displayViewBounds:(UIView *)view
{
    CGRect frame = view.bounds;
    CGFloat originX = frame.origin.x;
    CGFloat originY = frame.origin.y;
    CGFloat width = frame.size.width;
    CGFloat height = frame.size.height;
    
    NSLog(@"view bounds of cell are: origin:(%f,%f) height: %f width: %f" , originX,originY,height,width);
    
}

-(UICollectionViewCell *)getCellFromCollectionView:(UICollectionView *)collectionView atIndex:(NSInteger)index atSection:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - HMRecorderDelegate
-(void)recorderAsksDismissalWithReason:(HMRecorderDismissReason)reason
                              remakeID:(NSString *)remakeID
                                sender:(HMRecorderViewController *)sender
{
    HMGLogDebug(@"This is the remake ID the recorder used:%@", remakeID);
    
    // Handle reasons
    if (reason == HMRecorderDismissReasonUserAbortedPressingX)
    {
        //do nothing, need to stay on story details
    } else if (reason == HMRecorderDismissReasonFinishedRemake)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_FINISHED object:self userInfo:@{@"remakeID" : remakeID}];
    }
    
    //Dismiss modal recoder??
    [sender dismissViewControllerAnimated:YES completion:^{
        //[self.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark HMVideoPlayerVC delegate
-(void)videoPlayerFinishedPlaying
{
    [self.moviePlayer dismissViewControllerAnimated:YES completion:nil];
    [[Mixpanel sharedInstance] track:@"MEFinishWatchRemake"];
}

-(void)videoPlayerStopped
{
    [self.moviePlayer dismissViewControllerAnimated:YES completion:nil];
    [[Mixpanel sharedInstance] track:@"MEStopWatchRemake"];
}


// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //self.view.backgroundColor = [UIColor clearColor];
}

@end
