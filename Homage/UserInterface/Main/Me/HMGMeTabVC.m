//
//  HMGMeTabVC.m
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMGMeTabVC.h"
#import "HMGLog.h"
#import "HMRegularFontLabel.h"
#import "HMGUserRemakeCVCell.h"
#import "HMServer+Remakes.h"
#import "HMNotificationCenter.h"
#import "HMRecorderViewController.h"
#import "HMStyle.h"
#import "mixPanel.h"
#import "HMVideoPlayerDelegate.h"
#import "HMSimpleVideoViewController.h"
#import "JBWhatsAppActivity.h"
#import "HMServer+ReachabilityMonitor.h"
#import "NSDictionary+TypeSafeValues.h"
#import "HMServer+analytics.h"
#import "HMAppDelegate.h"
#import "AWAlertView.h"
#import "UIView+Hierarchy.h"
#import "HMSharing.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define SCROLL_VIEW_CELL 1
#define SCROLL_VIEW_CV 70

#define ALERT_VIEW_TAG_SHARE_FAILED 200

@interface HMGMeTabVC () < UICollectionViewDataSource,UICollectionViewDelegate,HMRecorderDelegate,HMVideoPlayerDelegate,HMSimpleVideoPlayerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *guiRemakeMoreStoriesButton;
@property (weak, nonatomic) IBOutlet UIButton *lastShareButtonPressed;
@property (weak, nonatomic) IBOutlet UICollectionView *userRemakesCV;

@property (weak,nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSInteger playingMovieIndex;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSString *currentFetchedResultsUser;

@property (weak,nonatomic) Remake *remakeToContinueWith;
@property (weak,nonatomic) Remake *remakeToShare;

@property (weak, nonatomic) IBOutlet HMRegularFontLabel *noRemakesLabel;
@property (nonatomic,weak) UIView *guiVideoContainer;

@property (nonatomic) HMSharing *currentSharer;

@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *guiCellPanGestureRecognizer;

@property (nonatomic) BOOL needsCheckIfAllClosed;

// Yes, the name of the variable is long because it is funny. deal with it!
@property (nonatomic) CGFloat bottomButtonAppearanceThresholdThatIsUsedToDetermineWhenToShowOrHideIt;

@end

@implementation HMGMeTabVC

#define REMAKE_ALERT_VIEW_TAG 100
#define TRASH_ALERT_VIEW_TAG  200
#define SHARE_ALERT_VIEW_TAG  300

//#define HOMAGE_APPSTORE_LINK @"https://itunes.apple.com/us/app/homage/id851746600?l=iw&ls=1&mt=8"

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark lifecycle related
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //self.remakesToDeleteInfo = [NSMutableDictionary new];
    
    [self initGUI];
    [self initContent];
    [self initPermanentObservers];
    
    self.playingMovieIndex = -1;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[Mixpanel sharedInstance] track:@"MEEnterTab"];
    [self initObservers];
    [self refreshFromLocalStorage];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UIEdgeInsets e = self.userRemakesCV.contentInset;
    e.bottom = 314;
    self.userRemakesCV.contentInset = e;
    [self handleVisibilityOfMoreStoriesButton];
    [self updateRenderingBarState];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObservers];
    //[self.moviePlayer done];
    
    //no movie is playing. nothing should happen
    if (self.playingMovieIndex == -1) return;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark initializations
