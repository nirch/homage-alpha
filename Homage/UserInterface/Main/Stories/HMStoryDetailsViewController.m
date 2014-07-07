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
#import "HMColor.h"
#import "Mixpanel.h"
#import "HMSimpleVideoPlayerDelegate.h"
#import "HMServer+ReachabilityMonitor.h"

@interface HMStoryDetailsViewController () <UICollectionViewDataSource,UICollectionViewDelegate,HMRecorderDelegate,UIScrollViewDelegate,HMSimpleVideoPlayerDelegate,UIActionSheetDelegate>

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UICollectionView *remakesCV;
@property (strong,nonatomic) HMSimpleVideoViewController *storyMoviePlayer;
@property (strong,nonatomic) HMSimpleVideoViewController *remakeMoviePlayer;
@property (nonatomic) NSInteger playingRemakeIndex;

@property (weak,nonatomic) Remake *oldRemakeInProgress;
@property (weak,nonatomic) UIView *guiRemakeVideoContainer;
@property (nonatomic) Remake *flaggedRemake;


@end

@implementation HMStoryDetailsViewController

#define REMAKE_ALERT_TAG 100
#define MARK_AS_INAPPROPRIATE_TAG 200
#define HM_EXCLUDE_GRADE -1

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize story = _story;
@synthesize autoStartPlayingStory = _autoStartPlayingStory;


#pragma mark lifecycle related
-(void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super viewDidLoad];
	[self initGUI];
    [self initContent];
    [self refetchRemakesForStoryID:self.story.sID];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiRemakeActivity.hidden = YES;
    if (self.autoStartPlayingStory)
    {
        [self.storyMoviePlayer play];
        self.storyMoviePlayer.shouldAutoPlay = YES;
        self.autoStartPlayingStory = NO;
    }
    [self initObservers];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiRemakeButton.enabled = YES;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiRemakeActivity.hidden = YES;
    [self.guiRemakeActivity stopAnimating];
    [self.storyMoviePlayer done];
    [self removeObservers];
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
    self.title = self.story.name;
    
    [[AMBlurView new] insertIntoView:self.guiBlurredView];
    
    self.noRemakesLabel.text = LS(@"NO_REMAKES");
    self.guiDescriptionField.font = [UIFont fontWithName:@"Avenir Book" size:self.guiDescriptionField.font.pointSize];
    self.guiDescriptionField.text = self.story.descriptionText;
    [self initStoryMoviePlayer];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
}

-(void)initStoryMoviePlayer
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    HMSimpleVideoViewController *vc;
    self.storyMoviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiStoryMovieContainer rotationSensitive:YES];
    self.storyMoviePlayer.videoURL = self.story.videoURL;
    [self.storyMoviePlayer hideVideoLabel];
    [self.storyMoviePlayer hideMediaControls];
    self.storyMoviePlayer.videoImage = self.story.thumbnail;
    self.storyMoviePlayer.delegate = self;
    self.storyMoviePlayer.resetStateWhenVideoEnds = YES;
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
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:nil];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)removeObservers
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


