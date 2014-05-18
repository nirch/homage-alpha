//
//  HMRecorderDetailedOptionsBarViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@import AVFoundation;

#import "HMRecorderDetailedOptionsBarViewController.h"
#import "DB.h"
#import "HMSceneCell.h"
#import "HMNotificationCenter.h"
#import "HMServer+LazyLoading.h"
#import "HMSimpleVideoViewController.h"
#import "HMRoundCountdownLabel.h"
#import "HMColor.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMAnimationsFX.h"
#import "mixpanel.h"
#import "HMMotionDetector.h"
#import "HMAvenirBookFontLabel.h"

@interface HMRecorderDetailedOptionsBarViewController ()

@property (nonatomic, readonly) BOOL alreadyInitializedGUI;

// Action bar, with more or less details.
@property (weak, nonatomic) IBOutlet UIView *guiMoreDetailsBar;
@property (weak, nonatomic) IBOutlet UIView *guiLessDetailsBar;
@property (weak, nonatomic) IBOutlet UIButton *guiCloseButton;
@property (weak, nonatomic) IBOutlet UILabel *guiCurrentSceneDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiCurrentSceneLabel;
@property (weak, nonatomic) IBOutlet UIImageView *guiReachability;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiMicrophoneUnauthorizedLabel;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiBadBGLabel;


// Table of scenes
@property (weak, nonatomic) IBOutlet UITableView *guiTableView;
@property (weak, nonatomic) IBOutlet UIView *guiTableHeaderView;

// Current Scene & story videos
@property (weak, nonatomic) IBOutlet UIView *guiSceneVideoContainerView;
@property (weak, nonatomic) IBOutlet UIView *guiStoryVideoContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *guiOriginalTakesVideosScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *guiOriginalTakesPageControl;
@property (weak, nonatomic, readonly) HMSimpleVideoViewController *sceneVideoVC;
@property (weak, nonatomic, readonly) HMSimpleVideoViewController *storyVideoVC;



// Scene direction and show script buttons
@property (weak, nonatomic) IBOutlet UIView *guiSceneDirectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiSceneDirectionButton;
@property (weak, nonatomic) IBOutlet UIView *guiShowScriptButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiShowScriptButton;

// Pointers to some info
@property (nonatomic, readonly) Remake *remake;
@property (nonatomic, readonly) NSArray *scenesOrdered;
@property (nonatomic, readonly) NSArray *footagesOrdered;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) NSArray *footagesReadyStates;
@property (nonatomic, readonly) NSNumber *sceneID;

// The round action buttons
@property (weak, nonatomic) IBOutlet UIButton *guiRecordButton;
@property (weak, nonatomic) IBOutlet UIView *guiCountdownContainer;
@property (weak, nonatomic) IBOutlet HMRoundCountdownLabel *guiRoundCountdownLabal;


//THE HAND!!!
@property (weak, nonatomic) IBOutlet UIImageView *guiPointingHand;

//audio player
@property (strong,nonatomic) AVAudioPlayer *audioPlayer;



@end

@implementation HMRecorderDetailedOptionsBarViewController

@synthesize remakerDelegate = _remakerDelegate;

-(void)viewDidLoad
{
    [super viewDidLoad];
    _remake = [self.remakerDelegate remake];
    [self checkMicrophoneAuthorization];
    [self initGUI];
    [self initObservers];
    [self refreshInfo];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self checkMicrophoneAuthorization];
    [self initGUIOnceAfterFirstAppearance];
    [self initObservers];
    [self updateTableHeader];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
    [self.sceneVideoVC done];
    [self.storyVideoVC done];
}

-(void)dealloc
{
    // NSLog(@">>> dealloc %@", [self class]);
}

-(void)checkMicrophoneAuthorization
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL response){
        self.guiMicrophoneUnauthorizedLabel.hidden = response;
    }];
}

