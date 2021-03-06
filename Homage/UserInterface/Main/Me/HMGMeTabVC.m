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
#import "HMCacheManager.h"
#import "HMServer+AppConfig.h"
#import "HMAppStore.h"
#import "HMInAppStoreViewController.h"
#import "HMDownloadViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <PSTAlertController/PSTAlertController.h>
#import "HMSharingDelegate.h"
#import "HMMELabelSpecific.h"

#define SCROLL_VIEW_CELL 1
#define SCROLL_VIEW_CV 70

@interface HMGMeTabVC () <
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    HMRecorderDelegate,
    HMVideoPlayerDelegate,
    HMSimpleVideoPlayerDelegate,
    UIActionSheetDelegate,
    HMSharingDelegate
>

@property (weak, nonatomic) IBOutlet UIButton *guiRemakeMoreStoriesButton;
@property (weak, nonatomic) IBOutlet UIButton *guiRemakeMoreStoriesButton2;

@property (weak, nonatomic) IBOutlet UICollectionView *userRemakesCV;

@property (nonatomic) UIDocumentInteractionController *documentInteractionController;

@property (weak, nonatomic) HMGUserRemakeCVCell *lastSharedRemakeCell;

@property (weak,nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSInteger playingMovieIndex;
@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) NSString *currentFetchedResultsUser;

@property (weak, nonatomic) HMDownloadViewController *saveVC;
@property (nonatomic) Remake *remakeToContinueWith;
@property (nonatomic) Remake *remakeToSave;

@property (weak, nonatomic) IBOutlet HMRegularFontLabel *noRemakesLabel;
@property (nonatomic,weak) UIView *guiVideoContainer;

@property (nonatomic) HMSharing *currentSharer;

@property (strong, nonatomic) IBOutlet UIPanGestureRecognizer *guiCellPanGestureRecognizer;

@property (nonatomic) BOOL needsCheckIfAllClosed;

// Yes, the name of the variable is long because it is funny. deal with it!
@property (nonatomic) CGFloat bottomButtonAppearanceThresholdThatIsUsedToDetermineWhenToShowOrHideIt;

@property (nonatomic) BOOL userAllowedToSaveRemakeVideosToDevice;

// Extra effects specific to a label
@property (nonatomic) HMMELabelSpecific *labelSpecific;

@end

@implementation HMGMeTabVC

#define REMAKE_ALERT_VIEW_TAG 100
#define TRASH_ALERT_VIEW_TAG  200
#define SHARE_ALERT_VIEW_TAG  300
#define ALERT_VIEW_TAG_SAVE_REMAKE_SHOULD_OPEN_STORE 400

#define ALERT_VIEW_TAG_SHARE_FAILED 1200
#define ALERT_VIEW_TAG_SAVE_TO_CM_FAILED 1300

//#define HOMAGE_APPSTORE_LINK @"https://itunes.apple.com/us/app/homage/id851746600?l=iw&ls=1&mt=8"

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark lifecycle related
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initSettings];
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
    
    if (self.labelSpecific == nil) {
        self.labelSpecific = [HMMELabelSpecific new];
        self.labelSpecific.superView = self.view;
        [self.labelSpecific prepare];
    }
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
-(void)initSettings
{
    // Determine if user is allowed to download and save remakes videos to camera roll.
    HMUserSaveToDevicePolicy policy = [HMServer.sh.configurationInfo[@"user_save_remakes_policy"] integerValue];
    self.userAllowedToSaveRemakeVideosToDevice =    policy == HMUserSaveToDevicePolicyAllowed ||
                                                    policy == HMUserSaveToDevicePolicyPremium;

}