#pragma mark - Observers handlers
-(void)onRemakeCreation:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    [self.guiRemakeActivity stopAnimating];
    self.guiRemakeActivity.hidden = YES;
    
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if ((notification.isReportingError && HMServer.sh.isReachable) || !remake) {
        [self remakeCreationFailMessage];
        HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
        return;
    }
    
    self.guiRemakeButton.enabled = YES;
    [self initRecorderWithRemake:remake completion:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onRemakesRefetched:(NSNotification *)notification
{
    //
    // Backend notifies that local storage was updated with remakes.
    //
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (notification.isReportingError && HMServer.sh.isReachable ) {
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
        [self cleanPrivateRemakes];
        [self refreshFromLocalStorage];
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onRemakeThumbnailLoaded:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSDictionary *info = notification.userInfo;
    
    //need to check if this notification came from the same sender
    id sender = info[@"sender"];
    if (sender != self) return;
    
    NSString *remakeID = info[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (!remake) return;
    
    NSIndexPath *indexPath = info[@"indexPath"];
    UIImage *image = info[@"image"];
    
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
    cell.guiMoreButton.alpha = 1;
    cell.guiThumbImage.image = remake.thumbnail;
    CGAffineTransform transform = CGAffineTransformMakeScale(0.8, 0.8);
    cell.guiThumbImage.transform = transform;
    cell.guiMoreButton.transform = transform;
    
    [UIView animateWithDuration:0.7 animations:^{
        cell.guiThumbImage.alpha = 1;
        cell.guiMoreButton.alpha = 1;
        cell.guiThumbImage.transform = CGAffineTransformIdentity;
        cell.guiMoreButton.transform = CGAffineTransformIdentity;
    }];
    
    cell.guiUserName.text = remake.user.userID;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onReachabilityStatusChange:(NSNotification *)notification
{
    [self setActionsEnabled:HMServer.sh.isReachable];
}

-(void)setActionsEnabled:(BOOL)enabled
{
    
    
    [self.guiRemakeButton setEnabled:NO];
    
    //disable remake CV
    for (UICollectionViewCell *cell in [self.remakesCV visibleCells])
    {
        [cell setUserInteractionEnabled:enabled];
    }
}


#pragma mark - Alerts
-(void)remakeCreationFailMessage
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"Failed creating remake.\n\nTry again later."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

#pragma mark refreshing remakes

-(void)refetchRemakesForStoryID:(NSString *)storyID
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    //when we will get the new refetch from the server, we will have all the still public remakes in hand. the remake parser will put this flag up again, and this way we'll know the remakes we should delete from the DB
    [self markCurrentRemakesAsNonPublic];
    [HMServer.sh refetchRemakesWithStoryID:storyID];
}

-(void)markCurrentRemakesAsNonPublic
{
    for (Remake *remake in self.fetchedResultsController.fetchedObjects)
    {
        if (remake)
        {
            remake.stillPublic = @NO;
        }
    }
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

-(void)cleanPrivateRemakes
{
    for (Remake *remake in self.fetchedResultsController.fetchedObjects)
    {
        if (!remake.stillPublic.boolValue) [DB.sh.context deleteObject:remake];
    }
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
    
    NSPredicate *hidePredicate = [NSPredicate predicateWithFormat:@"grade!=%d" , HM_EXCLUDE_GRADE];
    
    NSPredicate *compoundPredicate
    = [NSCompoundPredicate andPredicateWithSubpredicates:@[storyPredicate,notSameUser,hidePredicate]];
    
    fetchRequest.predicate = compoundPredicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"grade" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO]];
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
    
    cell.guiUserName.text = remake.user.userID;
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.tag = indexPath.item;
    cell.guiMoreButton.tag = indexPath.item;
    
    if (remake.thumbnail) {
        cell.guiThumbImage.image = remake.thumbnail;
        cell.guiThumbImage.alpha = 1;
        cell.guiMoreButton.alpha = 1;
    } else {
        cell.guiThumbImage.alpha = 0;
        cell.guiMoreButton.alpha = 0;
        cell.guiThumbImage.image = nil;
        [HMServer.sh lazyLoadImageFromURL:remake.thumbnailURL
                         placeHolderImage:nil
                         notificationName:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL
                                     info:@{@"indexPath":indexPath,@"sender":self,@"remakeID":remake.sID}
         ];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [[Mixpanel sharedInstance] track:@"SDStartPlayRemake" properties:@{@"remakeID" : remake.sID}];
    self.playingRemakeIndex = indexPath.item;
    [self initVideoPlayerWithURL:[NSURL URLWithString:remake.videoURL]];
}

-(void)handleNoRemakes
{
    if ([self.remakesCV numberOfItemsInSection:0] == 0) {
        [self.noRemakesLabel setHidden:NO];
    } else {
        [self.noRemakesLabel setHidden:YES];
    }
}

#pragma mark HMSimpleVideoPlayerDelegate

-(void)videoPlayerDidStop:(id)sender afterDuration:(NSString *)playbackTime
{
    if (sender == self.remakeMoviePlayer)
    {
        [self.guiRemakeVideoContainer removeFromSuperview];
        [[Mixpanel sharedInstance] track:@"SDStopWatchingRemake" properties:@{@"time_watched" : playbackTime}];
    } else if (sender == self.storyMoviePlayer)
    {
       [[Mixpanel sharedInstance] track:@"SDStopWatchingStory" properties:@{@"time_watched" : playbackTime}];
    }
}

-(void)videoPlayerDidFinishPlaying
{
    [[Mixpanel sharedInstance] track:@"SDVideoPlayerFinished"];
}

-(void)videoPlayerDidExitFullScreen
{
    [[Mixpanel sharedInstance] track:@"SDVideoPlayerExitFullScreen"];
}

-(void)videoPlayerWillPlay
{
    if ([self.storyMoviePlayer isInAction])
    {
      [[Mixpanel sharedInstance] track:@"SDStartPlayStory" properties:@{@"story" : self.story.name}];
    }
}

-(void)videoPlayerWasFired
{
    if ([self.storyMoviePlayer isInAction])
    {
        [self.storyMoviePlayer done];
    }
    if ([self.remakeMoviePlayer isInAction])
    {
        [self.remakeMoviePlayer done];
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


-(void)initVideoPlayerWithURL:(NSURL *)url
{
    UIView *view;
    self.guiRemakeVideoContainer = view = [[UIView alloc] initWithFrame:CGRectZero];
    self.guiRemakeVideoContainer.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.guiRemakeVideoContainer];
    [self.view bringSubviewToFront:self.guiRemakeVideoContainer];
    //[self displayRect:@"self.guiVideoContainer.frame" BoundsOf:self.guiVideoContainer.frame];
    
    self.remakeMoviePlayer = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiRemakeVideoContainer rotationSensitive:YES];
    self.remakeMoviePlayer.videoURL = [url absoluteString];
    [self.remakeMoviePlayer hideVideoLabel];
    //[self.videoView hideMediaControls];
    
    self.remakeMoviePlayer.delegate = self;
    self.remakeMoviePlayer.resetStateWhenVideoEnds = YES;
    [self.remakeMoviePlayer play];
    [self.remakeMoviePlayer setFullScreen];
}



#pragma mark - IB Actions
- (IBAction)onPressedRemakeButton:(UIButton *)sender
{
    self.guiRemakeButton.enabled = NO;
    self.guiRemakeActivity.hidden = NO;
    [self.guiRemakeActivity startAnimating];
    [self.storyMoviePlayer done];
    
    User *user = [User current];
    self.oldRemakeInProgress = [user userPreviousRemakeForStory:self.story.sID];
    

    if (self.oldRemakeInProgress)
    {
        if (self.oldRemakeInProgress.status.integerValue == HMGRemakeStatusNew)
        {
            [self initRecorderWithRemake:self.oldRemakeInProgress];
        } else
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"CONTINUE_WITH_REMAKE") message:LS(@"CONTINUE_OR_START_FROM_SCRATCH") delegate:self cancelButtonTitle:LS(@"CANCEL") otherButtonTitles:LS(@"OLD_REMAKE"), LS(@"NEW_REMAKE") , nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                alertView.tag = REMAKE_ALERT_TAG;
                [alertView show];
            });
        }
    } else {
        [[Mixpanel sharedInstance] track:@"SDNewRemake" properties:@{@"story" : self.story.name}];
        [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID withResolution:@"360"];
    }
}