-(void)initGUI
{
    //init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.userRemakesCV addSubview:refreshControl];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
    //self.refreshControl.tintColor = [HMColor.sh main2];
    CGRect f = [[refreshControl.subviews objectAtIndex:0] frame];
    f.origin.y += 32;
    [[refreshControl.subviews objectAtIndex:0] setFrame:f];
    refreshControl.layer.zPosition = -1;
    
    //self.view.backgroundColor = [UIColor clearColor];
    [self.userRemakesCV setBackgroundColor:[UIColor clearColor]];
    self.userRemakesCV.alwaysBounceVertical = YES;
    
    self.noRemakesLabel.text = LS(@"NO_REMAKES_ME_SCREEN");
    [self.noRemakesLabel setHidden:YES];
    //self.noRemakesLabel.textColor = [HMColor.sh textImpact];
    self.title = LS(@"ME_TAB_HEADLINE_TITLE");
    
    // Checks if need to close "opened" cells.
    self.needsCheckIfAllClosed = NO;
    
    // Goto stories button
    CGFloat t = IS_IPHONE_5 ? 510 : 470;
    self.bottomButtonAppearanceThresholdThatIsUsedToDetermineWhenToShowOrHideIt = t;
    [self _remakeMoreStoriesOutOfScreenPosition];
}

-(void)initContent
{
    [self refreshFromLocalStorage];
    [self refetchRemakesFromServer];
}

#pragma mark - Observers

-(void)initPermanentObservers
{
    //app notifying "me" tab that a user had chnaged, and need to show a different feed
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(refreshRemakes)
                                                       name:HM_REFRESH_USER_DATA
                                                     object:nil];
    
    // Observe refetching of remakes
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakesRefetched:)
                                                       name:HM_NOTIFICATION_SERVER_USER_REMAKES
                                                     object:nil];
    
    // Observe refetching a specific remake
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeRefetched:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE
                                                     object:nil];

    // Observe deletion of remake
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeDeletion:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_DELETION
                                                     object:nil];
    
    // Observe rendering bar
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRenderingBarStateChanged:)
                                                       name:HM_NOTIFICATION_UI_RENDERING_BAR_HIDDEN
                                                     object:nil];
    
    // Observe rendering bar
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRenderingBarStateChanged:)
                                                       name:HM_NOTIFICATION_UI_RENDERING_BAR_SHOWN
                                                     object:nil];
}

-(void)initObservers
{
    //observe generation of remake
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeCreation:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_CREATION
                                                     object:nil];
    
    // Observe share request
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onShareRemakeRequest:)
                                                       name:HM_NOTIFICATION_SERVER_SHARE_REMAKE_REQUEST
                                                     object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SHARE_REMAKE_REQUEST object:nil];
}

#pragma mark - Observers handlers
-(void)onRemakesRefetched:(NSNotification *)notification
{
    //
    // Backend notifies that local storage was updated with remakes.
    //
    if (notification.isReportingError && HMServer.sh.isReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong. \n\nTry to refresh in a few moments."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        
        HMGLogError(@">>> error in onRemakesRefetched: %@", notification.reportedError.localizedDescription);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.userRemakesCV.hidden = NO;
            [self refreshFromLocalStorage];
            [self.userRemakesCV reloadData];
            [self.refreshControl endRefreshing];
        });
    }
}

-(void)onRenderingBarStateChanged:(NSNotification *)notification
{
    [self updateRenderingBarState];
}

-(void)onRemakeRefetched:(NSNotification *)notification
{
    [self refreshFromLocalStorage];
}

-(void)refreshRemakes
{
    [self refreshFromLocalStorage];
    [self refetchRemakesFromServer];
}


-(void)onRemakeDeletion:(NSNotification *)notification
{
    // For now, just refetch and reload.
    // TODO: add a proper implementation of NSFetchedResultsControllerDelegate
    if (notification.isReportingError && HMServer.sh.isReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                        message:@"Something went wrong.\n\nTry to delete the remake in a few moments."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        [alert show];
    }

    // Refresh and reload
    [self refreshFromLocalStorage];
}

