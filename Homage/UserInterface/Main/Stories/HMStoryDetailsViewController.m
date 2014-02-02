//
//  HMStoryDetailsViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryDetailsViewController.h"
#import "HMStoryPresenterProtocol.h"
#import "HMNotificationCenter.h"
#import "HMServer+Remakes.h"
#import "HMServer+LazyLoading.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMRecorderViewController.h"
#import "HMRemakeCell.h"
#import "HMGLog.h"
#import "HMDetailedStoryRemakeVideoPlayerVC.h"

@interface HMStoryDetailsViewController () <UICollectionViewDataSource,UICollectionViewDelegate,HMSimpleVideoPlayerDelegate>

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UICollectionView *remakesCV;
@property (strong,nonatomic) HMSimpleVideoViewController *storyMoviePlayer;
@property (strong,nonatomic) HMSimpleVideoViewController *remakeVideoPlayer;
@property (nonatomic) NSInteger playingRemakeIndex;
@property (weak,nonatomic) Remake *oldRemakeInProgress;
@end

@implementation HMStoryDetailsViewController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize story = _story;


#pragma mark lifecycle related
-(void)viewDidLoad
{
    [super viewDidLoad];
	[self initGUI];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self refetchRemakesForStoryID:self.story.sID];
    [self initContent];
    [self initObservers];
    [self.guiRemakeActivity setHidden:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.guiRemakeActivity setHidden:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self removeObservers];
}

#pragma mark initializations

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
    self.storyMoviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiStoryMovieContainer];
    self.storyMoviePlayer.videoURL = self.story.videoURL;
    [self.storyMoviePlayer hideVideoLabel];
    [self.storyMoviePlayer hideMediaControls];
    self.storyMoviePlayer.videoImage = self.story.thumbnail;
    self.storyMoviePlayer.delegate = self;
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

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL object:nil];
}


#pragma mark - Observers handlers
-(void)onRemakeCreation:(NSNotification *)notification
{
    // Update UI
    self.guiRemakeButton.enabled = YES;
    [self.guiRemakeActivity stopAnimating];
    [self.guiRemakeActivity setHidden:YES];
    
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (notification.isReportingError || !remake) {
        [self remakeCreationFailMessage];
        return;
    }
    
    [self initRecorderWithRemake:remake completion:^{
        [self popView:NO];
    }];
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
    
    HMGLogDebug(@"the bug is in %s" , __PRETTY_FUNCTION__);
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

#pragma mark refreshing remakes

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
    
    NSPredicate *storyPredicate = [NSPredicate predicateWithFormat:@"story=%@", self.story];
    
    NSPredicate *notSameUser = [NSPredicate predicateWithFormat:@"user!=%@" , [User current]];
    
    NSPredicate *compoundPredicate
    = [NSCompoundPredicate andPredicateWithSubpredicates:@[storyPredicate,notSameUser]];
    
    fetchRequest.predicate = compoundPredicate;
    //fetchRequest.predicate = [NSPredicate predicateWithFormat:@"story=%@", self.story];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"sID" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    _fetchedResultsController.delegate = self;
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return _fetchedResultsController;
}

#pragma mark remakes collection view
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
    
    HMGLogDebug(@"the bug is in %s" , __PRETTY_FUNCTION__);
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
    cell.tag = indexPath.item;
    
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

/*-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMGLogDebug(@"the bug is in %s" , __PRETTY_FUNCTION__);
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HMRemakeCell *cell = (HMRemakeCell *)[self.remakesCV cellForItemAtIndexPath:indexPath];
    HMSimpleVideoViewController *vc;
    self.remakeVideoPlayer = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:cell.videoPlayerContainer];
    HMGLogDebug(@"user selected remake with url: %@" , remake.videoURL);
    self.remakeVideoPlayer.delegate = self;
    self.playingRemakeIndex = indexPath.item;
    self.remakeVideoPlayer.videoURL = remake.videoURL;
    [self.remakeVideoPlayer hideVideoLabel];
    [self.remakeVideoPlayer play];
    [cell.videoPlayerContainer setHidden:YES];
    [self.remakeVideoPlayer setFullScreen];
}

 */
-(void)handleNoRemakes
{
    if ([self.remakesCV numberOfItemsInSection:0] == 0) {
        [self.noRemakesLabel setHidden:NO];
    } else {
        [self.noRemakesLabel setHidden:YES];
    }
}

#pragma mark video players

-(void)videoPlayerDidStop
{
    if ([self.storyMoviePlayer isInAction])
    {
        //do nothing.
    } else if ([self.remakeVideoPlayer isInAction])
    {
        [self closeRemakeVideoPlayer];
    }
}

-(void)videoPlayerDidExitFullScreen
{
    if ([self.storyMoviePlayer isInAction])
    {
        //do nothing.
    } else if ([self.remakeVideoPlayer isInAction])
    {
        [self.remakeVideoPlayer done];
    }
}

-(void)videoPlayerWillPlay
{
    if ([self.storyMoviePlayer isInAction])
    {
        [self closeStoryVideoPlayer];
    } else if ([self.remakeVideoPlayer isInAction]) {
        [self closeRemakeVideoPlayer];
    }
}

-(void)closeRemakeVideoPlayer
{
    self.playingRemakeIndex = -1;
}

-(void)closeStoryVideoPlayer
{
    [self.storyMoviePlayer done];
}


#pragma mark - IB Actions
- (IBAction)onPressedRemakeButton:(UIButton *)sender
{
    self.guiRemakeButton.enabled = NO;
    [self.guiRemakeActivity setHidden:NO];
    [self.guiRemakeActivity startAnimating];
    [self.storyMoviePlayer done];
    
    User *user = [User current];
    self.oldRemakeInProgress = [user userPreviousRemakeForStory:self.story.sID];
    
    if (self.oldRemakeInProgress)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"CONTINUE_WITH_REMAKE", nil) message:NSLocalizedString(@"CONTINUE_OR_START_FROM_SCRATCH", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OLD_REMAKE", nil) otherButtonTitles:NSLocalizedString(@"NEW_REMAKE", nil), nil];
        [alertView show];
    } else {
        [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID];
    }
    
}

- (IBAction)closeButtonPushed:(UIButton *)sender
{
    [self popView:YES];
    
}

#pragma mark recorder init
-(void)initRecorderWithRemake:(Remake *)remake completion:(void (^)())completion
{
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:completion];
}

#pragma mark UITextView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    //old
    if (buttonIndex == 0) {
        [self initRecorderWithRemake:self.oldRemakeInProgress completion:^{
            [self popView:NO];
        }];
    }
    //start new remake
    if (buttonIndex == 1) {
        [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID];
    }
}

#pragma mark segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    HMRemakeCell *cell = (HMRemakeCell *)sender;
    
    if ([segue.identifier isEqualToString:@"remakeVideoPlayerSegue"]) {
        HMDetailedStoryRemakeVideoPlayerVC *vc = segue.destinationViewController;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:cell.tag inSection:0];
        Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
        vc.videoURL = remake.videoURL;
    }
}

#pragma mark helper functions
-(void)popView:(BOOL)animated
{
    [self.navigationController popViewControllerAnimated:YES];
}


// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //self.view.backgroundColor = [UIColor clearColor];
}


@end
