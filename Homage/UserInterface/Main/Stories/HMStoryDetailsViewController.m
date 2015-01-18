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
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMRecorderViewController.h"
#import "HMRemakeCell.h"
#import "HMGLog.h"
#import "HMStyle.h"
#import "Mixpanel.h"
#import "HMSimpleVideoPlayerDelegate.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMServer+analytics.h"
#import "HMAppDelegate.h"
#import "HMRegularFontLabel.h"
#import "HMRemakeScreenViewController.h"
#import "AMBlurView.h"
#import "DB.h"
#import "HMInAppStoreViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HMServer+AppConfig.h"
#import "HMAppStore.h"
#import <MONActivityIndicatorView/MONActivityIndicatorView.h>

@interface HMStoryDetailsViewController () <UICollectionViewDataSource,UICollectionViewDelegate,HMRecorderDelegate,UIScrollViewDelegate,HMSimpleVideoPlayerDelegate,UIActionSheetDelegate>

// Remakes collection view
@property (weak, nonatomic) IBOutlet UICollectionView *remakesCV;

// Story description label
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiStoryDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *guiStoryDescriptionBluryBG;
@property (weak, nonatomic) IBOutlet UIView *guiStoryDescriptionBG;

// More remakes headline
@property (weak, nonatomic) IBOutlet UIView *guiMoreRemakesHeadlineContainer;
@property (weak, nonatomic) IBOutlet UIView *guiMoreRemakesHeadlineBG;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiMoreRemakesHeadlineLabel;

@property (nonatomic) BOOL fetchingMoreRemakes;

@property (weak, nonatomic) MONActivityIndicatorView *activityView;

// Remake button
@property (weak,nonatomic)  IBOutlet UIView *guiRemakeVideoContainer;

// Video player
@property (strong,nonatomic) HMSimpleVideoViewController *storyMoviePlayer;
@property (strong,nonatomic) HMSimpleVideoViewController *remakeMoviePlayer;
@property (nonatomic) NSInteger playingRemakeIndex;
@property (nonatomic) BOOL shouldShowStoryMiniPlayer;
@property (nonatomic) BOOL isShowingStoryMiniPlayer;
@property (weak, nonatomic) IBOutlet UIButton *guiBackToTopButton;

// Remake screen overlay
@property (weak, nonatomic) IBOutlet UIView *guiRemakeScreenContainer;
@property (weak, nonatomic) HMRemakeScreenViewController *remakeScreenVC;
@property (nonatomic) BOOL ignoreRemakeSelections;
@property (nonatomic) UIColor *remakesInfoTextColor;

// Data
@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak,nonatomic) Remake *oldRemakeInProgress;
@property (nonatomic) Remake *flaggedRemake;

// Paging
@property (nonatomic) NSInteger shownRemakesPages;
@property (nonatomic) NSInteger previousRemakesCount;

// Fetched from server
@property (nonatomic) BOOL fetchedFirstPageFromServer;

// Offset point
@property (nonatomic) CGFloat offsetPoint;

@end

@implementation HMStoryDetailsViewController

@synthesize debugForcedVideoURL = _debugForcedVideoURL;

#define REMAKE_ALERT_TAG 100
#define MARK_AS_INAPPROPRIATE_TAG 200
#define HM_EXCLUDE_GRADE -1

#define MORE_REMAKES_OFFSET_POINT 180.0f
#define MORE_REMAKES_OFFSET_POINT_IPAD 360.0f;

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize story = _story;
@synthesize autoStartPlayingStory = _autoStartPlayingStory;


#pragma mark lifecycle related
-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
    [self initContent];
    [self refetchRemakesForStoryID:self.story.sID page:@(self.shownRemakesPages)];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
    [super viewDidAppear:animated];
    self.guiRemakeButton.enabled = YES;
    [self fixLayout];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.guiRemakeActivity.hidden = YES;
    [self.guiRemakeActivity stopAnimating];
    [self.storyMoviePlayer done];
    [self removeObservers];
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void)fixLayout
{
    if (IS_IPAD) {
        
    }
}

#pragma mark initializations