-(void)onRemakeCreation:(NSNotification *)notification
{
    // Get the new remake object.
    NSString *remakeID = notification.userInfo[@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if ((notification.isReportingError && HMServer.sh.isReachable) || !remake ) {
        [self remakeCreationFailMessage];
    }
    
    // Present the recorder for the newly created remake.
    [self initRecorderWithRemake:remake];
}

-(void)onShareRemakeRequest:(NSNotification *)notification
{
    if (notification.isReportingError) {
        // Failed to request a share remake object from the server.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:LS(@"SHARE_REMAKE_FAILED_TITLE")
                                                            message:LS(@"SHARE_REMAKE_FAILED_BODY")
                                                           delegate:self
                                                  cancelButtonTitle:LS(@"CANCEL_BUTTON")
                                                  otherButtonTitles:LS(@"TRY_AGAIN_BUTTON"), nil];
        alertView.tag = ALERT_VIEW_TAG_SHARE_FAILED;
        [alertView show];
        return;
    }
    
    // No error reported.
    // The share bundle is ready for sharing.
    // Open the ui for the user.
    NSDictionary *shareBundle = notification.userInfo[@"share_bundle"];
    [self.currentSharer shareRemakeBundle:shareBundle
                                 parentVC:self
                           trackEventName:@"MEShareRemake"
                                thumbnail:self.currentSharer.image
                                    sourceView:self.lastShareButtonPressed];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stopShareActivity];
        self.currentSharer = nil;
    });
}

-(void)stopShareActivity
{
    for (HMGUserRemakeCVCell *cell in self.userRemakesCV.visibleCells) {
        [cell.shareActivity stopAnimating];
        [cell.shareButton setHidden:NO];
    }
}

#pragma mark - Rendering bar states
-(void)updateRenderingBarState
{
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    [UIView animateWithDuration:1.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        if ([app.mainVC isRenderingViewShowing]) {
            UIEdgeInsets c = self.userRemakesCV.contentInset;
            c.top = [app.mainVC renderingViewHeight];
            self.userRemakesCV.contentInset = c;
        } else {
            UIEdgeInsets c = self.userRemakesCV.contentInset;
            c.top = 0;
            self.userRemakesCV.contentInset = c;
        }
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - Refresh my remakes
-(void)refetchRemakesFromServer
{
    [HMServer.sh refetchRemakesForUserID:User.current.userID];
}

-(void)refreshFromLocalStorage
{
    NSError *error;
    _fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:&error];
    HMGLogDebug(@"num of fetched objects: %d" , self.fetchedResultsController.fetchedObjects.count);
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching remakes. %@", error);
        return;
    }
    [self.userRemakesCV reloadData];
    [self handleRemakesCount];
}

-(void)onPulledToRefetch
{
    [[Mixpanel sharedInstance] track:@"MEUserRefresh"];
    [self refetchRemakesFromServer];
}


#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
    // If already exists, just return it.
    NSString *currentUserID = [User current].userID;
    if (_fetchedResultsController && [self.currentFetchedResultsUser isEqualToString:currentUserID]) {
        return _fetchedResultsController;
    }
    
    // Define fetch request.
    self.currentFetchedResultsUser = currentUserID;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_REMAKE];
    
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"user=%@", [User current]];
    //show only in progress and done remakes
    NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"(status=1 OR status=3 OR status=4)"];
    
    NSPredicate *compoundPredicate
    = [NSCompoundPredicate andPredicateWithSubpredicates:@[userPredicate,statusPredicate]];
    
    fetchRequest.predicate = compoundPredicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    

    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    //_fetchedResultsController.delegate = self;
    
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
    HMGLogDebug(@"number of items in fetchedObjects: %d" , self.fetchedResultsController.fetchedObjects.count);
    return self.fetchedResultsController.fetchedObjects.count;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMGUserRemakeCVCell *cell = [self.userRemakesCV dequeueReusableCellWithReuseIdentifier:@"RemakeCell"
                                                                              forIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    return cell;
}

