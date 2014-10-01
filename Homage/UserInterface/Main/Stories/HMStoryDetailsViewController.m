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
#import "HMServer+analytics.h"
#import "HMAppDelegate.h"
#import "HMRegularFontLabel.h"

@interface HMStoryDetailsViewController () <UICollectionViewDataSource,UICollectionViewDelegate,HMRecorderDelegate,UIScrollViewDelegate,HMSimpleVideoPlayerDelegate,UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *remakesCV;
@property (weak,nonatomic) UIView *guiRemakeVideoContainer;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiStoryDescriptionLabel;

// Video player
@property (strong,nonatomic) HMSimpleVideoViewController *storyMoviePlayer;
@property (strong,nonatomic) HMSimpleVideoViewController *remakeMoviePlayer;
@property (nonatomic) NSInteger playingRemakeIndex;

// Data
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (weak,nonatomic) Remake *oldRemakeInProgress;
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
    [super viewDidLoad];
    [self initGUI];
    [self initContent];
    [self refetchRemakesForStoryID:self.story.sID];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.guiRemakeActivity.hidden = YES;
    if (self.autoStartPlayingStory)
    {
        self.storyMoviePlayer.shouldAutoPlay = YES;
        self.autoStartPlayingStory = NO;
    }
    [self initObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    
    self.guiRemakeButton.enabled = YES;
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    
    self.guiRemakeActivity.hidden = YES;
    [self.guiRemakeActivity stopAnimating];
    [self.storyMoviePlayer done];
    [self removeObservers];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    
    
    
}

#pragma mark initializations

-(void)initGUI
{
    self.title = self.story.name;
    
    self.noRemakesLabel.text = LS(@"NO_REMAKES");
    self.guiStoryDescriptionLabel.text = self.story.descriptionText;
    [self initStoryMoviePlayer];
}

-(void)initStoryMoviePlayer
{
    
    HMSimpleVideoViewController *vc;
    self.storyMoviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiStoryMovieContainer rotationSensitive:YES];
    self.storyMoviePlayer.videoURL = self.story.videoURL;
    [self.storyMoviePlayer hideVideoLabel];
    [self.storyMoviePlayer hideMediaControls];
    self.storyMoviePlayer.videoImage = self.story.thumbnail;
    self.storyMoviePlayer.delegate = self;
    self.storyMoviePlayer.originatingScreen = [NSNumber numberWithInteger:HMStoryDetails];
    self.storyMoviePlayer.entityType = [NSNumber numberWithInteger:HMStory];
    self.storyMoviePlayer.entityID = self.story.sID;
    self.storyMoviePlayer.resetStateWhenVideoEnds = YES;
    
}

-(void)initContent
{
    self.noRemakesLabel.alpha = 0;
    self.remakesCV.alpha = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshFromLocalStorage];
        [UIView animateWithDuration:0.2 animations:^{
            self.noRemakesLabel.alpha = 1;
            self.remakesCV.alpha = 1;
        }];
    });
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
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:nil];
    
    
}

-(void)removeObservers
{
    
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_THUMBNAIL object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:nil];
    
}


#pragma mark - Observers handlers
-(void)onRemakeCreation:(NSNotification *)notification
{
    
    
    [self.guiRemakeActivity stopAnimating];
    self.guiRemakeActivity.hidden = YES;
    
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if ((notification.isReportingError && HMServer.sh.isReachable) || !remake) {
        [self remakeCreationFailMessage];
        
        return;
    }
    
    self.guiRemakeButton.enabled = YES;
    [self initRecorderWithRemake:remake completion:nil];
    
}

-(void)onRemakesRefetched:(NSNotification *)notification
{
    //
    // Backend notifies that local storage was updated with remakes.
    //
    
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
        HMGLogError(@">>> error in story details onRemakesRefetched %@", notification.reportedError.localizedDescription);
    } else {
        [self cleanPrivateRemakes];
        [self refreshFromLocalStorage];
    }
    
    
}

-(void)onRemakeThumbnailLoaded:(NSNotification *)notification
{
    
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
        HMGLogError(@">>> error in story details onRemakeThumbnailLoaded: %@", notification.reportedError.localizedDescription);
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
    
    NSError *error;
    
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching remakes. %@", error);
        return;
    }
    
    [self.remakesCV reloadData];
    [self handleNoRemakes];
    
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
    
    
    return _fetchedResultsController;
}