-(void)initGUI
{
    // Video controllers (scene & story)
    HMSimpleVideoViewController *vc;
    _sceneVideoVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiSceneVideoContainerView rotationSensitive:NO];
    self.sceneVideoVC.videoLabelText = LS(@"WATCH_OUR_SCENE");
    self.sceneVideoVC.delegate = self;
    
    _storyVideoVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiStoryVideoContainerView rotationSensitive:NO];
    self.storyVideoVC.videoLabelText = LS(@"WATCH_OUR_STORY");
    self.storyVideoVC.videoImage = [self lazyLoadThumbForStory:self.remake.story];
    self.storyVideoVC.videoURL = self.remake.story.videoURL;
    self.storyVideoVC.delegate = self;
    
    // Countdown delegate
    self.guiRoundCountdownLabal.delegate = self;
    
    //bad BG label
    self.guiBadBGLabel.hidden = YES;
}

-(void)initGUIOnceAfterFirstAppearance
{
    if (self.alreadyInitializedGUI) return;
    
    // The scroll view containing the two videos
    // Change the content size according to the size of the containers
    // Put the second container in the correct spot, according to the width
    NSInteger videosPages = 2;
    CGSize size = self.guiOriginalTakesVideosScrollView.bounds.size;
    self.guiOriginalTakesVideosScrollView.contentSize = CGSizeMake(size.width * videosPages, size.height);
    
    CGRect frame = self.guiStoryVideoContainerView.frame;
    frame.origin.x += size.width;
    self.guiStoryVideoContainerView.frame = frame;
    
    self.guiOriginalTakesPageControl.numberOfPages = videosPages;
    self.guiOriginalTakesPageControl.currentPage = 0;
    
    //THE HAND!!!
    /*self.guiPointingHand.hidden = YES;
    if (![User current].skipRecorderTutorial && self.remakerDelegate.showHand == YES);
    {
        self.guiPointingHand.hidden = NO;
        self.guiPointingHand.transform = CGAffineTransformMakeTranslation(0, 5);
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.3 delay:0 options:HM_ANIMATION_OPTION_PING_PONG animations:^{
                self.guiPointingHand.transform = CGAffineTransformMakeTranslation(0, -5);
            } completion:nil];
        });
    }*/
    
    // Mark that GUI already initialized once.
    _alreadyInitializedGUI = YES;
    
}

-(void)refreshInfo
{
    _scenesOrdered = self.remake.story.scenesOrdered;
    _footagesOrdered = self.remake.footagesOrdered;
    _footagesReadyStates = self.remake.footagesReadyStates;
}

#pragma mark - Obesrvers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // Observe closing animation
    [nc addUniqueObserver:self
                 selector:@selector(onRecorderDetailedOptionsClosing:)
                     name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSING
                   object:nil];
    
    // Observe closed state
    [nc addUniqueObserver:self
                 selector:@selector(onRecorderDetailedOptionsClosed:)
                     name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED
                   object:nil];
    
    // Observe opening animation
    [nc addUniqueObserver:self
                 selector:@selector(onRecorderDetailedOptionsOpening:)
                     name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENING
                   object:nil];
    
    // Observe opened state
    [nc addUniqueObserver:self
                 selector:@selector(onRecorderDetailedOptionsOpened:)
                     name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENED
                   object:nil];
    
    // Observe scene change
    [nc addUniqueObserver:self
                 selector:@selector(onUpdateCurrentScene:)
                     name:HM_UI_NOTIFICATION_RECORDER_CURRENT_SCENE
                   object:nil];
    
    // Observe scene thumbnail
    [nc addUniqueObserver:self
                 selector:@selector(onLazyLoadedSceneThumbnail:)
                     name:HM_NOTIFICATION_SERVER_SCENE_THUMBNAIL
                   object:nil];
    
    // Observe story thumbnail
    [nc addUniqueObserver:self
                 selector:@selector(onLazyLoadedStoryThumbnail:)
                     name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
                   object:nil];
    
    // Observe story thumbnail
    [nc addUniqueObserver:self
                 selector:@selector(onUploadProgress:)
                     name:HM_NOTIFICATION_UPLOAD_PROGRESS
                   object:nil];
    
    //observe bad background
    [nc addUniqueObserver:self
                 selector:@selector(showBadBackgroundLabel)
                     name:HM_NOTIFICATION_RECORDER_BAD_BACKGROUND
                   object:nil];
    
    //observe good background
    [nc addUniqueObserver:self
                 selector:@selector(hideBadBackgroundLabel)
                     name:HM_NOTIFICATION_RECORDER_GOOD_BACKGROUND
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(hideBadBackgroundLabel)
                     name:HM_DISABLE_BG_DETECTION
                   object:nil];
    
    // Observe reachability status changes
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:HMServer.sh];
    
    //observe camera movment
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onPressedCancelCountdownButton:)
                                                       name:HM_NOTIFICATION_CAMERA_NOT_STABLE
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onPressedCancelCountdownButton:)
                                                       name:HM_APP_WILL_RESIGN_ACTIVE
                                                     object:nil];
    
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSING object:nil];
    [nc removeObserver:self name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED object:nil];
    [nc removeObserver:self name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENING object:nil];
    [nc removeObserver:self name:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENED object:nil];
    [nc removeObserver:self name:HM_UI_NOTIFICATION_RECORDER_CURRENT_SCENE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SCENE_THUMBNAIL object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_CAMERA_NOT_STABLE object:nil];
    [nc removeObserver:self name:HM_APP_WILL_RESIGN_ACTIVE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_BAD_BACKGROUND object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_GOOD_BACKGROUND object:nil];
    [nc removeObserver:self name:HM_DISABLE_BG_DETECTION object:nil];
    
    
}