- (IBAction)moreButtonPushed:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.flaggedRemake = remake;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:LS(@"OPTIONS") delegate:self cancelButtonTitle:LS(@"CANCEL") destructiveButtonTitle:nil otherButtonTitles:LS(@"MARK_AS_INAPPROPRIATE"), nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 0:
            [self showMarkAsInappropriateAlert];
            break;
        default:
            break;
    }
}

-(void)showMarkAsInappropriateAlert
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"MARK_AS_INAPPROPRIATE") message:LS(@"MARK_AS_INAPPROPRIATE_QUESTION") delegate:self cancelButtonTitle:LS(@"NO") otherButtonTitles:LS(@"YES"), nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        alertView.tag = MARK_AS_INAPPROPRIATE_TAG;
        [alertView show];
    });
}

-(void)markAsInapppropriate
{
    NSString *userID = [User current].userID;
    NSString *remakeID = self.flaggedRemake.sID;
    [HMServer.sh markRemakeAsInappropriate:@{@"remake_id" : remakeID , @"user_id" : userID}];
}

#pragma mark recorder init
-(void)initRecorderWithRemake:(Remake *)remake completion:(void (^)())completion
{
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    recorderVC.delegate = self;
    [self.storyMoviePlayer done];
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:completion];
    
}

#pragma mark UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    if (alertView.tag == REMAKE_ALERT_TAG)
    {
        switch (buttonIndex)
        {
            case 0:
                self.guiRemakeActivity.hidden = YES;
                [self.guiRemakeActivity stopAnimating];
                self.guiRemakeButton.enabled = YES;
                break;
            case 1:
                [self initRecorderWithRemake:self.oldRemakeInProgress completion:nil];
                [[Mixpanel sharedInstance] track:@"SDOldRemake" properties:@{@"story" : self.story.name}];
                break;
            case 2:
                [[Mixpanel sharedInstance] track:@"SDNewRemakeOld" properties:@{@"story" : self.story.name}];
                NSString *remakeIDToDelete = self.oldRemakeInProgress.sID;
                [HMServer.sh deleteRemakeWithID:remakeIDToDelete];
                [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID withResolution:@"360"];
                self.oldRemakeInProgress = nil;
        }
    } else if (alertView.tag == MARK_AS_INAPPROPRIATE_TAG)
    {
        switch (buttonIndex)
        {
            case 0:
                break;
            case 1:
                [self markAsInapppropriate];
                break;
        }
    }
}