-(void)initGUI
{
    self.title = self.story.name;
    
    self.fetchedFirstPageFromServer = NO;
    self.noRemakesLabel.text = @"";
    self.guiStoryDescriptionLabel.text = self.story.descriptionText;
    [self initStoryMoviePlayer];
    
    // Story description.
    self.guiStoryMovieContainer.layer.zPosition = -1;
    [[AMBlurView new] insertIntoView:self.guiStoryDescriptionBluryBG];
    
    // More remakes headline
    [[AMBlurView new] insertIntoView:self.guiMoreRemakesHeadlineBG];
    self.guiMoreRemakesHeadlineBG.alpha = 0.3;
    
    // Premium content
    [self updateMakeYourOwnButton];
    
    // offset point
    if (IS_IPAD) {
        self.offsetPoint = MORE_REMAKES_OFFSET_POINT_IPAD;
    } else {
        self.offsetPoint = MORE_REMAKES_OFFSET_POINT;
    }
    
    // ************
    // *  STYLES  *
    // ************
    
    // Story description
    self.guiStoryDescriptionLabel.textColor = [HMStyle.sh colorNamed:C_SD_DESCRIPTION_TEXT];
    self.guiStoryDescriptionBG.backgroundColor = [HMStyle.sh colorNamed:C_SD_DESCRIPTION_BG];
    
    // More remakes label
    self.guiMoreRemakesHeadlineContainer.backgroundColor = [HMStyle.sh colorNamed:C_SD_MORE_REMAKES_TITLE_BG];
    self.guiMoreRemakesHeadlineLabel.textColor = [HMStyle.sh colorNamed:C_SD_MORE_REMAKES_TITLE_TEXT];
    
    // Make your own button
    self.guiRemakeButton.backgroundColor = [HMStyle.sh colorNamed:C_SD_REMAKE_BUTTON_BG];
    [self.guiRemakeButton setTitleColor:[HMStyle.sh colorNamed:C_SD_REMAKE_BUTTON_TEXT] forState:UIControlStateNormal];
    [self.guiRemakeActivity setColor:[HMStyle.sh colorNamed:C_ACTIVITY_CONTROL_TINT]];
    
    // No remakes
    self.noRemakesLabel.textColor = [HMStyle.sh colorNamed:C_SD_NO_REMAKES_LABEL];
    
    // Information text on remakes
    self.remakesInfoTextColor = [HMStyle.sh colorNamed:C_SD_REMAKE_INFO_TEXT];

}

-(void)loadAnotherRemakesPage
{
    if (self.fetchingMoreRemakes)
        return;

    self.fetchingMoreRemakes = YES;
    [self.activityView startAnimating];
    self.shownRemakesPages++;
    [self refetchRemakesForStoryID:self.story.sID page:@(self.shownRemakesPages)];
}

-(void)initStoryMoviePlayer
{
    self.shouldShowStoryMiniPlayer = YES;
    
    HMSimpleVideoViewController *vc;
    self.storyMoviePlayer = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiStoryMovieContainer rotationSensitive:YES];
    
    if (self.debugForcedVideoURL) {
        // Used for debugging
        self.storyMoviePlayer.videoURL = self.debugForcedVideoURL;
    } else {
        // The url to the video of the story
        self.storyMoviePlayer.videoURL = self.story.videoURL;
    }
    
    [self.storyMoviePlayer hideVideoLabel];
    [self.storyMoviePlayer hideMediaControls];
    
    // Lazy load image.
    NSURL *thumbURL =[NSURL URLWithString:self.story.thumbnailURL];
    [self.storyMoviePlayer setThumbURL:thumbURL];
    
    self.storyMoviePlayer.delegate = self;
    self.storyMoviePlayer.originatingScreen = [NSNumber numberWithInteger:HMStoryDetails];
    self.storyMoviePlayer.entityType = [NSNumber numberWithInteger:HMStory];
    self.storyMoviePlayer.entityID = self.story.sID;
    self.storyMoviePlayer.resetStateWhenVideoEnds = YES;
}