#pragma mark - Observers handlers
-(void)onLazyLoadedSceneThumbnail:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *sceneID = info[@"sceneID"];
    UIImage *image = info[@"image"];
    
    Scene *scene = [self.remake.story findSceneWithID:sceneID];
    if (notification.isReportingError || !image) {
        scene.thumbnail = nil;
    } else {
        scene.thumbnail = image;
    }
    
    // If scene not currently visible, don't update the UI
    if (![self.sceneID isEqualToNumber:sceneID]) return;
    self.sceneVideoVC.videoImage = image;
}

-(void)onLazyLoadedStoryThumbnail:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    UIImage *image = info[@"image"];
    NSString *storyID = info[@"storyID"];
    
    if (notification.isReportingError || !image || ![storyID isEqualToString:self.remake.story.sID])
    {
        self.remake.story.thumbnail = nil;
    } else {
        self.remake.story.thumbnail = image;
    }
    // If scene not currently visible, don't update the UI
    self.storyVideoVC.videoImage = image;
}

-(void)onRecorderDetailedOptionsClosed:(NSNotification *)notification
{
    self.guiLessDetailsBar.hidden = NO;
    self.guiMoreDetailsBar.hidden = YES;
    self.guiRecordButton.hidden = NO;
    
    self.guiRecordButton.enabled = YES;
    self.guiCloseButton.enabled= NO;
    
    self.guiLessDetailsBar.alpha = 1;
    self.guiMoreDetailsBar.alpha = 0;
    
    [self.sceneVideoVC done];
    [self.storyVideoVC done];
}

-(void)onRecorderDetailedOptionsClosing:(NSNotification *)notification
{
    self.guiLessDetailsBar.hidden = NO;
    self.guiMoreDetailsBar.hidden = NO;
    self.guiRecordButton.enabled = NO;
    self.guiCloseButton.enabled= NO;
    self.guiRecordButton.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiRecordButton.transform = CGAffineTransformIdentity;
        self.guiLessDetailsBar.alpha = 1;
        self.guiMoreDetailsBar.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
}

-(void)onRecorderDetailedOptionsOpened:(NSNotification *)notification
{
    [self.guiTableView reloadData];

    //
    //  Snappy arrow pointing on scene label
    //
    if (self.sceneID) {
        NSInteger rowNumber = self.count - self.sceneID.integerValue;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowNumber inSection:0];
        [self snapIndicatorIntoPlaceAtIndexPath:indexPath];
    }
    
    self.guiLessDetailsBar.hidden = YES;
    self.guiMoreDetailsBar.hidden = NO;
    
    self.guiRecordButton.enabled = NO;
    self.guiCloseButton.enabled= YES;
    
    self.guiLessDetailsBar.alpha = 0;
    self.guiMoreDetailsBar.alpha = 1;
    
    
}

-(void)onRecorderDetailedOptionsOpening:(NSNotification *)notification
{
    self.guiLessDetailsBar.hidden = YES;
    self.guiMoreDetailsBar.hidden = NO;
    self.guiRecordButton.enabled = NO;
    self.guiCloseButton.enabled= NO;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.guiMoreDetailsBar.alpha = 1;
    } completion:^(BOOL finished) {
        if (finished) self.guiRecordButton.hidden = YES;
    }];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.guiRecordButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
    } completion:nil];
}