-(void)initGUI
{
    //init refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.userRemakesCV addSubview:refreshControl];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(onPulledToRefetch) forControlEvents:UIControlEventValueChanged];
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
    self.title = LS(@"");
    
    // Checks if need to close "opened" cells.
    self.needsCheckIfAllClosed = NO;
    
    // Goto stories button
    CGFloat t = IS_IPHONE_5 ? 510 : 470;
    self.bottomButtonAppearanceThresholdThatIsUsedToDetermineWhenToShowOrHideIt = t;
    [self _remakeMoreStoriesOutOfScreenPosition];
    
    // ************
    // *  STYLES  *
    // ************
    self.refreshControl.tintColor = [HMStyle.sh colorNamed:C_REFRESH_CONTROL_TINT];
    self.guiRemakeMoreStoriesButton.backgroundColor = [HMStyle.sh colorNamed:C_ME_REMAKE_BUTTON_BG];
    [self.guiRemakeMoreStoriesButton setTitleColor:[HMStyle.sh colorNamed:C_ME_REMAKE_BUTTON_TEXT] forState:UIControlStateNormal];
    [self.guiRemakeMoreStoriesButton2 setTitleColor:[HMStyle.sh colorNamed:C_ME_REMAKE_BUTTON_TEXT] forState:UIControlStateNormal];
    [self.noRemakesLabel setTextColor:[HMStyle.sh colorNamed:C_ME_CREATE_FIRST_VIDEO_TEXT]];
    
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

    // Observe share request
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserWantToSaveRemakeVideo:)
                                                       name:HM_NOTIFICATION_UI_USER_WANTS_TO_SAVE_REMAKE
                                                     object:nil];
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SHARE_REMAKE_REQUEST object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_UI_USER_WANTS_TO_SAVE_REMAKE object:nil];
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
    UIButton *button = self.lastSharedRemakeCell.shareButton;
    NSDictionary *shareBundle = notification.userInfo[@"share_bundle"];
    
    if (shareBundle[K_REMAKE_LOCAL_VIDEO_URL]) {
        [self.currentSharer shareVideoFileInRemakeBundle:shareBundle
                                                parentVC:self
                                          trackEventName:@"MEShareRemake"
                                              sourceView:button];
    } else {
        // User sharing link.
        [self.currentSharer shareRemakeBundle:shareBundle
                                     parentVC:self
                               trackEventName:@"MEShareRemake"
                                    thumbnail:self.currentSharer.image
                                   sourceView:button];
    }

    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self stopShareActivity];
    });
}