- (void)updateCell:(HMGUserRemakeCVCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];

    //saving indexPath of cell in buttons tags, for easy acsess to index when buttons pushed
    /*cell.shareButton.tag = indexPath.item;
    cell.actionButton.tag = indexPath.item;
    cell.remakeButton.tag = indexPath.item;
    cell.closeMovieButton.tag = indexPath.item;
    cell.deleteButton.tag = indexPath.item;
    cell.tag = indexPath.item;*/
    //
    
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    if (cell.guiScrollView.delegate == nil) cell.guiScrollView.delegate = self;
    [cell closeAnimated:NO];
    
    cell.guiThumbImage.alpha = 0;
    NSURL *thumbURL = [NSURL URLWithString:remake.thumbnailURL];
    [cell.guiThumbImage sd_setImageWithURL:thumbURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        cell.guiThumbImage.image = image;
        if (cacheType == SDImageCacheTypeNone) {
            // Reveal with animation
            [UIView animateWithDuration:0.2 animations:^{
                cell.guiThumbImage.alpha = 1;
            }];
        } else {
            // Reveal with no animation.
            cell.guiThumbImage.alpha = 1;
        }
    }];
    
    cell.storyNameLabel.text = remake.story.name;
    [self updateUIOfRemakeCell:cell withStatus: remake.status];
}

-(void)updateUIOfRemakeCell:(HMGUserRemakeCVCell *)cell withStatus:(NSNumber *)status
{
    UIImage *image;
    
    cell.remakeButton.alpha = 1;
    [cell.shareActivity stopAnimating];
    cell.guiScrollView.contentSize = CGSizeMake(640, cell.guiScrollView.bounds.size.height);
    
    switch (status.intValue)
    {
        case HMGRemakeStatusInProgress:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            break;
            
        case HMGRemakeStatusDone:
            [cell.actionButton setTitle:@"" forState:UIControlStateNormal];
            image = [UIImage imageNamed:@"myStoriesPlayButton"];
            [cell.actionButton setImage:image forState:UIControlStateNormal];
            [cell.actionButton setHidden:NO];
            cell.actionButton.enabled = YES;
            [cell.shareButton setHidden:NO];
            cell.shareButton.enabled = YES;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            
            cell.remakeButton.alpha = 0;
            break;
            
        case HMGRemakeStatusNew:
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            break;
            
        case HMGRemakeStatusRendering:
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            break;
        
        case HMGRemakeStatusTimeout:
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            break;
        
        case HMGRemakeStatusClientRequestedDeletion:
            if (cell.guiActivityOverlay.alpha == 0) {
                [UIView animateWithDuration:0.3 animations:^{
                    cell.guiActivityOverlay.alpha = 1;
                    [cell.guiActivity startAnimating];
                }];
            }
            break;
    }
}

-(void)handleRemakesCount
{
    if ([self.userRemakesCV numberOfItemsInSection:0] == 0) {
        [self.noRemakesLabel setHidden:NO];
        [self.guiRemakeMoreStoriesButton setTitle:LS(@"REMAKE_A_STORY") forState:UIControlStateNormal];
    } else {
        [self.noRemakesLabel setHidden:YES];
        [self.guiRemakeMoreStoriesButton setTitle:LS(@"REMAKE_MORE_STORIES") forState:UIControlStateNormal];
    }
}

#pragma mark video player
-(void)playRemakeVideoWithURL:(NSString *)videoURL inCell:(HMGUserRemakeCVCell *)cell withIndexPath:(NSIndexPath *)indexPath
{
    /*if (self.playingMovieIndex != -1) //another movie is being played in another cell
    {
        HMGUserRemakeCVCell *otherRemakeCell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
        [self closeMovieInCell:otherRemakeCell];
    }*/
    
    self.playingMovieIndex = indexPath.item;
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self initVideoPlayerWithRemake:remake];
}