-(void)onUpdateCurrentScene:(NSNotification *)notification
{
    _sceneID = notification.userInfo[@"sceneID"];
    [self updateUIForSceneID:self.sceneID];
    self.guiReachability.hidden = HMServer.sh.isReachable;
}

-(void)onReachabilityStatusChange:(NSNotification *)notification
{
    self.guiReachability.hidden = HMServer.sh.isReachable;
}

-(void)onUploadProgress:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *sceneID = info[HM_INFO_SCENE_ID];
    NSInteger rowNumber = self.count - sceneID.integerValue;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:rowNumber inSection:0];
    if (![self.guiTableView.indexPathsForVisibleRows containsObject:indexPath]) return;
    HMSceneCell *cell = (HMSceneCell *)[self.guiTableView cellForRowAtIndexPath:indexPath];
    double progress = [info[HM_INFO_PROGRESS] doubleValue];
    cell.guiUploadProgressBar.progress = progress;
    
    
}

#pragma mark - Scene selection
-(void)updateUIForSceneID:(NSNumber *)sceneID
{
    Scene *scene = [self.remake.story findSceneWithID:sceneID];
    Footage *footage = [self.remake footageWithSceneID:sceneID];
    self.guiCurrentSceneLabel.text = [scene titleForSceneID];
    if ([footage readyState] == HMFootageReadyStateReadyForFirstRetake) {
        self.guiCurrentSceneLabel.textColor = HMColor.sh.text;
    } else {
        self.guiCurrentSceneLabel.textColor = HMColor.sh.textImpact;
    }
    self.guiCurrentSceneDurationLabel.text = [scene titleForTime];
    
    // Current scene "OUR TAKE" video.
    self.sceneVideoVC.videoImage = [self lazyLoadThumbImageForScene:scene];
    self.sceneVideoVC.videoURL = scene.videoURL;
    
    // Show script button shown only if script exists for this scene.
    double w = self.guiSceneDirectionButtonContainer.superview.bounds.size.width;
    CGRect f = self.guiSceneDirectionButtonContainer.frame;
    if (scene.script) {
        f.size.width = w / 2.0-2;
        self.guiSceneDirectionButtonContainer.frame = f;
    } else {
        f.size.width = w;
        self.guiSceneDirectionButtonContainer.frame = f;
    }
    
    [self refreshInfo];
    [self.guiTableView reloadData];
    [self updateShowHideScriptButtonWithReport:NO];
    [self updateTableHeader];
}

#pragma mark - Lazy loading
-(UIImage *)lazyLoadThumbImageForScene:(Scene *)scene
{
    if (scene.thumbnail) return scene.thumbnail;
    [HMServer.sh lazyLoadImageFromURL:scene.thumbnailURL
                     placeHolderImage:nil
                     notificationName:HM_NOTIFICATION_SERVER_SCENE_THUMBNAIL
                                 info:@{@"sceneID":scene.sID}
     ];
    return nil;
}

-(UIImage *)lazyLoadThumbForStory:(Story *)story
{
    if (story.thumbnail) return story.thumbnail;
    [HMServer.sh lazyLoadImageFromURL:story.thumbnailURL
                     placeHolderImage:nil
                     notificationName:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
                                 info:@{@"storyID":story.sID}
     ];
    return nil;
}

#pragma mark - Original takes
-(void)updateOriginalTakesPageContol
{
    UIScrollView *scrollView = self.guiOriginalTakesVideosScrollView;
    NSInteger page = scrollView.contentOffset.x / scrollView.frame.size.width;
    [self.guiOriginalTakesPageControl setCurrentPage:page];
}

#pragma mark - Table Data Source
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.footagesOrdered.count != self.scenesOrdered.count) {
        // Just in case bad data from the server doesn't provide the same number of footages as scenes.
        _count = MIN(self.footagesOrdered.count, self.scenesOrdered.count);
        HMGLogWarning(@"Why is the number of footaged %ld is not the same as the number of scenes %ld ?",(long)self.footagesOrdered.count,(long)self.scenesOrdered.count);
    } else {
        _count = self.footagesOrdered.count;
    }
    return self.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"scene cell";
    HMSceneCell *cell = [self.guiTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

// The scenes are ordered in the UI from bottom (lowest ID) to the top (highest ID)
// The indexes for rows start at the top of course.
// So given an indexPath, returns the index of the scene in the orderedScenes array.
-(NSInteger)sceneIndexForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = self.count - indexPath.row - 1;
    return index;
}

