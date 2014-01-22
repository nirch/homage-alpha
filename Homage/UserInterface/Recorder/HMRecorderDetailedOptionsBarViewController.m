//
//  HMRecorderDetailedOptionsBarViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderDetailedOptionsBarViewController.h"
#import "DB.h"
#import "HMSceneCell.h"
#import "HMNotificationCenter.h"
#import "HMServer+LazyLoading.h"
#import "HMSimpleVideoViewController.h"
#import "HMRoundCountdownLabel.h"

@interface HMRecorderDetailedOptionsBarViewController ()

@property (nonatomic, readonly) BOOL alreadyInitializedGUI;

// Action bar, with more or less details.
@property (weak, nonatomic) IBOutlet UIView *guiMoreDetailsBar;
@property (weak, nonatomic) IBOutlet UIView *guiLessDetailsBar;
@property (weak, nonatomic) IBOutlet UIButton *guiCloseButton;
@property (weak, nonatomic) IBOutlet UILabel *guiCurrentSceneDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiCurrentSceneLabel;

// Table of scenes
@property (weak, nonatomic) IBOutlet UITableView *guiTableView;

// Current Scene & story videos
@property (weak, nonatomic) IBOutlet UIView *guiSceneVideoContainerView;
@property (weak, nonatomic) IBOutlet UIView *guiStoryVideoContainerView;
@property (weak, nonatomic) IBOutlet UIScrollView *guiOriginalTakesVideosScrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *guiOriginalTakesPageControl;
@property (weak, nonatomic, readonly) HMSimpleVideoViewController *sceneVideoVC;
@property (weak, nonatomic, readonly) HMSimpleVideoViewController *storyVideoVC;

// Scene direction and show script buttons
@property (weak, nonatomic) IBOutlet UIView *guiSceneDirectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIView *guiShowScriptButtonContainer;

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


@end

@implementation HMRecorderDetailedOptionsBarViewController

@synthesize remakerDelegate = _remakerDelegate;

-(void)viewDidLoad
{
    [super viewDidLoad];
    _remake = [self.remakerDelegate remake];
    [self initGUI];
    [self initObservers];
    [self refreshInfo];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initGUIOnceAfterAppearance];
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
    [self.sceneVideoVC done];
    [self.storyVideoVC done];
}

-(void)initGUI
{
    // Video controllers (scene & story)
    HMSimpleVideoViewController *vc;
    _sceneVideoVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiSceneVideoContainerView];
    self.sceneVideoVC.videoLabelText = @"PLAY OUR TAKE";
    
    _storyVideoVC = vc = [[HMSimpleVideoViewController alloc] initWithDefaultNibInParentVC:self containerView:self.guiStoryVideoContainerView];
    self.storyVideoVC.videoLabelText = @"PLAY OUR STORY";
    self.storyVideoVC.videoImage = [self lazyLoadThumbForStory:self.remake.story];
    self.storyVideoVC.videoURL = self.remake.story.videoURL;
    
    // Countdown delegate
    self.guiRoundCountdownLabal.delegate = self;
}

-(void)initGUIOnceAfterAppearance
{
    if (self.alreadyInitializedGUI) return;
    
    // The scroll view containing the two videos
    NSInteger originalTakesPages = 2;
    CGSize size = self.guiSceneVideoContainerView.bounds.size;
    size.width *= originalTakesPages;
    self.guiOriginalTakesVideosScrollView.contentSize = size;
    self.guiOriginalTakesPageControl.numberOfPages = originalTakesPages;
    self.guiOriginalTakesPageControl.currentPage = 0;
    
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
    
    // Observe scene thumbnail
    [nc addUniqueObserver:self
                 selector:@selector(onLazyLoadedStoryThumbnail:)
                     name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL
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
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SCENE_THUMBNAIL object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_STORY_THUMBNAIL object:nil];
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
    if (notification.isReportingError || !image) {
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
}

#pragma mark - Scene selection
-(void)updateUIForSceneID:(NSNumber *)sceneID
{
    Scene *scene = [self.remake.story findSceneWithID:sceneID];
    self.guiCurrentSceneLabel.text = [scene titleForSceneID];
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
    // TODO: ask why sometimes the server return more scenes for the story than available footages for the remake.
    _count = MIN(self.footagesOrdered.count, self.scenesOrdered.count);
    return self.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"scene cell";
    HMSceneCell *cell = [self.guiTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

-(void)configureCell:(HMSceneCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = self.count - indexPath.row - 1;
    Scene *scene = self.scenesOrdered[index];
    HMFootageReadyState footageReadyState = [self.footagesReadyStates[index] integerValue];
    
    cell.guiSceneLabel.text = [Scene titleForSceneBySceneID:scene.sID];
    cell.readyState = footageReadyState;
    cell.guiSceneTimeLabel.text = scene.titleForTime;
}

#pragma mark - Table view delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = self.count - indexPath.row - 1;
    HMFootageReadyState readyState = [self.footagesReadyStates[index] integerValue];
    if (readyState == HMFootageReadyStateStillLocked) {
        // Can't select locked scenes;
        [self.guiTableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }

    // A selectable row
    Scene *scene = self.scenesOrdered[index];
    [self.remakerDelegate selectSceneID:scene.sID];
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
                                                      userInfo:@{@"fileName":fileName,
                                                                 @"remakeID":self.remake.sID,
                                                                 @"sceneID":footage.sceneID,
                                                                 @"durationInSeconds":@(footage.relatedScene.durationInSeconds)
                                                                 }
     ];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.guiCountdownContainer.hidden = YES;
    });
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
    self.guiCountdownContainer.hidden = NO;
    [self.guiRoundCountdownLabal startTicking];
    
}

- (IBAction)onPressedCancelCountdownButton:(UIButton *)sender
{
    [self.guiRoundCountdownLabal cancel];
    self.guiCountdownContainer.hidden = YES;
}

- (IBAction)onPressedSceneDirectionButton:(id)sender
{
    [self.remakerDelegate showSceneContextMessageForSceneID:self.sceneID];
}

- (IBAction)onPressedShowScriptButton:(id)sender
{
}


@end
