//
//  HMStoryDetailsViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryDetailsViewController.h"

#import "HMNotificationCenter.h"
#import "HMServer+Remakes.h"
#import "HMServer+LazyLoading.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMRecorderViewController.h"
#import "HMRemakeCell.h"
#import "HMGLog.h"

@interface HMStoryDetailsViewController () <UICollectionViewDataSource,UICollectionViewDelegate>

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UICollectionView *remakesCV;
@property (strong,nonatomic) HMSimpleVideoViewController *moviePlayer;
@end

@implementation HMStoryDetailsViewController

@synthesize fetchedResultsController = _fetchedResultsController;

@synthesize story = _story;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self refetchRemakesForStoryID:self.story.sID];
    [self initObservers];
    [self initContent];
	[self initGUI];
    
}

-(void)initGUI
{
    self.title = self.story.name;
    self.guiBGImageView.image = [self.story.thumbnail applyBlurWithRadius:2.0 tintColor:nil saturationDeltaFactor:0.3 maskImage:nil];
    [self.guiBGImageView addMotionEffectWithAmount:-30];
    self.noRemakesLabel.text = NSLocalizedString(@"NO_REMAKES", nil);
    self.guiDescriptionField.text = self.story.descriptionText;
    [self initStoryMoviePlayer];
}

-(void)initStoryMoviePlayer
{
    HMSimpleVideoViewController *vc;
    self.moviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guisStoryMovieContainer];
    self.moviePlayer.videoURL = self.story.videoURL;
    [self.moviePlayer hideVideoLabel];
    [self.moviePlayer hideMediaControls];
    self.moviePlayer.videoImage = self.story.thumbnail;
}

-(void)initContent
{
    [self refreshFromLocalStorage];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe remake creation
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeCreation:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_CREATION
                                                     object:nil];
    
    // Observe refetching of remakes for StoryID
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakesRefetched:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY
                                                     object:nil];
    
    // Observe lazy loading thumbnails
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeThumbnailLoaded:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL
                                                     object:nil];
    
}

#pragma mark - Observers handlers
-(void)onRemakeCreation:(NSNotification *)notification
{
    // Update UI
    self.guiRemakeButton.enabled = YES;
    [self.guiRemakeActivity stopAnimating];
    
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (notification.isReportingError || !remake) {
        [self remakeCreationFailMessage];
        return;
    }
    
    // Present the recorder for the newly created remake.
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:nil];
}

-(void)onRemakesRefetched:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
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
    if (![self.remakesCV.indexPathsForVisibleItems containsObject:indexPath]) return;
    
    // Reveal the image
    HMRemakeCell *cell = (HMRemakeCell *)[self.remakesCV cellForItemAtIndexPath:indexPath];
    cell.guiThumbImage.alpha = 0;
    cell.guiThumbImage.image = remake.thumbnail;
    cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [UIView animateWithDuration:0.7 animations:^{
        cell.guiThumbImage.alpha = 1;
        cell.guiThumbImage.transform = CGAffineTransformIdentity;
    }];
    
    cell.guiUserName.text = remake.user.userID;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}

-(void)handleNoRemakes
{
    if ([self.remakesCV numberOfItemsInSection:0] == 0) {
        [self.noRemakesLabel setHidden:NO];
    } else {
        [self.noRemakesLabel setHidden:YES];
    }
}

#pragma mark - Alerts
-(void)remakeCreationFailMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"Failed creating remake.\n\nTry again later."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)refetchRemakesForStoryID:(NSString *)storyID
{
    [HMServer.sh refetchRemakesWithStoryID:storyID];
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
    [self.remakesCV reloadData];
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
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"story=%@", self.story];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sID" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return _fetchedResultsController;
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
    HMRemakeCell *cell = [self.remakesCV dequeueReusableCellWithReuseIdentifier:@"RemakeCell"
                                                                              forIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return cell;
}


- (void)updateCell:(HMRemakeCell *)cell forIndexPath:(NSIndexPath *)indexPath
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
    
    cell.guiUserName.text = remake.user.userID;
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
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HMRemakeCell *cell = (HMRemakeCell *)[self.remakesCV cellForItemAtIndexPath:indexPath];
    HMSimpleVideoViewController *vc;
    vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:cell];
    vc.videoURL = remake.videoURL;
    [vc hideVideoLabel];
    [vc play];
    [vc setFullScreen];
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedRemakeButton:(UIButton *)sender
{
    self.guiRemakeButton.enabled = NO;
    [self.guiRemakeActivity startAnimating];
    [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID];
}


@end