-(void)configureCell:(HMSceneCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = [self sceneIndexForIndexPath:indexPath]; // self.count - indexPath.row - 1;
    Scene *scene = self.scenesOrdered[index];
    HMFootageReadyState footageReadyState = [self.footagesReadyStates[index] integerValue];
    
    cell.guiSceneLabel.text = [Scene titleForSceneBySceneID:scene.sID];
    cell.readyState = footageReadyState;
    cell.guiSceneTimeLabel.text = scene.titleForTime;
    cell.guiSelectRowButton.tag = indexPath.row;
    cell.guiRetakeSceneButton.tag = indexPath.row;
    cell.guiRowIndicatorImage.alpha = [scene.sID isEqualToNumber:self.sceneID] ? 1 : 0;
    cell.guiRowIndicatorImage.transform = CGAffineTransformIdentity;
}

-(void)snapIndicatorIntoPlaceAtIndexPath:(NSIndexPath *)indexPath
{
    HMSceneCell *cell = (HMSceneCell *)[self.guiTableView cellForRowAtIndexPath:indexPath];
    cell.guiRowIndicatorImage.alpha = 1;
    cell.animator = [[UIDynamicAnimator alloc] initWithReferenceView:cell.guiRowIndicatorImage.superview];
    UISnapBehavior *snap = [[UISnapBehavior alloc] initWithItem:cell.guiRowIndicatorImage snapToPoint:CGPointMake(39,28)];
    [snap setDamping:0.3];
    [cell.animator addBehavior:snap];
}

-(void)updateTableHeader
{
    UIView *headerView = self.guiTableView.tableHeaderView;
    CGRect f = headerView.frame;
    f.size.height = self.remake.allScenesTaken ? 64 : 0;
    headerView.frame = f;
    self.guiTableView.tableHeaderView = headerView;
}

#pragma mark - Scroll view delegate
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateOriginalTakesPageContol];
    [self.sceneVideoVC done];
    [self.storyVideoVC done];
}

#pragma mark - HMCountDownDelegate
-(void)countDownDidFinish
{
    // Start recording for current scene.
    Footage *footage = [self.remake footageWithSceneID:self.sceneID];
    NSString *fileName = [footage generateNewRawFileName];
    HMGLogDebug(@"Will start recording to tmp file:%@", fileName);
    
    // Count down finished. Notify that the camera should start recording.
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_START_RECORDING
                                                        object:self
                                                      userInfo:@{HM_INFO_FILE_NAME:fileName,
                                                                 HM_INFO_REMAKE_ID:self.remake.sID,
                                                                 HM_INFO_SCENE_ID:footage.sceneID,
                                                                 HM_INFO_DURATION_IN_SECONDS:@(footage.relatedScene.durationInSeconds)
                                                                 }
     ];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.guiCountdownContainer.hidden = YES;
    });
}

#pragma mark - Show/Hide script
-(void)toggleUserPreferenceToShowingOrHidingScriptWhileRecording
{
    
    if (User.current.prefersToSeeScriptWhileRecording.boolValue) {
        User.current.prefersToSeeScriptWhileRecording = @NO;
    } else {
        User.current.prefersToSeeScriptWhileRecording = @YES;
    }
}

-(void)updateShowHideScriptButtonWithReport:(BOOL)report
{
    if (User.current.prefersToSeeScriptWhileRecording.boolValue) {
        [self.guiShowScriptButton setTitle: LS(@"HIDE_SCRIPT") forState:UIControlStateNormal];
        [[Mixpanel sharedInstance] track:@"REHideScript" properties:@{@"story" : self.remake.story.name}];
    } else {
        [self.guiShowScriptButton setTitle:LS(@"SHOW_SCRIPT") forState:UIControlStateNormal];
        
        if (report) [[Mixpanel sharedInstance] track:@"REShowScript" properties:@{@"story" : self.remake.story.name}];

    }
    [self.remakerDelegate updateWithUpdateType:HMRemakerUpdateTypeScriptToggle info:nil];
}