#pragma mark remakes collection view
- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    HMGLogDebug(@"number of items in fetchedObjects: %d" , self.fetchedResultsController.fetchedObjects.count);
    return self.fetchedResultsController.fetchedObjects.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    HMRemakeCell *cell = [self.remakesCV dequeueReusableCellWithReuseIdentifier:@"RemakeCell"
                                                                              forIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    
    return cell;
}


- (void)updateCell:(HMRemakeCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
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
                                     info:@{@"indexPath":indexPath,@"sender":self,@"remakeID":remake.sID}];
        
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.playingRemakeIndex = indexPath.item;
    [self initVideoPlayerWithRemake:remake];
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
    if (self.remakeMoviePlayer.entityType.intValue == HMRemake)
    {
        [self.guiRemakeVideoContainer removeFromSuperview];
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


-(void)initVideoPlayerWithRemake:(Remake *)remake
{
    UIView *view;
    self.guiRemakeVideoContainer = view = [[UIView alloc] initWithFrame:CGRectZero];
    self.guiRemakeVideoContainer.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.guiRemakeVideoContainer];
    [self.view bringSubviewToFront:self.guiRemakeVideoContainer];
    //[self displayRect:@"self.guiVideoContainer.frame" BoundsOf:self.guiVideoContainer.frame];
    
    self.remakeMoviePlayer = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiRemakeVideoContainer rotationSensitive:YES];
    self.remakeMoviePlayer.videoURL = remake.videoURL;
    [self.remakeMoviePlayer hideVideoLabel];
    //[self.videoView hideMediaControls];
    
    self.remakeMoviePlayer.delegate = self;
    self.remakeMoviePlayer.originatingScreen = [NSNumber numberWithInteger:HMStoryDetails];
    self.remakeMoviePlayer.entityType = [NSNumber numberWithInteger:HMRemake];
    self.remakeMoviePlayer.entityID = remake.sID;
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


#pragma mark UIAlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    
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
                [[Mixpanel sharedInstance] track:@"doOldRemake" properties:@{@"story" : self.story.name}];
                break;
            case 2:
                [[Mixpanel sharedInstance] track:@"doNewRemakeOld" properties:@{@"story" : self.story.name}];
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


#pragma mark - HMRecorderDelegate
-(void)recorderAsksDismissalWithReason:(HMRecorderDismissReason)reason
                              remakeID:(NSString *)remakeID
                                sender:(HMRecorderViewController *)sender
{
    HMGLogDebug(@"Recorder asked to be dismissed. This is the remake ID the recorder used:%@", remakeID);
    
    self.autoStartPlayingStory = NO;

    // Handle reasons
    if (reason == HMRecorderDismissReasonUserAbortedPressingX) {

        // Do nothing, need to stay on story details

    } else if (reason == HMRecorderDismissReasonFinishedRemake) {

        // Notify anyone who is interested that the recorder finished
        // with the provided remake id.
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_FINISHED object:self userInfo:@{@"remakeID" : remakeID}];
        
    }
    
    //Dismiss the modal recorder VC.
    [sender dismissViewControllerAnimated:YES completion:^{
        // Mark in app delegate that we left the recorder context
        HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
        app.isInRecorderContext = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }];
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat currentOffset = self.remakesCV.contentOffset.y;
    CGFloat contentInset = self.remakesCV.contentInset.top;
    self.guiStoryDescriptionLabel.alpha = MAX((1-(contentInset + currentOffset)/contentInset),0);
}


#pragma mark recorder init
-(void)initRecorderWithRemake:(Remake *)remake
{
    [self initRecorderWithRemake:remake completion:nil];
}

-(void)initRecorderWithRemake:(Remake *)remake completion:(void (^)())completion
{
    // Handle status bar hiding
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.isInRecorderContext = YES;
    [self setNeedsStatusBarAppearanceUpdate];

    // Open the recorder
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    recorderVC.delegate = self;
    [self.storyMoviePlayer done];
    if (recorderVC) {
        [self presentViewController:recorderVC animated:YES completion:completion];
    } else {
        // Some error occured. Failed to initialize video recorder VC.
        app.isInRecorderContext = NO;
        HMGLogError(@"For some reason, faied to initialize recorder VC");
    }
}

// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //self.view.backgroundColor = [UIColor clearColor];
}

@end
