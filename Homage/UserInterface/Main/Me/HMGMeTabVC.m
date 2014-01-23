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
#import <InAppSettingsKit/IASKAppSettingsViewController.h>
#import "HMSimpleVideoViewController.h"
#import "HMSimpleVideoPlayerProtocol.h"


@interface HMGMeTabVC () <IASKSettingsDelegate, UICollectionViewDataSource,UICollectionViewDelegate,HMSimpleVideoPlayerProtocol>

@property (strong,nonatomic) IASKAppSettingsViewController *appSettingsViewController;
@property (strong,nonatomic) HMSimpleVideoViewController *moviePlayer;
@property (weak, nonatomic) IBOutlet UILabel *headLine;
@property (weak, nonatomic) IBOutlet UICollectionView *userRemakesCV;
@property (weak,nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSInteger playingMovieIndex;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (weak,nonatomic) Remake *remakeToDelete;
@property (weak, nonatomic) IBOutlet HMFontLabel *noRemakesLabel;

@end

@implementation HMGMeTabVC

//ask aviv
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize appSettingsViewController = _appSettingsViewController;

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
    //[self.refreshControl beginRefreshing];
    [self refetchRemakesFromServer];

    [self initGUI];
    [self initObservers];
    [self initContent];
    
    self.playingMovieIndex = -1;
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
}

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
    
    UIColor *homageColor = [UIColor colorWithRed:255 green:125 blue:95 alpha:1];
    self.headLine.text = NSLocalizedString(@"ME_TAB_HEADLINE_TITLE", nil);
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
        [alert show];
        HMGLogError(@">>> error in %s: %@", __PRETTY_FUNCTION__ , notification.reportedError.localizedDescription);
    } else {
        [self refreshFromLocalStorage];
    }
    [self.refreshControl endRefreshing];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onRemakeThumbnailLoaded:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    //NSError *error = info[@"error"];
    UIImage *image = info[@"image"];
    
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (notification.isReportingError ) {
        HMGLogError(@">>> error in %s: %@", __PRETTY_FUNCTION__ , notification.reportedError.localizedDescription);
        remake.thumbnail = [UIImage imageNamed:@"errorThumbnail"];
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
        [alert show];
        NSLog(@">>> You also get the NSError object:%@", notification.reportedError.localizedDescription);
    } else {
        [self refetchRemakesFromServer];
        Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
        [DB.sh.context deleteObject:remake];
    }
    
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onPulledToRefetch
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self refetchRemakesFromServer];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark - Refresh stories
-(void)refetchRemakesFromServer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    // Refetch stories from the server
    [HMServer.sh refetchRemakesForUserID:[[User current] email]];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)refreshFromLocalStorage
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching remakes. %@", error);
        return;
    }
    [self.userRemakesCV reloadData];
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
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_REMAKE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user=%@", [User current]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"sID" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return _fetchedResultsController;
}


-(void)viewDidAppear:(BOOL)animated
{
    
}

-(void)viewWillAppear:(BOOL)animated
{

}

