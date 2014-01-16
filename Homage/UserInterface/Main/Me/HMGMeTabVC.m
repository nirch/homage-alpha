//
//  HMGMeTabVC.m
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMGMeTabVC.h"
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>
#import "HMGLog.h"
#import "HMGUserRemakeCVCell.h"
#import "HMServer+Remakes.h"
#import "HMServer+LazyLoading.h"
#import "HMNotificationCenter.h"



@interface HMGMeTabVC () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (strong,nonatomic) MPMoviePlayerController *movieplayer;
@property (weak, nonatomic) IBOutlet UILabel *headLine;
@property (weak, nonatomic) IBOutlet UICollectionView *userRemakesCV;
@property (weak,nonatomic) UIRefreshControl *refreshControl;
@property (strong,nonatomic) NSArray *userRemakes;
@property (nonatomic) NSInteger playingMovieIndex;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;

@end

@implementation HMGMeTabVC

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad
{
    User *user = [User current];
    HMGLogDebug(@"current user is: %@" , user.email);
    [super viewDidLoad];
    [self.refreshControl beginRefreshing];
    [self refetchRemakesFromServer];

    [self initGUI];
    [self initObservers];
    [self initContent];
    
    self.playingMovieIndex = -1;
    self.headLine.text = NSLocalizedString(@"ME_TAB_HEADLINE_TITLE", nil);
    
}

-(void)initGUI
{
    UIRefreshControl *tempRefreshControl = [[UIRefreshControl alloc] init];
    [self.userRemakesCV addSubview:tempRefreshControl];
    self.refreshControl = tempRefreshControl;
    self.userRemakesCV.alwaysBounceVertical = YES;
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
                                                   selector:@selector(onRemakesRefetched:)
                                                       name:HM_NOTIFICATION_SERVER_FETCHED_USER_REMAKES
                                                     object:nil];
    
    // Observe lazy loading thumbnails
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeThumbnailLoaded:)
                                                       name:HM_NOTIFICATION_SERVER_FETCHED_STORY_THUMBNAIL
                                                     object:nil];
}

#pragma mark - Observers handlers
-(void)onApplicationStartedNotification:(NSNotification *)notification
{
    HMGLogDebug(@"onApplicationStartedNotification recieved");
    //
    // Application notifies that local storage is ready and the app can start.
    //
    [self.refreshControl beginRefreshing];
    [self refetchRemakesFromServer];
}

-(void)onRemakesRefetched:(NSNotification *)notification
{
    //
    // Backend notifies that local storage was updated with stories.
    //
    HMGLogDebug(@"onRemakesRefetched recieved");
    [self.refreshControl endRefreshing];
    [self refreshFromLocalStorage];
}

-(void)onRemakeThumbnailLoaded:(NSNotification *)notification
{
    HMGLogDebug(@"onRemakeThumbnailLoaded recieved");
    NSDictionary *info = notification.userInfo;
    NSIndexPath *indexPath = info[@"indexPath"];
    NSError *error = info[@"error"];
    UIImage *image = info[@"image"];
    
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (error || !image) {
        remake.thumbnail = nil;
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
}


#pragma mark - Refresh stories
-(void)refetchRemakesFromServer
{
    // Refetch stories from the server
    [HMServer.sh refetchRemakesForUserID:[[User current] email]];
}

-(void)refreshFromLocalStorage
{
    NSError *error;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching remakes. %@", error);
        return;
    }
    [self.userRemakesCV reloadData];
}

#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
    // If already exists, just return it.
    if (_fetchedResultsController) return _fetchedResultsController;
    
    // Define fetch request.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_REMAKE];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user=%@", [User current]];
    HMGLogDebug(@"current user is: %@" , [User current].email);
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:YES]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    return _fetchedResultsController;
}


-(void)viewDidAppear:(BOOL)animated
{
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.userRemakesCV reloadData];
}