-(void)initContent
{
    self.previousRemakesCount = -1;
    self.shownRemakesPages = 1;
    self.noRemakesLabel.alpha = 0;
    self.remakesCV.alpha = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self refreshFromLocalStorage];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.remakesCV.alpha = 1;
        }];
    });
}

#pragma mark - Segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"remake embedded screen segue"]) {
        HMRemakeScreenViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        self.remakeScreenVC = vc;
    }
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
}

-(void)removeObservers
{
    
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKES_FOR_STORY object:nil];
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

-(void)onShareRemakeRequest:(NSNotification *)notification
{
    
}

-(void)onRemakesRefetched:(NSNotification *)notification
{
    self.fetchedFirstPageFromServer = YES;
    self.fetchingMoreRemakes = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.activityView stopAnimating];        
    });
    
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


#pragma mark - Alerts
-(void)remakeCreationFailMessage
{
    self.guiRemakeButton.enabled = YES;
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
-(void)refetchRemakesForStoryID:(NSString *)storyID page:(NSNumber *)page
{
    if (!page) page = @1;
    
    // when we will get the new refetch from the server, we will have all the still public remakes in hand.
    // the remake parser will put this flag up again, and this way we'll know the remakes we should delete from the DB
    //[self markCurrentRemakesAsNonPublic];

    [HMServer.sh refetchRemakesWithStoryID:storyID
                        likesInfoForUserID:User.current.userID
                                      page:page.integerValue];
}

-(void)markCurrentRemakesAsNonPublic
{
    return;
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
    self.fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:&error];
    if (error) {
        HMGLogError(@"Critical local storage error, when fetching remakes. %@", error);
        return;
    }
    
    // How many new remakes loaded?
    // If nothing new loaded, scroll the activity cell out of the view.
    NSInteger currentCount = self.fetchedResultsController.fetchedObjects.count;
    NSInteger delta = currentCount - self.previousRemakesCount;
    self.previousRemakesCount = currentCount;
    if (delta == 0 && currentCount > 14 && self.previousRemakesCount>-1) {
        [self scrollActivityOutOfView];
    }
        
    // Reload data
    [self.remakesCV reloadData];
    [self handleNoRemakes];
    
}

-(void)scrollActivityOutOfView
{
    CGFloat y = self.remakesCV.contentOffset.y + self.remakesCV.contentInset.top;
    if (y<=0) return;
    y = y - 45;
    CGRect rect = CGRectMake(0, y, 1, 1);
    [self.remakesCV scrollRectToVisible:rect animated:YES];
}

-(void)cleanPrivateRemakes
{
    for (Remake *remake in self.fetchedResultsController.fetchedObjects)
    {
        if (!remake.stillPublic.boolValue) [DB.sh.context deleteObject:remake];
    }
}