-(void)initVideoPlayerWithRemake:(Remake *)remake
{
    UIView *view;
    self.guiVideoContainer = view = [[UIView alloc] initWithFrame:CGRectZero];
    self.guiVideoContainer.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:self.guiVideoContainer];
    [self.view bringSubviewToFront:self.guiVideoContainer];
    
    HMSimpleVideoViewController *vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiVideoContainer rotationSensitive:YES];
    vc.videoURL = remake.videoURL;
    vc.entityType = [NSNumber numberWithInteger:HMRemake];
    vc.originatingScreen = [NSNumber numberWithInteger:HMMyStories];
    vc.entityID = remake.sID;
    [vc hideVideoLabel];
    //[self.videoView hideMediaControls];
    vc.delegate = self;
    vc.resetStateWhenVideoEnds = YES;
    [vc play];
    [vc setFullScreen];
}

-(void)configureCellForMoviePlaying:(HMGUserRemakeCVCell *)cell active:(BOOL)active
{
    if (active)
    {
        //[cell.moviePlaceHolder insertSubview:self.moviePlayer.view belowSubview:cell.closeMovieButton];
        [cell.guiThumbImage setHidden:YES];
        [cell.buttonsView setHidden:YES];
    } else
    {
        [cell.guiThumbImage setHidden:NO];
        [cell.buttonsView setHidden:NO];
    }
}


-(void)closeCurrentlyPlayingMovie
{
    HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)[self getCellFromCollectionView:self.userRemakesCV atIndex:self.playingMovieIndex atSection:0];
    [self closeMovieInCell:cell];
}

-(void)closeMovieInCell:(HMGUserRemakeCVCell *)remakeCell
{
    //self.moviePlayer = nil;
    [self configureCellForMoviePlaying:remakeCell active:NO];
    self.playingMovieIndex = -1; //we are good to go and play a movie in another cell
}

-(HMGUserRemakeCVCell *)getParentCollectionViewCellOfButton:(UIButton *)button
{
    //TODO: this is only the current hirarchy in the hmguserCVcell!
    id cell = [button findAncestorViewThatIsMemberOf:[HMGUserRemakeCVCell class]];
    if (![cell isKindOfClass:[HMGUserRemakeCVCell class]])
    {
        HMGLogError(@"button super view is not a collection view cell!");
        return nil;
    }
    return cell;
}


-(void)remakeCreationFailMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                    message:@"Failed creating remake.\n\nTry again in a few moments."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}


#pragma mark recorder init
-(void)initRecorderWithRemake:(Remake *)remake
{
    // Handle status bar hiding
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    app.isInRecorderContext = YES;
    [self setNeedsStatusBarAppearanceUpdate];

    // Open the recorder.
    HMRecorderViewController *recorderVC = [HMRecorderViewController recorderForRemake:remake];
    recorderVC.delegate = self;
    if (recorderVC) [self presentViewController:recorderVC animated:YES completion:nil];
}