-(void)onUserWantToSaveRemakeVideo:(NSNotification *)notification
{
    NSString *remakeID = notification.userInfo[@"remake_id"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    if (!remake) return;
    
    // Make sure remake is in the right status.
    if (remake.status.integerValue != HMGRemakeStatusDone) {
        return;
    }
    
    // Start the flow of saving/downloading clip.
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.saveVC = [HMDownloadViewController downloadVCInParentVC:app.mainVC];
    self.saveVC.delegate = self;
    self.saveVC.info = @{
                         @"remake":remake
                         };
    [self.saveVC startSavingToCameraRoll];
    self.remakeToSave = remake;
    [self downloadUserRemake:remake];
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
            if (self.userRemakesCV.contentOffset.y == 0)
                [self.userRemakesCV scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
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

    //
    // Check if needs to download and cache resources
    //
    dispatch_async(dispatch_get_main_queue(), ^{
        [HMCacheManager.sh checkIfNeedsToDownloadAndCacheResources];
    });
    
//    // Clear temp files for remakes in "DONE" status
//    for (Remake *remake in self.fetchedResultsController.fetchedObjects) {
//        if (remake.status && remake.status.integerValue == HMGRemakeStatusDone) {
//            [remake deleteRawLocalFiles];
//        }
//    }
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
    // Get the remake.
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // Thumb image
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
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
    
    // Allow scrolling of the cell (for more options/buttons)
    if (cell.guiScrollView.delegate == nil) cell.guiScrollView.delegate = self;
    [cell closeAnimated:NO];
    
    
    // The name of the story.
    cell.storyNameLabel.text = remake.story.name;
    
    // Update the cell according to the status of the remake.
    [self updateUIOfRemakeCell:cell withStatus: remake.status];
    
    // Handle showing/hiding the save remake to device, depending on the setting of this label/app.
    [self updateOptionToDownloadVideoInCell:cell];
    
    // ************
    // *  STYLES  *
    // ************
    [cell.shareActivity setColor:[HMStyle.sh colorNamed:C_ACTIVITY_CONTROL_TINT]];
    [cell.guiActivity setColor:[HMStyle.sh colorNamed:C_ACTIVITY_CONTROL_TINT]];
    
    cell.storyNameLabel.textColor = [HMStyle.sh colorNamed:C_ME_TEXT];
    cell.guiRetakeLabel.textColor = [HMStyle.sh colorNamed:C_ME_TEXT];
    cell.guiDeleteLabel.textColor = [HMStyle.sh colorNamed:C_ME_TEXT];
    
    cell.guiSepTop.backgroundColor = [HMStyle.sh colorNamed:C_ME_CELL_TOP_BORDER];
    cell.guiSepBottom.backgroundColor = [HMStyle.sh colorNamed:C_ME_CELL_BOTTOM_BORDER];
}

-(void)updateOptionToDownloadVideoInCell:(HMGUserRemakeCVCell *)cell
{
    if (!self.userAllowedToSaveRemakeVideosToDevice) {
        cell.guiDownloadButton.hidden = YES;
        return;
    }

    // If already initialized the layout, nothing to do here.
    if (cell.layoutInitialized) return;

    // Initialize the layout for showing the share button
    // and download button side by side.
    CGRect f = cell.shareButton.frame;
    f.size.width = f.size.width / 2.0;
    cell.shareButton.frame = f;
    f.origin.x += f.size.width;
    cell.guiDownloadButton.frame = f;
    
    // Mark it so it will not be initialized again.
    cell.layoutInitialized = YES;
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
            cell.guiDownloadButton.hidden = YES;
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
            cell.guiDownloadButton.hidden = NO;
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
            cell.guiDownloadButton.hidden = YES;
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            break;
            
        case HMGRemakeStatusRendering:
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.guiDownloadButton.hidden = YES;
            cell.shareButton.enabled = NO;
            cell.remakeButton.enabled = YES;
            cell.guiActivityOverlay.alpha = 0;
            [cell.guiActivity stopAnimating];
            break;
        
        case HMGRemakeStatusTimeout:
            cell.actionButton.enabled = NO;
            [cell.actionButton setHidden:YES];
            [cell.shareButton setHidden:YES];
            cell.guiDownloadButton.hidden = YES;
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
        [self.guiRemakeMoreStoriesButton2 setTitle:LS(@"REMAKE_A_STORY") forState:UIControlStateNormal];
    } else {
        [self.noRemakesLabel setHidden:YES];
        [self.guiRemakeMoreStoriesButton setTitle:LS(@"REMAKE_MORE_STORIES") forState:UIControlStateNormal];
        [self.guiRemakeMoreStoriesButton2 setTitle:LS(@"REMAKE_A_STORY") forState:UIControlStateNormal];
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
    if (active) {
        [cell.guiThumbImage setHidden:YES];
        [cell.buttonsView setHidden:YES];
    } else {
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

#pragma mark - AlertView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == REMAKE_ALERT_VIEW_TAG)
    {
        //
        // remake button pushed
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
        //join now!
        if (buttonIndex == 1)
        {
            [self closeAllCellsExceptCell:nil animated:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_USER_JOIN object:nil userInfo:nil];
        }
    } else if (alertView.tag == ALERT_VIEW_TAG_SAVE_REMAKE_SHOULD_OPEN_STORE) {
        if (buttonIndex == 1) {
            // 
            HMInAppStoreViewController *vc = [HMInAppStoreViewController storeVCForRemake:self.remakeToSave];
            vc.delegate = self;
            vc.openedFor = HMStoreOpenedForSaveRemakeToCameraRoll;
            [self presentViewController:vc animated:YES completion:nil];
        } else {
            // Canceled entering the store from buying a save token.
            [self.saveVC cancel];
            [self finishedDownloadFlowForRemake:self.remakeToSave];
        }
    } else if (alertView.tag == ALERT_VIEW_TAG_SAVE_TO_CM_FAILED) {
        if (buttonIndex == 1) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
}

#pragma mark - UITextView delegate
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
-(void)startAnimatingActivityInCell:(HMGUserRemakeCVCell *)cell forButton:(UIButton *)button
{
    // Will start animating the activity
    // But will also position it horizontally to match
    // the related button position.
    CGPoint p = cell.shareActivity.center;
    p.x = button.center.x;
    cell.shareActivity.center = p;
    [cell.shareActivity startAnimating];
    button.hidden = YES;
}

-(void)shareRemakeRequestForRemake:(Remake *)remake thumb:(UIImage *)thumb
{
    self.currentSharer = [HMSharing new];
    self.currentSharer.delegate = self;
    self.currentSharer.image = thumb;
    NSDictionary *shareBundle = [self.currentSharer generateShareBundleForRemake:remake
                                                                  trackEventName:@"MEShareRemake"
                                                               originatingScreen:@(HMMyStories)];
    [self.currentSharer requestShareWithBundle:shareBundle];
}

-(void)shareRemakeVideoFileRequestForRemake:(Remake *)remake
{
    self.currentSharer = [HMSharing new];
    self.currentSharer.delegate = self;
    self.currentSharer.shareAsFile = YES;
    NSDictionary *shareBundle = [self.currentSharer generateShareBundleForRemake:remake
                                                                  trackEventName:@"MEShareRemake"
                                                               originatingScreen:@(HMMyStories)];
    [self.currentSharer requestShareWithBundle:shareBundle];
}

-(void)userWantsToShareRemake:(Remake *)remakeToShare
{
    // If allowed to share videos as attachment in this story,
    // will ask the user what she want to share (a link or the actual video file).
    Story *story = remakeToShare.story;

    // Share options.
    PSTAlertController *ac = [PSTAlertController alertControllerWithTitle:remakeToShare.story.name
                                                                  message:LS(@"SHARE_OPTIONS_MESSAGE")
                                                           preferredStyle:PSTAlertControllerStyleActionSheet];

    // Option 1 - Save to camera roll.
    if (self.userAllowedToSaveRemakeVideosToDevice) {
        [ac addAction:[PSTAlertAction actionWithTitle:LS(@"SHARE_ITEM_OPTION_SAVE_TO_CR") handler:^(PSTAlertAction *action) {
            [self userWantsToSaveRemakeToCameraRoll:remakeToShare];
        }]];
    }

    // Option 2 - Share as a link.
    [ac addAction:[PSTAlertAction actionWithTitle:LS(@"SHARE_ITEM_OPTION_LINK") handler:^(PSTAlertAction *action) {
        [self userWantsToShareRemakeAsLink:remakeToShare];
    }]];
    
    // Option 3 - Share as a video file.
    if (story.sharingVideoAllowed.boolValue) {
        [ac addAction:[PSTAlertAction actionWithTitle:LS(@"SHARE_ITEM_OPTION_FILE") handler:^(PSTAlertAction *action) {
            [self userWantsToShareRemakeAsVideoFile:remakeToShare];
        }]];
    }
    
    // If more than one option, will let the user choose.
    // Otherwise, will just share a link.
    if (ac.actions.count > 1) {
        [ac addCancelActionWithHandler:nil];
        [ac showWithSender:nil controller:self animated:YES completion:nil];
        return;
    }
    
    // Allowed to only share links to the remake.
    // No need to let the user choose an option.
    [self userWantsToShareRemakeAsLink:remakeToShare];
}

-(void)userWantsToShareRemakeAsLink:(Remake *)remakeToShare
{
    HMGUserRemakeCVCell *cell = self.lastSharedRemakeCell;
    UIButton *button = cell.shareButton;
    
    // Share request for the remake.
    // (Homage server needs to create a share object first)
    [self shareRemakeRequestForRemake:remakeToShare thumb:cell.guiThumbImage.image];
    [self startAnimatingActivityInCell:cell forButton:button];
}

-(void)userWantsToShareRemakeAsVideoFile:(Remake *)remakeToShare
{
    HMGUserRemakeCVCell *cell = self.lastSharedRemakeCell;
    UIButton *button = cell.shareButton;

    // User wants to share remake as video file.
    // But the file must be available on local storage first.
    if (remakeToShare.isVideoAvailableLocally) {
        // The video is available in local storage.
        // Share the video file.
        [self shareRemakeVideoFileRequestForRemake:remakeToShare];
        [self startAnimatingActivityInCell:cell forButton:button];
        return;
    }
    
    // The video is not available locally yet.
    // Will need to download the video before being able to share the file.
    // Start the flow of downloading remake and sharing it as a file
    // when downloaded successfuly.
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.saveVC = [HMDownloadViewController downloadVCInParentVC:app.mainVC];
    self.saveVC.delegate = self;
    self.saveVC.info = @{
                         @"remake":remakeToShare
                         };
    NSURL *remakeVideoURL = [NSURL URLWithString:[remakeToShare.videoURL stringByReplacingOccurrencesOfString:@"%20" withString:@"+"]];
    self.saveVC.downloadFlow = HMDownloadFlowShare;
    [self.saveVC startDownloadResourceFromURL:remakeVideoURL
                                toLocalFolder:HMCacheManager.sh.remakesCachePath];
}

-(void)userWantsToSaveRemakeToCameraRoll:(Remake *)remakeToSave
{
    // Start the flow of saving/downloading clip.
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.saveVC = [HMDownloadViewController downloadVCInParentVC:app.mainVC];
    self.saveVC.delegate = self;
    self.saveVC.info = @{
                         @"remake":remakeToSave
                         };
    [self.saveVC startSavingToCameraRoll];
    self.remakeToSave = remakeToSave;
    [self downloadUserRemake:remakeToSave];
}

#pragma mark - HMSharingDelegate
-(void)sharingDidFinishWithShareBundle:(NSDictionary *)shareBundle
{
    self.currentSharer.delegate = nil;
    self.currentSharer = nil;
    [self refreshFromLocalStorage];
    [self.userRemakesCV reloadData];
}

#pragma mark - Download remake flow
-(void)startDownloadFlowForRemake:(Remake *)remake
{
    if ([remake isVideoAvailableLocally]) {
        // The video is already available locally.
        // We just need to save it to the camera roll.
        NSURL *localVideoURL = [HMCacheManager.sh urlForCachedResource:remake.videoURL
                                                             cachePath:HMCacheManager.sh.remakesCachePath];
        UISaveVideoAtPathToSavedPhotosAlbum(localVideoURL.path,
                                            self,
                                            @selector(video:didFinishSavingWithError:contextInfo:),
                                            NULL);
        [self.saveVC startSavingToCameraRoll];
        return;
    }
    
    // Video is not available locally.
    // Will need to download video.
    NSURL *remakeVideoURL = [NSURL URLWithString:[remake.videoURL stringByReplacingOccurrencesOfString:@"%20" withString:@"+"]];
    [self.saveVC startDownloadResourceFromURL:remakeVideoURL toLocalFolder:HMCacheManager.sh.remakesCachePath];
}

-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    // Finish the flow
    [self finishedDownloadFlowForRemake:self.remakeToSave];
    
    // If error, show the failed download message.
    // on error, will not use the user's save token
    // so she may try to download the remake again.
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"DOWNLOAD_FAILED_TO_SAVE_TO_CR_TITLE")
                                                        message:LS(@"DOWNLOAD_FAILED_TO_SAVE_TO_CR_MESSAGE")
                                                       delegate:self
                                              cancelButtonTitle:LS(@"OK")
                                              otherButtonTitles:LS(@"SETTINGS"), nil];
        alert.tag = ALERT_VIEW_TAG_SAVE_TO_CM_FAILED;
        [alert show];
        return;
    }
    
    // No error. All is well.
    // Remake video saved successfully to camera roll.
    // User spent a save token (irrelevant if user purchased full bundle)
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"DOWNLOAD_REMAKES_SAVED_TITLE")
                                                    message:LS(@"DOWNLOAD_REMAKES_SAVED_MESSAGE")
                                                   delegate:nil
                                          cancelButtonTitle:LS(@"OK")
                                          otherButtonTitles:nil];
    [alert show];
    [HMAppStore userUsedOneSaveRemakeToken];
}