#pragma mark - Make your own button
-(void)updateMakeYourOwnButton
{
    if (self.story.isPremiumAndLocked && [HMServer.sh supportsInAppPurchases]) {
        [self.guiRemakeButton setImage:[UIImage imageNamed:@"storyLockedIconSmall"] forState:UIControlStateNormal];
    } else {
        [self.guiRemakeButton setImage:[UIImage imageNamed:@"remakeInverseBGButton"] forState:UIControlStateNormal];
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
    NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"status=%@" , @(HMGRemakeStatusDone)];
    NSPredicate *compoundPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[storyPredicate, notSameUser, hidePredicate, statusPredicate]];
    
    fetchRequest.predicate = compoundPredicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"grade" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"sID" ascending:NO]];
    fetchRequest.fetchBatchSize = 20;
    fetchRequest.fetchLimit = self.shownRemakesPages * NUMBER_OF_REMAKES_PER_PAGE;
    
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
    if (self.fetchedResultsController.fetchedObjects.count >= NUMBER_OF_REMAKES_PER_PAGE ) {
        return self.fetchedResultsController.fetchedObjects.count+1;
    } else {
        return self.fetchedResultsController.fetchedObjects.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.item;
    
    if (index == self.fetchedResultsController.fetchedObjects.count) {
        // Load more cell
        HMRemakeCell *cell = [self.remakesCV dequeueReusableCellWithReuseIdentifier:@"MoreRemakesCell"
                                                                       forIndexPath:indexPath];
        [self updateLoadMoreRemakesCell:cell];
        return cell;
    }
    
    // Remake cell.
    HMRemakeCell *cell = [self.remakesCV dequeueReusableCellWithReuseIdentifier:@"RemakeCell"
                                                                   forIndexPath:indexPath];
    [self updateCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)updateLoadMoreRemakesCell:(HMRemakeCell *)cell
{
    if (cell.guiContainer.subviews.count > 0) return;

    // The activity view.
    MONActivityIndicatorView *activityView = [[MONActivityIndicatorView alloc] init];
    activityView.numberOfCircles = 3;
    activityView.radius = 8;
    activityView.internalSpacing = 5;
    activityView.duration = 0.2;
    activityView.delegate = self;
    self.activityView = activityView;
    [cell.guiContainer addSubview:activityView];
    activityView.frame = cell.guiContainer.bounds;
    activityView.center = CGPointMake(180, 24);
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = indexPath.item;
    if (index == self.fetchedResultsController.fetchedObjects.count) {
        return CGSizeMake(320, 45);
    } else {
        return CGSizeMake(156, 90);
    }
}

- (void)updateCell:(HMRemakeCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Thumbnail
    cell.guiThumbImage.transform = CGAffineTransformIdentity;
    cell.guiThumbImage.alpha = 0;
    
    // Lazy load image.
    NSURL *thumbURL =[NSURL URLWithString:remake.thumbnailURL];
    [cell.guiThumbImage sd_setImageWithURL:thumbURL placeholderImage:nil options:SDWebImageRetryFailed|SDWebImageLowPriority|SDWebImageDownloaderLIFOExecutionOrder completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (cacheType == SDImageCacheTypeNone) {
            // Reveal with animation
            cell.guiThumbImage.transform = CGAffineTransformMakeScale(0.8, 0.8);
            [UIView animateWithDuration:0.2 animations:^{
                cell.guiThumbImage.alpha = 1;
                cell.guiThumbImage.transform = CGAffineTransformIdentity;
            }];
        } else {
            // Reveal with no animation.
            cell.guiThumbImage.alpha = 1;
        }
    }];
    
    
    //
    // Social
    //
    
    // Likes counter
    cell.guiLikesCountLabel.textColor = self.remakesInfoTextColor;
    if (remake.likesCount && remake.likesCount.integerValue > 0) {
        cell.guiLikesCountLabel.text = [NSString stringWithFormat:@"%@", remake.likesCount];
        cell.guiLikesCountLabel.alpha = 1.0;
        cell.guiLikesIcon.alpha = 1.0;
    } else {
        cell.guiLikesCountLabel.text = @"0";
        cell.guiLikesCountLabel.alpha = 0.3;
        cell.guiLikesIcon.alpha = 0.3;
    }
    
    // Views counter
    cell.guiViewsCountLabel.textColor = self.remakesInfoTextColor;
    if (remake.viewsCount && remake.viewsCount.integerValue > 0) {
        cell.guiViewsCountLabel.text = [NSString stringWithFormat:@"%@", remake.viewsCount];
        cell.guiViewsCountLabel.alpha = 1.0;
        cell.guiViewsIcon.alpha = 1.0;
    } else {
        cell.guiViewsCountLabel.text = @"0";
        cell.guiViewsCountLabel.alpha = 0.3;
        cell.guiViewsIcon.alpha = 0.3;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Check if ignore flag not set.
    if (self.ignoreRemakeSelections) return;
    
    if (indexPath.item == self.fetchedResultsController.fetchedObjects.count) {
        [self loadAnotherRemakesPage];
        return;
    }
    
    // Get the related remake (ignore if for some reason not found);
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (!remake) {
        HMGLogError(@"User selected remake but none found in local storage. Critical error.");
        return;
    }

    // Will ignore further selections, until the remake screen is dismissed.
    self.ignoreRemakeSelections = YES;
    
    // Prepare the remake screen before the transition.
    HMRemakeCell *cell = (HMRemakeCell *)[collectionView cellForItemAtIndexPath:indexPath];
    CGRect f = cell.frame;
    CGPoint c = cell.center;
    c.y -= collectionView.contentOffset.y;
    [self.remakeScreenVC prepareForRemake:remake animateFromRect:f fromCenter:c];
    
    // Reveal the remake screen
    self.guiRemakeScreenContainer.hidden = NO;
    self.guiRemakeScreenContainer.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.guiRemakeScreenContainer.alpha = 1;
        self.guiMoreRemakesHeadlineLabel.alpha = 0;
        
        CGFloat currentOffset = self.remakesCV.contentOffset.y + self.remakesCV.contentInset.top;
        if (currentOffset >= self.offsetPoint) self.guiStoryMovieContainer.alpha = 0;
    }];
    
    // Stop the story movie player (if playing)
    [self.storyMoviePlayer done];
    
    // Mixpanel event (user selected a remake in story details screen)
    NSString *userID = remake.user.userID ? remake.user.userID : @"unknown";
    NSDictionary *properties = @{
                                 @"story_id": remake.story.sID,
                                 @"remake_id": remake.sID,
                                 @"remake_owner_id": userID,
                                 @"index": @(indexPath.item)
                                 };
    [[Mixpanel sharedInstance] track:@"SDSelectedRemake" properties:properties];
    
}