#pragma mark UITextView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == REMAKE_ALERT_VIEW_TAG)
    {
        //
        //remake button pushed
        //
        
        if (buttonIndex == 0)
        {
           //cancel
        }
        
        //continue with old remake
        if (buttonIndex == 1) {
            [self initRecorderWithRemake:self.remakeToContinueWith];
            [[Mixpanel sharedInstance] track:@"MEDoRemake" properties:@{@"story" : self.remakeToContinueWith.story.name , @"remake_id" : self.remakeToContinueWith.sID , @"continue_with_old_remake" : @"yes"}];
        }
        //start new remake
        if (buttonIndex == 2) {
            NSString *remakeIDToDelete = self.remakeToContinueWith.sID;
            [[Mixpanel sharedInstance] track:@"MEDoRemake" properties:@{@"story" : self.remakeToContinueWith.story.name , @"remake_id" : self.remakeToContinueWith.sID , @"continue_with_old_remake" : @"no"}];
            [HMServer.sh deleteRemakeWithID:remakeIDToDelete];
            [HMServer.sh createRemakeForStoryWithID:self.remakeToContinueWith.story.sID forUserID:User.current.userID withResolution:@"360"];
            self.remakeToContinueWith = nil;
        }
        //[self.userRemakesCV reloadData];
    
    } else if (alertView.tag == TRASH_ALERT_VIEW_TAG) {
        
        //
        // delete button pushed
        //
        if (buttonIndex == 1) {
            
            // Mark remake for deletion and update cell.
            AWAlertView *av = (AWAlertView *)alertView;
            NSIndexPath *indexPath = av.awContextObject;
            if (!indexPath) return;

            Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
            if (!remake || !remake.sID) return;
            
            // Mark remake as user requested deletion.
            remake.status = @(HMGRemakeStatusClientRequestedDeletion);
            
            // Reload data (reload all data
            // because of a bug in reloadItemsAtIndexPaths in iOS 7.0.X
            [self.userRemakesCV reloadData];
            
            // Mixpanel event about the deletion request.
            if (remake.story.name && remake.story.sID)
            {
                [[Mixpanel sharedInstance] track:@"MEDeleteRemake" properties:@{@"story" : remake.story.name , @"remake_id" : remake.sID}];
            }
            
            // Tell server to delete remake.
            [HMServer.sh deleteRemakeWithID:remake.sID];
            
        }
        
    } else if (alertView.tag == SHARE_ALERT_VIEW_TAG) {
        //
        // 
        //
        
        //dont join
        if (buttonIndex == 0)
        {
            self.remakeToShare = nil;
        }
        //join now!
        if (buttonIndex == 1)
        {
            [self closeAllCellsExceptCell:nil animated:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_USER_JOIN object:nil userInfo:nil];
        }
    }
}

-(UICollectionViewCell *)getCellFromCollectionView:(UICollectionView *)collectionView atIndex:(NSInteger)index atSection:(NSInteger)section
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:section];
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    return cell;
}

#pragma mark - HMRecorderDelegate
-(void)recorderAsksDismissalWithReason:(HMRecorderDismissReason)reason
                              remakeID:(NSString *)remakeID
                                sender:(HMRecorderViewController *)sender {
    
    HMGLogDebug(@"This is the remake ID the recorder used:%@", remakeID);
    
    // Handle reasons
    if (reason == HMRecorderDismissReasonUserAbortedPressingX) {
        //do nothing.
    } else if (reason == HMRecorderDismissReasonFinishedRemake) {
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

#pragma mark HMSimpleVideoViewController delegate
-(void)videoPlayerDidStop
{
    [self.guiVideoContainer removeFromSuperview];
    if (self.playingMovieIndex != -1)
        [self closeCurrentlyPlayingMovie];
}


#pragma mark - Scroll view delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    switch (scrollView.tag) {
        case SCROLL_VIEW_CELL:
            // Remake cells scroll views
            [self handleRemakeCellScrollView:scrollView];
            break;
        
        case SCROLL_VIEW_CV:
            [self handleVisibilityOfMoreStoriesButtonByScrollView:scrollView];
            break;
        
        default:
            return;
    }
}

-(void)handleRemakeCellScrollView:(UIScrollView *)scrollView
{
    CGFloat offsetX = scrollView.contentOffset.x;
    CGFloat part = MAX(offsetX / 160.0f , 0);
    //CGFloat scale = MAX(1.0f - part, 0.3);
    HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)scrollView.superview.superview;
    //cell.guiThumbContainer.transform = CGAffineTransformMakeScale(scale, scale);
    cell.guiThumbContainer.transform = CGAffineTransformMakeTranslation(-offsetX, 0);
    cell.guiThumbContainer.alpha = 1-part;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView.tag == 1) {
        HMGUserRemakeCVCell *draggedCell = (HMGUserRemakeCVCell *)scrollView.superview.superview;
        // close all cells not dragged.
        [self closeAllCellsExceptCell:draggedCell animated:YES];
        self.needsCheckIfAllClosed = YES;
    } else {
        if (self.needsCheckIfAllClosed) [self closeAllCellsExceptCell:nil animated:YES];
    }
}