-(void)finishedDownloadFlowForRemake:(Remake *)remake
{
    self.remakeToSave = nil;
    [self.userRemakesCV reloadData];
    [self.saveVC dismiss];
    self.saveVC = nil;
}

-(void)downloadUserRemake:(Remake *)remake
{
    HMUserSaveToDevicePolicy savePolicy = [HMServer.sh.configurationInfo[@"user_save_remakes_policy"] integerValue];
    if (savePolicy == HMUserSaveToDevicePolicyNotAllowed) {
        [self finishedDownloadFlowForRemake:remake];
        return;
    }
    
    // If app allows users to download and save
    // videos to camera roll freely,
    // start the download flow.
    if (savePolicy == HMUserSaveToDevicePolicyAllowed) {
        [self startDownloadFlowForRemake:remake];
        return;
    }
    
    // Premium downloads.
    // Allow user to download a remake,
    // if app configured to allow premium downloads
    // and user already made a purchase that allows her
    // to do so.
    if ([HMAppStore maySaveAnotherRemakeToDevice]) {
        [self startDownloadFlowForRemake:remake];
        return;
    }
    
    // User isn't allowed to make a premium download yet.
    // Open the in app store.
    // Show us the monkey!
    [self buyBeforeDownloadMessage];
}

-(void)downloadFailedMessage
{
    //
    // Show a message to the user about the failed download.
    //
    HMUserSaveToDevicePolicy policy = [HMServer.sh.configurationInfo[@"user_save_remakes_policy"] integerValue];
    NSString *failedMessage;
    if (policy == HMUserSaveToDevicePolicyPremium) {
        failedMessage = LS(@"DOWNLOAD_FAILED_PREMIUM_MESSAGE");
    } else {
        failedMessage = LS(@"DOWNLOAD_FAILED_MESSAGE");
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"DOWNLOAD_FAILED_TITLE")
                                                    message:failedMessage
                                                   delegate:nil
                                          cancelButtonTitle:LS(@"OK")
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)notAllowedToDownloadPremiumRemakeVideosMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"DOWNLOAD_NOT_ALLOWED_TITLE")
                                                    message:LS(@"DOWNLOAD_NOT_ALLOWED_PREMIUM_MESSAGE")
                                                   delegate:nil
                                          cancelButtonTitle:LS(@"OK")
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)buyBeforeDownloadMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"DOWNLOAD_SAVE_PREMIUM_TITLE")
                                                    message:LS(@"DOWNLOAD_SAVE_PREMIUM_MESSAGE")
                                                   delegate:self
                                          cancelButtonTitle:LS(@"DOWNLOAD_CANCEL")
                                          otherButtonTitles:LS(@"DOWNLOAD_STORE"), nil];
    alert.tag = ALERT_VIEW_TAG_SAVE_REMAKE_SHOULD_OPEN_STORE;
    alert.delegate = self;
    [alert show];
}