-(void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    HMRemakeCell *cell = (HMRemakeCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.1 animations:^{
        cell.alpha = 0.5;
        cell.transform = CGAffineTransformMakeScale(0.95, 0.95);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            cell.alpha = 1.0;
            cell.transform = CGAffineTransformIdentity;
        }];
    }];
}

-(void)handleNoRemakes
{
    BOOL hidden = YES;
    if ([self.remakesCV numberOfItemsInSection:0] == 0) {
        // If no fetches from server happened yet, stay hidden.
        // If already fetched from server and still no remakes, show the label.
        if (self.fetchedFirstPageFromServer) {
            hidden = NO;
        }
    }
    if (hidden) {
        self.noRemakesLabel.alpha = 0;
    } else {
        self.noRemakesLabel.text = LS(@"NO_REMAKES_STORY_DETAILS");
        [UIView animateWithDuration:1.0 animations:^{
            self.noRemakesLabel.alpha = 1;
        }];
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


// Deprecated.
//-(void)initVideoPlayerWithRemake:(Remake *)remake
//{
//    UIView *view;
//    self.guiRemakeVideoContainer = view = [[UIView alloc] initWithFrame:CGRectZero];
//    self.guiRemakeVideoContainer.backgroundColor = [UIColor clearColor];
//    
//    [self.view addSubview:self.guiRemakeVideoContainer];
//    [self.view bringSubviewToFront:self.guiRemakeVideoContainer];
//    //[self displayRect:@"self.guiVideoContainer.frame" BoundsOf:self.guiVideoContainer.frame];
//    
//    self.remakeMoviePlayer = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiRemakeVideoContainer rotationSensitive:YES];
//    self.remakeMoviePlayer.videoURL = remake.videoURL;
//    [self.remakeMoviePlayer hideVideoLabel];
//    //[self.videoView hideMediaControls];
//    
//    self.remakeMoviePlayer.delegate = self;
//    self.remakeMoviePlayer.originatingScreen = [NSNumber numberWithInteger:HMStoryDetails];
//    self.remakeMoviePlayer.entityType = [NSNumber numberWithInteger:HMRemake];
//    self.remakeMoviePlayer.entityID = remake.sID;
//    self.remakeMoviePlayer.resetStateWhenVideoEnds = YES;
//    [self.remakeMoviePlayer play];
//    [self.remakeMoviePlayer setFullScreen];
//}


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
                
                // Do nothing.
                self.guiRemakeActivity.hidden = YES;
                [self.guiRemakeActivity stopAnimating];
                self.guiRemakeButton.enabled = YES;
                break;
                
            case 1:
                
                // Continue old remake.
                [self initRecorderWithRemake:self.oldRemakeInProgress completion:nil];
                [[Mixpanel sharedInstance] track:@"doOldRemake" properties:@{@"story" : self.story.name}];
                break;
                
            case 2:
                
                [[Mixpanel sharedInstance] track:@"doNewRemakeOld" properties:@{@"story" : self.story.name}];
                NSString *remakeIDToDelete = self.oldRemakeInProgress.sID;
                
                // Out with the old
                [HMServer.sh deleteRemakeWithID:remakeIDToDelete];
                
                // In with the new.
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
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat currentOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
    if (self.shouldShowStoryMiniPlayer) {
        // Handle displaying/hiding mini player.
        [self handleMiniPlayerAppearanceByOffset:currentOffset];
    } else {
        CGFloat moviePos = -currentOffset;
        self.guiStoryMovieContainer.transform = CGAffineTransformMakeTranslation(0, moviePos);
        if (currentOffset >= self.offsetPoint) {
            if (self.storyMoviePlayer.isInAction) {
                [self.storyMoviePlayer pause];
            }
        }
    }

    // More remakes headline position
    CGFloat moreRamakesHeadlinePosition = MAX(-currentOffset, -self.offsetPoint);
    self.guiMoreRemakesHeadlineContainer.transform = CGAffineTransformMakeTranslation(0, moreRamakesHeadlinePosition);
    self.guiMoreRemakesHeadlineContainer.userInteractionEnabled = currentOffset >= self.offsetPoint;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y+scrollView.bounds.size.height;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (contentHeight - offset <= 50) {
        [self loadAnotherRemakesPage];
    }
}

-(void)_iPadScrollViewDidScroll:(UIScrollView *)scrollView
{

}

-(void)handleMiniPlayerAppearanceByOffset:(CGFloat)currentOffset
{
    if (currentOffset >= self.offsetPoint) {
        if (!self.isShowingStoryMiniPlayer) {
            // Reveal the mini player
            self.guiStoryMovieContainer.layer.zPosition = 10;
            self.guiStoryMovieContainer.alpha = 0;
            self.isShowingStoryMiniPlayer = YES;
            self.guiBackToTopButton.hidden = NO;
            self.guiBackToTopButton.layer.zPosition = 20;
            CGAffineTransform t = CGAffineTransformIdentity;
            if (IS_IPAD) {
                t = CGAffineTransformTranslate(t, 400, -180);
                t = CGAffineTransformScale(t, 0.20, 0.20);
            } else {
                t = CGAffineTransformTranslate(t, 220, -65);
                t = CGAffineTransformScale(t, 0.20, 0.20);
            }
            self.guiStoryMovieContainer.transform = t;
            [UIView animateWithDuration:1.0 animations:^{
                CGAffineTransform t = CGAffineTransformIdentity;
                if (IS_IPAD) {
                    t = CGAffineTransformTranslate(t, 300, -180);
                    t = CGAffineTransformScale(t, 0.20, 0.20);
                } else {
                    t = CGAffineTransformTranslate(t, 120, -65);
                    t = CGAffineTransformScale(t, 0.20, 0.20);
                }
                self.guiStoryMovieContainer.transform = t;
                self.guiStoryMovieContainer.alpha = 1;
            }];
        }
        
    } else {
        CGAffineTransform t;
        if (IS_IPAD) {
            CGFloat moviePos = -currentOffset/2.0f;
            t = CGAffineTransformMakeTranslation(0, moviePos);
            CGFloat scale = MAX(MIN(1.0, 1-currentOffset / self.offsetPoint),0.2);
            t = CGAffineTransformScale(t, scale, scale);
        } else {
            CGFloat moviePos = -currentOffset;
            t = CGAffineTransformMakeTranslation(0, moviePos);
        }
        
        self.guiStoryMovieContainer.transform = t;
        self.guiStoryMovieContainer.layer.zPosition = -1;
        self.isShowingStoryMiniPlayer = NO;
        self.guiBackToTopButton.hidden = YES;
        self.guiStoryMovieContainer.alpha = 1;
        self.guiStoryMovieContainer.hidden = NO;
    }
}

#pragma mark - HMRemakePresenterDelegate
-(void)dismissPresentedRemake
{
    // Hide the remake screen
    self.ignoreRemakeSelections = NO;
    [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.guiRemakeScreenContainer.alpha = 0;
        self.guiMoreRemakesHeadlineLabel.alpha = 1;
        self.guiStoryMovieContainer.alpha = 1;
    } completion:nil];
    [self.remakesCV reloadData];
}