-(void)closeAllCellsExceptCell:(HMGUserRemakeCVCell *)exceptCell animated:(BOOL)animated
{
    for (HMGUserRemakeCVCell *cell in self.userRemakesCV.visibleCells) {
        if (![cell isEqual:exceptCell]) {
            [cell closeAnimated:animated];
        }
    }
    self.needsCheckIfAllClosed = NO;
}

// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //self.view.backgroundColor = [UIColor clearColor];
}

-(void)displayRect:(NSString *)name BoundsOf:(CGRect)rect
{
    CGSize size = rect.size;
    CGPoint origin = rect.origin;
    NSLog(@"%@ bounds: origin:(%f,%f) size(%f %f)" , name , origin.x , origin.y , size.width , size.height);
}

#pragma mark - Create more remakes buttons
-(void)_remakeMoreStoriesOutOfScreenPosition
{
    CGAffineTransform t = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 80);
    t = CGAffineTransformScale(t, 1.3, 1.3);
    self.guiRemakeMoreStoriesButton.alpha = 0;
    self.guiRemakeMoreStoriesButton.transform = t;
}

-(void)hideRemakeMoreStoriesButton
{
    [self hideRemakeMoreStoriesButtonMovingToStories:NO];
}

-(void)hideRemakeMoreStoriesButtonMovingToStories:(BOOL)movingToStories
{
    [UIView animateWithDuration:0.3 animations:^{
        [self _remakeMoreStoriesOutOfScreenPosition];
    } completion:^(BOOL finished) {
        if (movingToStories) {
            HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
            [app.mainVC showStoriesTab];
        }
    }];
}