-(void)viewDidDisappear:(BOOL)animated
{
    
    if (self.playingMovieIndex == -1) return;
    HMGUserRemakeCVCell *otherRemakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
    [self closeMovieInCell:otherRemakeCell];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    [cell.layer setBorderColor:[UIColor colorWithRed:213.0/255.0f green:210.0/255.0f blue:199.0/255.0f alpha:1.0f].CGColor];
    [cell.layer setBorderWidth:1.0f];
    [cell.layer setCornerRadius:7.5f];
    [cell.layer setShadowOffset:CGSizeMake(0, 1)];
    [cell.layer setShadowColor:[[UIColor darkGrayColor] CGColor]];
    [cell.layer setShadowRadius:8.0];
    [cell.layer setShadowOpacity:0.8];

    cell.shareButton.tag = indexPath.item;
    cell.actionButton.tag = indexPath.item;
    cell.closeMovieButton.tag = indexPath.item;
        
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    
    if (remake.thumbnail) {
        cell.guiThumbImage.image = remake.thumbnail;
        cell.guiThumbImage.alpha = 1;
    } else {
        cell.guiThumbImage.alpha = 0;
        cell.guiThumbImage.image = nil;
        [HMServer.sh lazyLoadImageFromURL:remake.thumbnailURL
                         placeHolderImage:nil
                         notificationName:HM_NOTIFICATION_SERVER_FETCHED_STORY_THUMBNAIL
                                     info:@{@"indexPath":indexPath}
         ];
    }
    
    [self updateUIOfRemakeCell:cell withStatus: remake.status];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(void)updateUIOfRemakeCell:(HMGUserRemakeCVCell *)cell withStatus:(NSNumber *)status
{
    NSString *imagePath;
    UIImage *bgimage;
    
    switch (status.integerValue)
    {
        case HMGRemakeStatusInProgress:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"underconsruction" ofType:@"png"];
            bgimage = [UIImage imageWithContentsOfFile:imagePath];
            [cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
        case HMGRemakeStatusDone:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"pb_play_icon" ofType:@"png"];
            bgimage = [UIImage imageWithContentsOfFile:imagePath];
            [cell.actionButton setImage:bgimage forState:UIControlStateNormal];
            [cell.shareButton setHidden:NO];
            cell.shareButton.enabled = YES;
            cell.remakeButton.enabled = YES;
            cell.deleteButton.enabled = YES;
            break;
        
        case HMGRemakeStatusNew:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            imagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"underconsruction.png" ofType:nil];
            bgimage = [UIImage imageWithContentsOfFile:imagePath];
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
    
    NSURL *URL = [NSURL URLWithString:videoURL];
    
    self.movieplayer = [[MPMoviePlayerController alloc] initWithContentURL:URL];
    self.movieplayer.controlStyle = MPMovieControlStyleEmbedded;
    self.movieplayer.scalingMode = MPMovieScalingModeAspectFit;
    [self.movieplayer.view setFrame: cell.bounds];
    self.playingMovieIndex = indexPath.item;
    self.movieplayer.shouldAutoplay = YES;
    [cell.moviePlaceHolder insertSubview:self.movieplayer.view belowSubview:cell.closeMovieButton];
    [cell.guiThumbImage setHidden:YES];
    [cell.buttonsView setHidden:YES];
    [cell.moviePlaceHolder setHidden:NO];
    [self.movieplayer setFullscreen:NO animated:YES];
}

- (IBAction)closeMovieButtonPushed:(UIButton *)sender
{
    HMGUserRemakeCVCell *remakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:sender.tag atSection:0];
    [self closeMovieInCell:remakeCell];
}

-(void)closeMovieInCell:(HMGUserRemakeCVCell *)remakeCell
{
    [self.movieplayer stop];
    self.movieplayer = nil;
    [remakeCell.moviePlaceHolder setHidden:YES];
    [remakeCell.guiThumbImage setHidden:NO];
    [remakeCell.buttonsView setHidden:NO];
    self.playingMovieIndex = -1; //we are good to go and play a movie in another cell
}

#pragma mark settings

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
		appSettingsViewController.delegate = self;
		BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
		appSettingsViewController.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
	}
	return appSettingsViewController;
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
    activityViewController.excludedActivityTypes = @[UIActivityTypePostToTwitter,UIActivityTypeMessage,UIActivityTypePrint,UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList];
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


@end