-(void)userWantsToRemakeStory
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self remakeStory];
    });
}

#pragma mark - In App Store
-(void)openInAppStoreForCurrentStory
{
    if (!self.story.isPremiumAndLocked) return;
    
    HMInAppStoreViewController *vc = [HMInAppStoreViewController storeVCForStory:self.story];
    vc.delegate = self;
    vc.openedFor = HMStoreOpenedForStoryDetailsRemakeButton;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - HMStoreDelegate
-(void)storeDidFinishWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        // Check if user unlocked the current premium story.
        [self updateMakeYourOwnButton];
    }];
}

#pragma mark - recorder init
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



-(void)remakeStory
{
    self.guiRemakeButton.enabled = NO;
    self.guiRemakeActivity.hidden = NO;
    [self.guiRemakeActivity startAnimating];
    [self.storyMoviePlayer done];
    
    //
    // Check if story is premium
    // If it is premium, user will need to make a purchase first
    // (ignore and behave normally if app doesn't supports in app purchases
    // or if the content was already paid for)
    //
    if (self.story.isPremiumAndLocked  && [HMServer.sh supportsInAppPurchases]) {
        [self openInAppStoreForCurrentStory];
        return;
    }
    
    //
    // Remaking (opening the recorder screen)
    //
    User *user = [User current];
    self.oldRemakeInProgress = [user userPreviousRemakeForStory:self.story.sID];
    if (self.oldRemakeInProgress)
    {
        //
        // User already have a remake for this story in local storage.
        // If user already
        //
        if ([self.oldRemakeInProgress noFootagesTakenYet]) {
            
            // This remake is still clean.
            // User didn't take any footages for this remake yet.
            [self initRecorderWithRemake:self.oldRemakeInProgress];
            
        } else {
            
            // Some footages taken in the previous remake.
            // Let the user decide if she want to continue that remake
            // or start from scratch.
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"CONTINUE_WITH_REMAKE") message:LS(@"CONTINUE_OR_START_FROM_SCRATCH") delegate:self cancelButtonTitle:LS(@"CANCEL") otherButtonTitles:LS(@"OLD_REMAKE"), LS(@"NEW_REMAKE") , nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                alertView.tag = REMAKE_ALERT_TAG;
                [alertView show];
            });
        }
    } else {
        //
        // User doesn't have and old remake for this story in local storage.
        // Will create a new remake.
        //
        NSDictionary *info = @{
                               @"story": self.story.name,
                               @"story_id": self.story.sID,
                               @"is_locked": @(self.story.isPremiumAndLocked)
                               };
        [[Mixpanel sharedInstance] track:@"SDNewRemake" properties:info];
        [HMServer.sh createRemakeForStoryWithID:self.story.sID forUserID:User.current.userID withResolution:@"360"];
    }
}

#pragma mark - MONActivityIndicatorViewDelegate
-(UIColor *)activityIndicatorView:(MONActivityIndicatorView *)activityIndicatorView circleBackgroundColorAtIndex:(NSUInteger)index
{
    UIColor *color;
    color = [HMStyle.sh colorNamed:C_ARRAY_SD_MORE_REMAKES_ACTIVITY_INDICATOR
                           atIndex:index];
    return color;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedScrollToTopButton:(id)sender
{
    [self.remakesCV scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}


- (IBAction)onPressedRemakeButton:(UIButton *)sender
{
    [self remakeStory];
}

- (IBAction)moreButtonPushed:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    Remake *remake = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.flaggedRemake = remake;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc]initWithTitle:LS(@"OPTIONS") delegate:self cancelButtonTitle:LS(@"CANCEL") destructiveButtonTitle:nil otherButtonTitles:LS(@"MARK_AS_INAPPROPRIATE"), nil];
    [actionSheet showInView:self.view];
}

// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    //self.view.backgroundColor = [UIColor clearColor];
}

-(IBAction)unwindFromRemakeScreenToStoryDetails:(UIStoryboardSegue *)unwindSegue
{
    
}

@end