/* 
#pragma mark segue
 
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //HMRemakeCell *cell = (HMRemakeCell *)sender;
    
    if ([segue.identifier isEqualToString:@"remakeVideoPlayerSegue"]) {
        HMSimpleVideoViewController *vc = segue.destinationViewController;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:cell.tag inSection:0];
        Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
        [[Mixpanel sharedInstance] track:@"SDStartPlayRemake" properties:@{@"story" : self.story.name , @"remakeNum" : [NSString stringWithFormat:@"%d" , indexPath.item]}];
        vc.videoURL = remake.videoURL];
    }
}
 
*/

#pragma mark - HMRecorderDelegate
-(void)recorderAsksDismissalWithReason:(HMRecorderDismissReason)reason
                              remakeID:(NSString *)remakeID
                                sender:(HMRecorderViewController *)sender
{
    HMGLogDebug(@"This is the remake ID the recorder used:%@", remakeID);
    
    self.autoStartPlayingStory = NO;
    // Handle reasons
    if (reason == HMRecorderDismissReasonUserAbortedPressingX)
    {
        //do nothing, need to stay on story details
    } else if (reason == HMRecorderDismissReasonFinishedRemake)
    {
        //[self.navigationController popViewControllerAnimated:YES];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_FINISHED object:self userInfo:@{@"remakeID" : remakeID}];
    }
    
    //Dismiss modal recoder??
    [sender dismissViewControllerAnimated:YES completion:^{
        //[self.navigationController popViewControllerAnimated:YES];
    }];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat currentOffset = self.remakesCV.contentOffset.y;
    CGFloat contentInset = self.remakesCV.contentInset.top;
    self.guiDescriptionBG.alpha = MAX((1-(contentInset + currentOffset)/contentInset),0);
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


// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //self.view.backgroundColor = [UIColor clearColor];
}

@end