-(void)viewWillDisappear:(BOOL)animated
{
    
    [self.moviePlayer done];
    
    //no movie is playing. nothing should happen
    if (self.playingMovieIndex == -1) return;
    
    HMGUserRemakeCVCell *otherRemakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
    [self closeMovieInCell:otherRemakeCell];
    
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
    [cell.layer setBorderColor:[UIColor colorWithRed:213.0/255.0f green:210.0/255.0f blue:199.0/255.0f alpha:1.0f].CGColor];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setCornerRadius:7.5f];
    [cell.layer setShadowOffset:CGSizeMake(0, 1)];
    [cell.layer setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [cell.layer setShadowRadius:8.0];
    [cell.layer setShadowOpacity:0.8];
    //

    //saving indexPath of cell in buttons tags, for easy acsess to index when buttons pushed
    cell.shareButton.tag = indexPath.item;
    cell.actionButton.tag = indexPath.item;
    cell.closeMovieButton.tag = indexPath.item;
    cell.deleteButton.tag = indexPath.item;
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
                                     info:@{@"indexPath":indexPath}
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
    UIImage *bgimage;
    
    switch (status.integerValue)
    {
        case HMGRemakeStatusInProgress:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            bgimage = [UIImage imageNamed:@"complete"];
            [cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
        case HMGRemakeStatusDone:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            bgimage = [UIImage imageNamed:@"play"];
            [cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            [cell.shareButton setHidden:NO];
            cell.shareButton.enabled = YES;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
        
        case HMGRemakeStatusNew:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            bgimage = [UIImage imageNamed:@"underconsruction"];
            [cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;

        case HMGRemakeStatusRendering:
            [cell.actionButton setTitle:@"R" forState:UIControlStateNormal];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = NO;
            break;
            
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
}

-(void)handleNoRemakes
{
    if ([self.userRemakesCV numberOfItemsInSection:0] == 0) {
        [self.noRemakesLabel setHidden:NO];
    } else {
        [self.noRemakesLabel setHidden:YES];
    }
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

-(void)playRemakeVideoWithURL:(NSString *)videoURL inCell:(HMGUserRemakeCVCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
    if (self.playingMovieIndex != -1) //another movie is being played in another cell
    {
        HMGUserRemakeCVCell *otherRemakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
        [self closeMovieInCell:otherRemakeCell];
    }
    
    self.playingMovieIndex = indexPath.item;
    
    HMSimpleVideoViewController *vc;
    self.moviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithNibNamed:@"HMMeVideoPlayer" inParentVC:self containerView:cell.moviePlaceHolder];
    self.moviePlayer.delegate = self;
    self.moviePlayer.videoURL = videoURL;
    [self configureCellForMoviePlaying:cell active:YES];
    [self.moviePlayer play];
}

-(void)configureCellForMoviePlaying:(HMGUserRemakeCVCell *)cell active:(BOOL)active
{
    if (active)
    {
        [cell.moviePlaceHolder insertSubview:self.moviePlayer.view belowSubview:cell.closeMovieButton];
        [cell.guiThumbImage setHidden:YES];
        [cell.buttonsView setHidden:YES];
        [cell.moviePlaceHolder setHidden:NO];
    } else
    {
        [cell.moviePlaceHolder setHidden:YES];
        [cell.guiThumbImage setHidden:NO];
        [cell.buttonsView setHidden:NO];
    }
}

-(void)videoPlayerHitStopButton
{
    HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
    [self closeMovieInCell:cell];
}

-(void)closeMovieInCell:(HMGUserRemakeCVCell *)remakeCell
{
    self.moviePlayer = nil;
    [self configureCellForMoviePlaying:remakeCell active:NO];
    self.playingMovieIndex = -1; //we are good to go and play a movie in another cell
}

- (IBAction)deleteRemake:(UIButton *)sender
{
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag                                                                         inSection:0];
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.remakeToDelete = remake;

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"DELETE_REMAKE", nil) message:NSLocalizedString(@"APPROVE_DELETION", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"NO", nil) otherButtonTitles:NSLocalizedString(@"YES", nil), nil];
    [alertView show];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    //NO?
    if (buttonIndex == 0) {
        self.remakeToDelete = nil;
    }
    //YES?
    if (buttonIndex == 1) {
        NSString *remakeID = self.remakeToDelete.sID;
        HMGLogDebug(@"user chose to delete remake with id: %@" , remakeID);
        [HMServer.sh deleteRemakeWithID:remakeID];
        //[DB.sh.context deleteObject:self.remakeToDelete];
        self.remakeToDelete = nil;
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

#pragma mark settings

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!_appSettingsViewController) {
		_appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
		_appSettingsViewController.delegate = self;
		BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
		_appSettingsViewController.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
	}
	return _appSettingsViewController;
}


- (IBAction)showSettingModal:(id)sender
{
    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
    [self.appSettingsViewController setShowCreditsFooter:NO];
    self.appSettingsViewController.showDoneButton = YES;
    [self presentViewController:aNavController animated:YES completion:Nil];
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
	// your code here to reconfigure the app for changed settings
}

#pragma mark sharing

- (IBAction)shareButtonPushed:(UIButton *)button
{
    NSString *shareString = @"Check out the cool video i created with #Homage App";
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, remake.thumbnail,remake.videoURL , nil];
   UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:shareString forKey:@"subject"];
    activityViewController.excludedActivityTypes = @[UIActivityTypeMessage,UIActivityTypePrint,UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList];
    //activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:activityViewController animated:YES completion:^{}];
    
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

@end