#pragma mark - HMSimpleVideoPlayerDelegate
-(void)videoPlayerWillPlay
{
    if (self.guiOriginalTakesPageControl.currentPage == 0) //our scene
    {
        [[Mixpanel sharedInstance] track:@"REPlayOurScene"];
    } else if (self.guiOriginalTakesPageControl.currentPage == 1) //our story
    {
        [[Mixpanel sharedInstance] track:@"REPlayOurStory"];
    }
}

-(void)videoPlayerDidStop:(id)sender afterDuration:(NSString *)playbackTime
{
    if (self.guiOriginalTakesPageControl.currentPage == 0) //our scene
    {
        [[Mixpanel sharedInstance] track:@"REStopOurScene" properties:@{@"time_watched" : playbackTime}];
    } else if (self.guiOriginalTakesPageControl.currentPage == 1) //our story
    {
        [[Mixpanel sharedInstance] track:@"REStopOurStory" properties:@{@"time_watched" : playbackTime}];
    }    
}

-(void)videoPlayerDidFinishPlaying
{
    [self.sceneVideoVC done];
    [self.storyVideoVC done];
    
    if (self.guiOriginalTakesPageControl.currentPage == 0) //our scene
    {
        [[Mixpanel sharedInstance] track:@"REfinishOurScene"];
    } else if (self.guiOriginalTakesPageControl.currentPage == 1) //our story
    {
        [[Mixpanel sharedInstance] track:@"REfinishOurStory"];
    }
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
-(IBAction)onPressedCloseButton:(UIButton *)sender
{
    [self.remakerDelegate toggleOptions];
}

- (IBAction)onPressedOpenButton:(UIButton *)sender
{
    //THE HAND!!!
    self.guiPointingHand.hidden = YES;
    [[Mixpanel sharedInstance] track:@"REexpandMenu"];
    [self.remakerDelegate toggleOptions];
}

- (IBAction)onChangedValueOriginalTakesPageControl:(UIPageControl *)sender
{
    NSInteger page = sender.currentPage;
    UIScrollView *scrollView = self.guiOriginalTakesVideosScrollView;
    CGPoint offset = CGPointMake(page*scrollView.bounds.size.width, 0);
    [scrollView setContentOffset:offset animated:YES];
}

- (IBAction)onPressedRecordButton:(UIButton *)sender
{
    // Countdown before actual recording starts.
    // (user can cancel this action before the countdown ends)
    [HMMotionDetector.sh start];
    [self postDisableBGdetectionNotification];
    NSString *eventName = [NSString stringWithFormat:@"REHitRecordScene%ld" , self.sceneID.longValue];
    [[Mixpanel sharedInstance] track:eventName properties:@{@"sceneNumber" : self.sceneID , @"story" : self.remake.story.name}];
    self.guiCountdownContainer.hidden = NO;
    [self.guiRoundCountdownLabal startTicking];
    
    //play countdown sound
    NSError *error;
    NSURL *cinemaCountdownURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"cinemaCountdown_oneLast" ofType:@"wav"]];
    self.audioPlayer = [[AVAudioPlayer alloc]
                        initWithContentsOfURL:cinemaCountdownURL error:&error];
    NSLog(@"error: %@" , error);
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
    
    Scene *scene = [self.remake.story findSceneWithID:self.sceneID];
    CGPoint focusPoint = scene.focusCGPoint;
    NSDictionary *userInfo = @{HM_INFO_FOCUS_POINT:@[@(focusPoint.x),@(focusPoint.y)]};
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_START_COUNTDOWN_BEFORE_RECORDING object:nil userInfo:userInfo];
}

- (IBAction)onPressedCancelCountdownButton:(UIButton *)sender
{
    [self cancelCountdown];
}

-(void)cancelCountdown
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_CANCEL_COUNTDOWN_BEFORE_RECORDING object:nil];
    [self.guiRoundCountdownLabal cancel];
    [HMMotionDetector.sh stopWithNotification:NO];
    [self postEnableBGDetectionNotification];
    [[Mixpanel sharedInstance] track:@"RECancelRecord"];
    self.guiCountdownContainer.hidden = YES;
    [self.audioPlayer stop];
    
    
}