-(void)showRemakeMoreStoriesButton
{
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.4 initialSpringVelocity:0.1 options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.guiRemakeMoreStoriesButton.alpha = 1;
                         self.guiRemakeMoreStoriesButton.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

-(void)handleVisibilityOfMoreStoriesButton
{
    [self handleVisibilityOfMoreStoriesButtonByScrollView:nil];
}

-(void)handleVisibilityOfMoreStoriesButtonByScrollView:(UIScrollView *)scrollView
{
    if (scrollView == nil) scrollView = self.userRemakesCV;
    
    // TODO: temporarily hardcoded. make dynamic solution.
    CGFloat yOffset = scrollView.contentSize.height - scrollView.contentOffset.y;
    BOOL shouldBeShown = yOffset < self.bottomButtonAppearanceThresholdThatIsUsedToDetermineWhenToShowOrHideIt;
    if (shouldBeShown && self.guiRemakeMoreStoriesButton.alpha == 0) {
        [self showRemakeMoreStoriesButton];
    } else if (!shouldBeShown && self.guiRemakeMoreStoriesButton.alpha == 1) {
        [self hideRemakeMoreStoriesButton];
    }
}

#pragma mark - Share remake
-(void)shareRemakeRequestForRemake:(Remake *)remake thumb:(UIImage *)thumb
{
    self.currentSharer = [HMSharing new];
    self.currentSharer.image = thumb;
    NSDictionary *shareBundle = [self.currentSharer generateShareBundleForRemake:remake
                                                                  trackEventName:@"MEShareRemake"
                                                               originatingScreen:@(HMMyStories)];
    [self.currentSharer requestShareWithBundle:shareBundle];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onActionButtonPushed:(UIButton *)sender
{
    HMGUserRemakeCVCell *cell = [self getParentCollectionViewCellOfButton:sender];
    if (!cell) return;
    
    NSIndexPath *indexPath = [self.userRemakesCV indexPathForCell:cell];
    //NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HMGLogInfo(@"the user selected remake at index: %d" , indexPath.item);
    //HMGUserRemakeCVCell *cell = (HMGUserRemakeCVCell *)[self.userRemakesCV cellForItemAtIndexPath:indexPath];
    switch (remake.status.integerValue)
    {
        case HMGRemakeStatusDone:
            [[Mixpanel sharedInstance] track:@"MEPlayRemake" properties:@{@"story" : remake.story.name , @"remake_id" : remake.sID}];
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
}

- (IBAction)onDeleteRemakeButtonPushed:(UIButton *)sender
{
    // Get some info
    HMGUserRemakeCVCell *cell = [self getParentCollectionViewCellOfButton:sender];
    NSIndexPath *indexPath = [self.userRemakesCV indexPathForCell:cell];
    
    //
    // Ask user if sure about deleting the remake.
    //
    AWAlertView *alertView = [[AWAlertView alloc] initWithTitle: LS(@"DELETE_REMAKE") message:LS(@"APPROVE_DELETION") delegate:self cancelButtonTitle:LS(@"NO") otherButtonTitles:LS(@"YES"), nil];
    alertView.tag = TRASH_ALERT_VIEW_TAG;
    alertView.awContextObject = indexPath;
    [alertView show];
}

- (IBAction)onRemakeButtonPushed:(UIButton *)button
{
    [self closeCurrentlyPlayingMovie];
    HMGUserRemakeCVCell *cell = [self getParentCollectionViewCellOfButton:button];
    if (!cell) return;
    
    NSIndexPath *indexPath = [self.userRemakesCV indexPathForCell:cell];
    
    [cell disableInteractionForAShortWhile];
    
    self.remakeToContinueWith = [self.fetchedResultsController objectAtIndexPath:indexPath];
    HMGLogDebug(@"gonna remake story: %@" , self.remakeToContinueWith.story.name);
    
    if (!self.remakeToContinueWith.story.isActive.boolValue)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"SORRY") message:LS(@"STORY_NOT_AVAILABLE") delegate:self cancelButtonTitle:LS(@"OK") otherButtonTitles:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
        return;
    }
    
    NSInteger remakeStatus = self.remakeToContinueWith.status.integerValue;
    
    //we only want to suggest to continue a remake if a remake is in user progress or timed out and we want to give him the option to send to rendering again
    if (remakeStatus == HMGRemakeStatusInProgress || remakeStatus == HMGRemakeStatusTimeout)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"CONTINUE_WITH_REMAKE") message:LS(@"CONTINUE_OR_START_FROM_SCRATCH") delegate:self cancelButtonTitle:LS(@"CANCEL") otherButtonTitles:LS(@"OLD_REMAKE"), LS(@"NEW_REMAKE") , nil];
        alertView.tag = REMAKE_ALERT_VIEW_TAG;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
    } else {
        [HMServer.sh createRemakeForStoryWithID:self.remakeToContinueWith.story.sID forUserID:User.current.userID withResolution:@"360"];
    }
}

- (IBAction)onShareButtonPushed:(UIButton *)button
{
    HMGUserRemakeCVCell *cell = [self getParentCollectionViewCellOfButton:button];
    if (!cell) return;
    NSIndexPath *indexPath = [self.userRemakesCV indexPathForCell:cell];
    Remake *remakeToShare = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.lastShareButtonPressed = button;
    
    
    if ([[User current] isGuestUser])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"SIGN_UP_NOW") message:LS(@"ONLY_SIGN_IN_USERS_CAN_SHARE") delegate:self cancelButtonTitle:LS(@"NOT_NOW") otherButtonTitles:LS(@"JOIN_NOW"), nil];
        alertView.tag = SHARE_ALERT_VIEW_TAG;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
        
    } else {
        // Allow sharing one at a time.
        if (self.currentSharer) return;
        
        // Share request for the remake. (Homage server needs to create a share object first)
        [self shareRemakeRequestForRemake:remakeToShare thumb:cell.guiThumbImage.image];
        cell.shareButton.hidden = YES;
        [cell.shareActivity startAnimating];
    }
}

- (IBAction)onRemakeMoreStoriesButtonPushed:(id)sender
{
    [[Mixpanel sharedInstance] track:@"MERemakeMoreStories"];
    [self hideRemakeMoreStoriesButtonMovingToStories:YES];
}


@end