#pragma mark - HMDownloadDelegate
-(void)downloadFinishedWithError:(NSError *)error info:(NSDictionary *)info
{
    // Download failed.
    // Notify user and make sure she understands
    // she can download the video layer, without paying for it again.
    Remake *remake = info[@"remake"];
    [self finishedDownloadFlowForRemake:remake];
    
    if (error.code != NSURLErrorCancelled) {
        [self downloadFailedMessage];
    }
}

-(void)downloadFinishedSuccessfullyWithInfo:(NSDictionary *)info
{
    // Download was successful. Try to copy the file to camera roll.
    NSString *localPath = info[@"file_path"];
    
    if (self.saveVC.downloadFlow == HMDownloadFlowSaveToCameraRoll) {
        [self.saveVC startSavingToCameraRoll];
        UISaveVideoAtPathToSavedPhotosAlbum(localPath,
                                            self,
                                            @selector(video:didFinishSavingWithError:contextInfo:),
                                            NULL);
    } else if (self.saveVC.downloadFlow == HMDownloadFlowShare) {
        // Dismiss the download UI.
        [self.saveVC dismiss];
        self.saveVC = nil;
        
        // Share request for the remake. (Homage server needs to create a share object first)
        // In this flow we are sharing a video file available locally (and not a link)
        Remake *remakeToShare = info[@"remake"];
        [self shareRemakeVideoFileRequestForRemake:remakeToShare];
    }
}