- (IBAction)onPressedSceneDirectionButton:(id)sender
{
    [[Mixpanel sharedInstance] track:@"REMenuSceneDirection" properties:@{@"story" : self.remake.story.name}];
    [self.remakerDelegate showSceneContextMessageForSceneID:self.sceneID checkNextStateOnDismiss:NO info:nil];
}

- (IBAction)onPressedToggleShowingScriptButton:(id)sender
{
    [self toggleUserPreferenceToShowingOrHidingScriptWhileRecording];
    [self updateShowHideScriptButtonWithReport:YES];
}

- (IBAction)onPressedCreateMovieButton:(id)sender
{
    [self.remakerDelegate updateWithUpdateType:HMRemakerUpdateTypeCreateMovie info:nil];
}

- (IBAction)onPressedSelectScene:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    [[Mixpanel sharedInstance] track:@"REReturnToScene" properties:@{@"sceneNumber" : [NSString stringWithFormat:@"%ld" , (long)indexPath.item]}];
    NSInteger index = [self sceneIndexForIndexPath:indexPath];
    HMFootageReadyState footageReadyState = [self.footagesReadyStates[index] integerValue];
    
    //
    // Some crazy animations
    //
    double delayInSeconds = 0.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        HMSceneCell *cell = (HMSceneCell *)[self.guiTableView cellForRowAtIndexPath:indexPath];
        if (footageReadyState == HMFootageReadyStateStillLocked)
        {
            cell.guiSceneLockedIcon.transform = CGAffineTransformMakeScale(1.2, 1.2);
            [UIView animateWithDuration:0.5 animations:^{
                cell.guiSceneLockedIcon.transform = CGAffineTransformIdentity;
            }];
            return;
        }
        
        if (footageReadyState == HMFootageReadyStateReadyForSecondRetake) {
            [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                cell.guiSceneRetakeIcon.transform = CGAffineTransformMakeRotation(-M_PI*0.2);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1.0 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    cell.guiSceneRetakeIcon.transform = CGAffineTransformIdentity;
                } completion:nil];
            }];
        }
        
        //
        //  The label scales a bit
        //
        [UIView animateWithDuration:0.7 animations:^{
            cell.guiSceneLabel.alpha = 0.5;
            cell.guiSceneLabel.transform = CGAffineTransformMakeScale(1.1, 1.1);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.7 animations:^{
                cell.guiSceneLabel.alpha = 1;
                cell.guiSceneLabel.transform = CGAffineTransformIdentity;
            }];
        }];
        
        //
        //  Snappy arrow pointing on scene label
        //
        [self snapIndicatorIntoPlaceAtIndexPath:indexPath];
    });
    
    // Will not select locked scenes.
    if (footageReadyState == HMFootageReadyStateStillLocked) return;
    
    //
    // Hide selection indicator from all scenes
    //
    for (HMSceneCell *cell in self.guiTableView.visibleCells) {
        cell.guiRowIndicatorImage.alpha = 0;
        cell.guiRowIndicatorImage.center = CGPointMake(-50,28+arc4random()%40-20);
    }
    
    //
    // Actually selecting the scene
    //
    Scene *scene = self.scenesOrdered[index];
    [self.remakerDelegate selectSceneID:scene.sID];
    
}

- (IBAction)onPressedRetakeButton:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
    NSInteger index = [self sceneIndexForIndexPath:indexPath];
    Scene *scene = self.scenesOrdered[index];
    Footage *footage = [self.remake footageWithSceneID:scene.sID];
    if (footage.readyState != HMFootageReadyStateReadyForSecondRetake) return;
    [self.remakerDelegate updateWithUpdateType:HMRemakerUpdateTypeRetakeScene info:@{@"sceneID":scene.sID}];
}


-(void)showBadBackgroundLabel
{
    if (!self.guiBadBGLabel.hidden) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.guiBadBGLabel.hidden = NO;
    });
}

-(void)hideBadBackgroundLabel
{
    if (self.guiBadBGLabel.hidden) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.guiBadBGLabel.hidden = YES;
    });
}

//make comment should you want to hide status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)postDisableBGdetectionNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_DISABLE_BG_DETECTION object:self];
}

-(void)postEnableBGDetectionNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_ENABLE_BG_DETECTION object:self];
}


@end