#pragma mark - HMStoreDelegate
-(void)storeDidFinishWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.remakeToSave == nil) return;

        // Finished with the in app store.
        
        // If still not allowed to download and save remake video
        // Will show the "not allowed" message and finish the download flow.
        if (![HMAppStore maySaveAnotherRemakeToDevice]) {
            [self notAllowedToDownloadPremiumRemakeVideosMessage];
            [self finishedDownloadFlowForRemake:self.remakeToSave];
            return;
        }
        
        // User is allowed to download to device.
        [self startDownloadFlowForRemake:self.remakeToSave];
    }];
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

    NSString *storyName = remake.story.name ? remake.story.name : @"unknown";
    NSString *remakeID = remake.sID ? remake.sID : @"unknown";

    switch (remake.status.integerValue)
    {
        case HMGRemakeStatusDone:
            [[Mixpanel sharedInstance] track:@"MEPlayRemake" properties:@{@"story":storyName , @"remake_id" : remakeID}];
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
    self.lastSharedRemakeCell = cell;
    
    //
    // Special handling for guest users (but only if guest users not allowed to share).
    //
    BOOL guestUsersAllowedToShare = [HMServer.sh.configurationInfo[@"guest_allow_share"] boolValue];
    if (User.current.isGuestUser && !guestUsersAllowedToShare)
    {
        // Share not allowed for guest users in this app configuration.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"SIGN_UP_NOW") message:LS(@"ONLY_SIGN_IN_USERS_CAN_SHARE") delegate:self cancelButtonTitle:LS(@"NOT_NOW") otherButtonTitles:LS(@"JOIN_NOW"), nil];
        alertView.tag = SHARE_ALERT_VIEW_TAG;
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertView show];
        });
        return;
    }
    
    // Start the sharing flow.
    [self userWantsToShareRemake:remakeToShare];
}

- (IBAction)onRemakeMoreStoriesButtonPushed:(id)sender
{
    [[Mixpanel sharedInstance] track:@"MERemakeMoreStories"];
    [self hideRemakeMoreStoriesButtonMovingToStories:YES];
}

- (IBAction)onDownloadButtonPushed:(UIButton *)button
{
    // Allow only one download at a time.
    if (self.remakeToSave) return;
    
    HMGUserRemakeCVCell *cell = [self getParentCollectionViewCellOfButton:button];
    if (!cell) return;

    // Get the remake object.
    NSIndexPath *indexPath = [self.userRemakesCV indexPathForCell:cell];
    Remake *remakeToSave = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Make sure remake is in the right status.
    if (remakeToSave.status.integerValue != HMGRemakeStatusDone) {
        return;
    }
    
    // And start the save flow.
    [self userWantsToSaveRemakeToCameraRoll:remakeToSave];
}

@end
