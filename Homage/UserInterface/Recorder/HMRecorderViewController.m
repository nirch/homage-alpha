//
//  HMRecorderViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#define SILHOUETTE_HARD_CODED_ALPHA 0.85f

#define OPTIONS_BAR_TRANSFORM_MAX 167.0f
#define OPTIONS_BAR_TRANSFORM_CLOSED CGAffineTransformMakeTranslation(0, OPTIONS_BAR_TRANSFORM_MAX)
#define OPTIONS_BAR_TRANSFORM_OPENED CGAffineTransformIdentity
#define OPTIONS_BAR_TRANSFORM_HIDDEN CGAffineTransformMakeTranslation(0, 260)

#import "HMRecorderViewController.h"
#import "DB.h"
#import "HMRecorderChildInterface.h"
#import "HMRecorderMessagesOverlayViewController.h"
#import "HMNotificationCenter.h"
#import "HMRecorderEditTextsViewController.h"
#import "HMVideoCameraViewController.h"
#import "HMRecorderTutorialViewController.h"
#import "HMUploadManager.h"
#import "Mixpanel.h"
#import <AudioToolbox/AudioServices.h>
#import "HMMotionDetector.h"
#import "HMServer+AppConfig.h"
#import "HMServer+LazyLoading.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HMServer+Footages.h"
#import "HMCacheManager.h"
#import "HMMainGUIProtocol.h"
#import "HMABTester.h"
#import "HMAppDelegate.h"
#import "HMServer+AppConfig.h"
#import "HMExtractController.h"
#import "HMRecorderDetailedOptionsBarViewController.h"

@interface HMRecorderViewController () <UIAlertViewDelegate>

// IB outlets

// Child interfaces containers (overlay, messages, detailed options/action bar etc).
@property (weak, nonatomic) IBOutlet UIView *guiCameraContainer;
@property (weak, nonatomic) IBOutlet UIView *guiDetailedOptionsBarContainer;
@property (weak, nonatomic) IBOutlet UIView *guiWhileRecordingOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiTextsEditingContainer;
@property (weak, nonatomic) IBOutlet UIView *guiMessagesOverlayContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiSceneDirectionButton;
@property (weak, nonatomic) IBOutlet UIView *guiSceneDirectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiBackgroundStatusButton;
@property (weak, nonatomic) IBOutlet UIView *guiHelperScreenContainer;

// Silhouette background image
@property (weak, nonatomic) IBOutlet UIImageView *guiSilhouetteImageView;

// Top recorder buttons
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;
@property (weak, nonatomic) IBOutlet UIButton *guiCameraSwitchingButton;

// Top script view
@property (weak, nonatomic) IBOutlet UIView *guiTopScriptView;
@property (weak, nonatomic) IBOutlet UILabel *guiScriptLabel;

// AB tests
@property (weak, nonatomic) HMABTester *abTester;

// Weak pointers to child view controllers
@property (weak, nonatomic, readonly) HMRecorderMessagesOverlayViewController *messagesOverlayVC;
@property (weak, nonatomic, readonly) HMRecorderEditTextsViewController *editingTextsVC;
@property (weak, nonatomic, readonly) HMRecorderTutorialViewController *tutorialVC;
@property (weak, nonatomic, readonly) HMVideoCameraViewController *videoCameraVC;
@property (weak, nonatomic, readonly) HMRecorderDetailedOptionsBarViewController *optionsBarVC;

// UI State
@property (nonatomic, readonly) BOOL detailedOptionsOpened;
@property (nonatomic, readonly) HMRecorderState recorderState;
@property (nonatomic) double startPanningY;
@property (nonatomic, readonly) BOOL lockedAutoRotation;
@property (nonatomic, readonly) BOOL frontCameraAllowed;
@property (nonatomic, readonly) NSUInteger allowedOrientations;
@property (nonatomic) BOOL flagForDebugging;
@property (nonatomic) BOOL stopRecordingFired;
@property (nonatomic) BOOL isSelfie;

// scene direction audio player
@property (strong,nonatomic) AVAudioPlayer *directionAudioPlayer;

// Some physics animations
@property (nonatomic, readonly) UIDynamicAnimator *animator;

//THE HAND!!!
@property (nonatomic,readwrite) BOOL showHand;

// Good and bad backgrounds
@property (nonatomic) NSInteger backgroundStatusCounter;
@property (nonatomic) BOOL      backgroundAlertDisplaying;
@property (nonatomic) BOOL      isBadBackgroundWarningOn;
@property (nonatomic) HMBadBackgroundPolicy badBackgroundPolicy;
@property (nonatomic) NSDictionary *badBackgroundTextsMappings;
@property (nonatomic) NSDictionary *badBackgroundIconsMappings;
@property (nonatomic) NSInteger lastBadBackgroundMark;
@property (nonatomic) NSMutableDictionary *usedBadBackgroundMarks;

// Preloading
@property (nonatomic) NSMutableArray *preloadedImageViews;

@end

@implementation HMRecorderViewController

@synthesize remake = _remake;
@synthesize currentSceneID = _currentSceneID;

#define GOOD_BACKGROUND_TH   3
#define BAD_BACKGROUND_TH   -2
#define BAD_BACKGROUND_PRESENT_POPUP_TH -15

+(HMRecorderViewController *)recorderForRemake:(Remake *)remake
{
    if (![remake isKindOfClass:[Remake class]]) return nil;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"RecorderStoryboard" bundle:nil];
    HMRecorderViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Recorder"];
    vc.remake = remake;
    return vc;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.usedBadBackgroundMarks = [NSMutableDictionary new];
    
    HMGLogInfo(@"Opened recorder for remake:%@ story:%@",self.remake.sID, self.remake.story.name);
    [[Mixpanel sharedInstance] track:@"REEnterRecorder" properties:@{@"remakeID" : self.remake.sID , @"story" : self.remake.story.name}];
    
    // Cache manager, stop downloads.
    [HMCacheManager.sh pauseDownloads];
    
    // Status bar should be hidden.
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Background detection.
    [self postEnableBGDetectionNotification];
    
    // Initalize AB Testing
    [self initABTesting];
    
    
    // More initializations.
    [self initRemakerState];
    [self initOptions];
    [self initGUI];
    [self initBadBackgroundsPolicy];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initObservers];
    [self.videoCameraVC attachCameraIO];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self fixLayout];
    [self.optionsBarVC checkMicrophoneAuthorization];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopSceneDirectionAudioPlayback]; // Stop if playing. Nothing otherwise.
    [self.videoCameraVC releaseCameraIO];
}

-(void)dealloc
{
    HMGLogInfo(@"Recorder deallocated successfully for remakeID:%@", self.remake.sID);
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - AB Testing
-(void)initABTesting
{
    // AB Tester
    HMAppDelegate *app = [[UIApplication sharedApplication] delegate];
    self.abTester = app.abTester;
    
    // Defaults
    self.badBackgroundPolicy = HMBadBackgroundPolicyTolerant;
    
    // If should force a policy, skip this AB Test
    // (used for debugging. Shouldn't happen on a release build)
    NSNumber *forcedPolicy = HMServer.sh.configurationInfo[@"recorder_forced_bbg_policy"];
    if (forcedPolicy) {
        self.badBackgroundPolicy = [forcedPolicy integerValue];
        return;
    }
    
    // Report about entering the recorder, if relevant test requires.
    if ([self.abTester isABTestingProject:AB_PROJECT_RECORDER_BAD_BACKGROUNDS] ||
        [self.abTester isABTestingProject:AB_PROJECT_RECORDER_ICONS]) {
        // We care about reporting a view of the recorder, only if
        // the recorder interface provided a variant.
        [self.abTester reportEventType:@"enteredRecorder"];
    }

    // An ab test with variance on the bad background policy.
    if ([self.abTester isABTestingProject:AB_PROJECT_RECORDER_BAD_BACKGROUNDS]) {
        // Bad background policy chosen by ab test.
        self.badBackgroundPolicy = [self.abTester integerValueForProject:AB_PROJECT_RECORDER_BAD_BACKGROUNDS
                                                            varName:@"badBackgroundStrictPolicy"
                                              hardCodedDefaultValue:self.badBackgroundPolicy];
    }
}

-(void)initBadBackgroundsPolicy
{
    self.lastBadBackgroundMark = BBG_MARK_UNRECOGNIZED;
    
    self.badBackgroundTextsMappings = @{
                                        @(BBG_MARK_NOISY):@"RECORDER_BBG_NOISY",
                                        @(BBG_MARK_DARK):@"RECORDER_BBG_DARK",
                                        @(BBG_MARK_SILHOUETTE):@"RECORDER_BBG_SILHOUETTE",
                                        @(BBG_MARK_SHADOW):@"RECORDER_BBG_SHADOW",
                                        @(BBG_MARK_CLOTH):@"RECORDER_BBG_CLOTH",
                                        @(BBG_MARK_UNRECOGNIZED):@"RECORDER_BBG_GENERAL_MESSAGE",
                                        };
}

#pragma mark - UI initializations
-(void)initGUI
{
    // Getting the landscape width of the device
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat screenLandscapeWidth = screenSize.width > screenSize.height ? screenSize.width : screenSize.height;
    CGFloat screenLandscapeHeight = screenSize.height < screenSize.width ? screenSize.height : screenSize.width;
    
    // Width and height for 16:9 aspect ratio
    CGFloat ratio_16_9_width = screenLandscapeWidth;
    CGFloat ratio_16_9_height = ratio_16_9_width / (16.0f / 9.0f);
    CGSize ratio_16_9 = CGSizeMake(ratio_16_9_width, ratio_16_9_height);
    
    // Point for 16:9 ratio in a way that the view will be in the center of the screen
    CGFloat ratio_16_9_x = 0.0f;
    CGFloat ratio_16_9_y = (screenLandscapeHeight - ratio_16_9_height) / 2.0f; // 0.0f
    
    CGRect ratio_16_9_rect = CGRectMake(ratio_16_9_x, ratio_16_9_y, ratio_16_9_width, ratio_16_9_height);
    
    // Updating the size of the silhouette image view to be in a 16:9 ratio
    CGRect silhouetteImageViewBounds = self.guiSilhouetteImageView.bounds;
    silhouetteImageViewBounds.size = ratio_16_9;
    self.guiSilhouetteImageView.bounds = silhouetteImageViewBounds;
    //self.guiSilhouetteImageView.frame = ratio_16_9_rect;
    //self.guiSilhouetteImageView.autoresizingMask = UIViewAutoresizingNone;
    
    // Updating the camera preview frame to be in a 16:9 ratio
    CGRect cameraPreviewFrame = ratio_16_9_rect;
    self.videoCameraVC.previewView.superview.frame = cameraPreviewFrame;
    self.videoCameraVC.previewView.superview.autoresizingMask = UIViewAutoresizingNone;

    [self loadSilhouettes];
    
    self.backgroundStatusCounter = 0;
    self.guiBackgroundStatusButton.alpha = 0;
    self.isBadBackgroundWarningOn = NO;
    
    // Drawer
    self.guiDetailedOptionsBarContainer.layer.shouldRasterize = NO;
    
    // iPad specific
    if (IS_IPAD) {
        CGPoint p = self.guiDetailedOptionsBarContainer.center;
        p.y += 452;
        self.guiDetailedOptionsBarContainer.center = p;
    }
}

-(void)fixLayout
{
    CGPoint p;
    if (IS_IPAD) {
        p = CGPointMake(556, 719);
    } else if (IS_IPHONE_5 || IS_16_9_LANDSCAPE) {
        p = CGPointMake(328, 267);
    } else {
        p = CGPointMake(283, 267);
    }
    self.guiBackgroundStatusButton.center = p;
}

#pragma mark - Recorder state flow
-(void)initRemakerState
{
    // Critical error if remake doesn't exist in local storage!
    if (!self.remake) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"CRITICAL_ERROR")
                                                        message:LS(@"Recorder missing reference to a 'REMAKE'.")
                                                       delegate:nil
                                              cancelButtonTitle:LS(@"OK")
                                              otherButtonTitles:nil
                              ];
        [alert show];
    }
    
    // Currently edited scene
    
    // If all scenes were already retaken, will start at the "Nailed all scenes" screen.
    if (self.remake.allScenesTaken) {
        _currentSceneID = [self.remake lastSceneID];
        [self updateUIForSceneID:self.currentSceneID];
        [self showFinishedAllScenesMessage];
        return;
    }
    
    // In all other cases, will just start at the "Just started" state.
    _recorderState = HMRecorderStateJustStarted;
    [self advanceState];
}

-(void)advanceState
{
    //
    // The flow state machine.
    // Moves to next stage according to current state.
    //
    
    // -----------------------------------------
    // DEPRECATED the general message screen.
    // Will start with the tutorial screens (or just go straight to making a scene)
    // if (self.recorderState == HMRecorderStateJustStarted) {
    // 0 - HMRecorderStateJustStarted --> 1 - HMRecorderStateGeneralMessage
    // [self stateShowGeneralIntroStateIfNeeded];
    // -----------------------------------------
    if (self.recorderState == HMRecorderStateJustStarted) {
        
        // Initialize the state of the recorder
        // (it may start at the first scene, or later scene if
        // this is remake in progress).
        [self stateJustStartedSoInitialize];
        
    } else if (self.recorderState == HMRecorderStateInitialized) {
        
        BOOL debugAlwaysSkipHelpScreens = NO; // Set to NO or remove this for correct behavior.
        BOOL debugAlwaysShowHelpScreens = NO;  // Set to NO or remove this for correct behavior.
        
        if (debugAlwaysShowHelpScreens) {
            [self stateShowHelpScreens];
            return;
        }
        
        // 1 - HMRecorderStateGeneralMessage --> 2 - HMRecorderStateSceneContextMessage (if user already seen tutorials)
        // OR
        // 1 - HMRecorderStateGeneralMessage --> 8 - HMRecorderStateHelpScreens
        User *user = [User current];
        if (user.skipRecorderTutorial || debugAlwaysSkipHelpScreens) {
            if ([HMServer.sh shouldShowFirstSceneContextMessage]) {
                // Show a context message for the first scene.
                [self stateShowContextForNextScene];
            } else {
                // Some apps are configured not to show the context message for the first scene.
                [self stateMakingAScene];
            }
        } else {
            // Showing the help/tutorial screens.
            [self stateShowHelpScreens];
        }
        
    } else if (self.recorderState == HMRecorderStateHelpScreens) {
        
        // 8 - HMRecorderStateHelpScreens --> 2 - HMRecorderStateSceneContextMessage
        [self stateShowContextForNextScene];
        
    } else if (self.recorderState == HMRecorderStateSceneContextMessage) {
        
        // 2 - HMRecorderStateSceneContextMessage --> 3 - HMRecorderStateMakingAScene
        [self stateMakingAScene];
        
    } else if (self.recorderState == HMRecorderStateMakingAScene) {
        
        // 3 - HMRecorderStateMakingAScene -->
        // --> 4 - HMRecorderStateFinishedASceneMessage  or
        // or
        // --> 5 - HMRecorderStateEditingTexts
        // or
        // --> 6 - HMRecorderStateFinishedAllScenesMessage
        [self stateFinishedMakingASceneAndCheckingWhatsNext];
        
    } else if (self.recorderState == HMRecorderStateFinishedASceneMessage) {
        
        // 4 - HMRecorderStateFinishedASceneMessage --> going to next scene --> 3 - HMRecorderStateMakingAScene
        [self stateMakingNextScene];
        
    } else if (self.recorderState == HMRecorderStateEditingTexts) {
        
        // 5 - HMRecorderStateEditingTexts --> edited all texts --> 6 - HMRecorderStateFinishedAllScenesMessage
        // or
        // 5 - HMRecorderStateEditingTexts --> not all texts edited --> 3 - HMRecorderStateMakingAScene
        
        // Nothing to do here. The editing texts screen will decide on the next state.
        
    } else if (self.recorderState == HMRecorderStateFinishedAllScenesMessage) {
        
        // 6 - HMRecorderStateFinishedAllScenesMessage --> create movie request success --> Done!
        // or
        // 6 - HMRecorderStateFinishedAllScenesMessage --> 3 - HMRecorderStateMakingAScene
        [self stateDoneIfUserRequestToCreateMovieIsASuccess];

    } else if (self.recorderState == HMRecorderStateUserRequestToCheckWhatNext) {
        // 7 - HMRecorderStateUserRequestToCheckWhatNext --> ?
        [self stateFinishedMakingASceneAndCheckingWhatsNext];
    }
}

//-(void)stateShowGeneralIntroStateIfNeeded
//{
//    // HMRecorderStateJustStarted --> HMRecorderStateGeneralMessage
//    
//    //
//    // Select the first scene requiring a first retake.
//    // If none found (all footages already taken by the user),
//    // will select the last scene for this remake instead.
//    //
//    _currentSceneID = [self.remake nextReadyForFirstRetakeSceneID];
//    if (!self.currentSceneID)
//    {
//       _currentSceneID = [self.remake lastSceneID];
//    }
//    [self updateUIForSceneID:self.currentSceneID];
//    
//    // Just started. Show general message.
//    // But if user chosen not to show that message, skip it.
//    _recorderState = HMRecorderStateGeneralMessage;
//    if ([User.current.skipRecorderTutorial isEqualToNumber:@YES]) {
//        // Skip to next state without showing the general message.
//        [self advanceState];
//    } else {
//        [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeGeneral checkNextStateOnDismiss:YES info:nil];
//    }
//    
//}

-(void)stateJustStartedSoInitialize
{
    // HMRecorderStateJustStarted --> HMRecorderStateInitialized
    
    //
    // Select the first scene requiring a first retake.
    // If none found (all footages already taken by the user),
    // will select the last scene for this remake instead.
    //
    _currentSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    if (!self.currentSceneID)
    {
        _currentSceneID = [self.remake lastSceneID];
    }
    [self updateUIForSceneID:self.currentSceneID];
    
    // Initialized after starting.
    // Advance to next state.
    _recorderState = HMRecorderStateInitialized;
    [self advanceState];
}

-(void)stateShowContextForNextScene
{
    // HMRecorderStateGeneralMessage --> HMRecorderStateSceneContextMessage
    
    //
    // Showing context for the next scene needing a first retake.
    //
    _recorderState = HMRecorderStateSceneContextMessage;
    [self showSceneContextMessageForSceneID:self.currentSceneID checkNextStateOnDismiss:YES info:nil];
}

-(void)stateShowHelpScreens
{
    _recorderState = HMRecorderStateHelpScreens;
    self.guiHelperScreenContainer.hidden = NO;
    [self postDisableBGdetectionNotification];
    self.guiHelperScreenContainer.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiHelperScreenContainer.alpha = 1;
    } completion:^(BOOL finished) {
        [self.tutorialVC start];
    }];
}

-(void)stateMakingAScene
{
    // HMRecorderStateSceneContextMessage || HMRecorderStateFinishedASceneMessage --> HMRecorderStateMakingAScene
    
    //
    // Making a scene :-)
    //
    _recorderState = HMRecorderStateMakingAScene;
    [self updateUIForCurrentScene];
    [self closeDetailedOptionsAnimated:YES];
    self.guiTextsEditingContainer.hidden = YES;
    
    // Some scenes play scene direction as audio
    Scene *scene = [self.remake.story findSceneWithID:self.currentSceneID];
    if (scene.directionAudioURL) {
        [self startSceneDirectionAudioPlayback];
    }
    
    // Now the user has control of the flow...
}

-(void)stateFinishedMakingASceneAndCheckingWhatsNext
{
    NSNumber *nextSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    if (!nextSceneID) {
        // All scenes retaken by the user (at least once).
        // Will check if needs to edit texts or just show the finish message.
        
        // --> HMRecorderStateEditingTexts
        if (self.remake.textsShouldBeEntered) {
            _recorderState = HMRecorderStateEditingTexts;
            [self showEditingTextsScreen];
            return;
        }

        //  --> HMRecorderStateFinishedAllScenesMessage
        _recorderState = HMRecorderStateFinishedAllScenesMessage;
        [self showFinishedAllScenesMessage];
        [self updateUIForCurrentScene];
        return;
        
    }
    
    //  --> HMRecorderStateFinishedASceneMessage
    
    // Showing "finished a scene" message.
    // And change to the next scene.
    [self showFinishedSceneMessageForSceneID:self.currentSceneID checkNextStateOnDismiss:YES];
    [self updateUIForCurrentScene];
    _recorderState = HMRecorderStateFinishedASceneMessage;
}

-(void)stateMakingNextScene
{
    _currentSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    [self stateMakingAScene];
}

//-(void)stateEditingTexts
//{
//    // TODO: implement
//}

-(void)stateDoneIfUserRequestToCreateMovieIsASuccess
{
//    if (self.remake.status.integerValue > HMGRemakeStatusNew) {
//        [self dismissWithReason:HMRecorderDismissReasonFinishedRemake];
//        return;
//    }
    [self stateMakingNextScene];
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addUniqueObserver:self
                 selector:@selector(onContourFileDownloaded:)
                     name:HM_NOTIFICATION_SERVER_CONTOUR_FILE_RECIEVED
                   object:nil];
    
    
    
    //
    // Back Camera selected
    //
    [nc addUniqueObserver:self
                 selector:@selector(onBackCameraSelected:)
                     name:HM_NOTIFICATION_RECORDER_USING_BACK_CAMERA
                   object:nil];
    
    //
    // Front Camera selected
    //
    [nc addUniqueObserver:self
                 selector:@selector(onFrontCameraSelected:)
                     name:HM_NOTIFICATION_RECORDER_USING_FRONT_CAMERA
                   object:nil];
    
    // Observe user pressing the record button (start counting down to recording)
    [nc addUniqueObserver:self
                 selector:@selector(onStartedCountingDownToRecording:)
                     name:HM_NOTIFICATION_RECORDER_START_COUNTDOWN_BEFORE_RECORDING
                   object:nil];
    
    // Observe started recording
    [nc addUniqueObserver:self
                 selector:@selector(onStartRecording:)
                     name:HM_NOTIFICATION_RECORDER_START_RECORDING
                   object:nil];
    
    // Observe stop recording
    [nc addUniqueObserver:self
                 selector:@selector(onStopRecording:)
                     name:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                   object:nil];
    
    // Observe raw user's take file is available and
    // needs to be added to the related Footage object in local storage
    [nc addUniqueObserver:self
                 selector:@selector(onNewRawFootageFileAvailable:)
                     name:HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE
                   object:nil];
    
    // Handle recording errors by showing the FAIL message
    [nc addUniqueObserver:self
                 selector:@selector(onRecorderEpicFail:)
                     name:HM_NOTIFICATION_RECORDER_EPIC_FAIL
                   object:nil];
    
    // Observe telling server to render
    [nc addUniqueObserver:self
                 selector:@selector(onRender:)
                     name:HM_NOTIFICATION_SERVER_RENDER
                   object:nil];
    
    //observe camera movment
    [nc addUniqueObserver:self
                 selector:@selector(onCameraNotStable:)
                     name:HM_NOTIFICATION_CAMERA_NOT_STABLE
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(onBadBackgroundDetected:)
                     name:HM_CAMERA_BAD_BACKGROUND
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(onGoodBackgroundDetected:)
                     name:HM_CAMERA_GOOD_BACKGROUND
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(onAppMovedToBackground:)
                     name:HM_APP_WILL_RESIGN_ACTIVE
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(onAppDidEnterForeground:)
                     name:HM_APP_WILL_ENTER_FOREGROUND
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(onPressedLockedRecordButton:)
                     name:HM_NOTIFICATION_RECORDER_PRESSING_LOCKED_RECORD_BUTTON
                   object:nil];
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_CONTOUR_FILE_RECIEVED object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_USING_BACK_CAMERA object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_USING_FRONT_CAMERA object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_COUNTDOWN_BEFORE_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_EPIC_FAIL object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_RENDER object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_CAMERA_NOT_STABLE object:nil];
    [nc removeObserver:self name:HM_CAMERA_BAD_BACKGROUND object:nil];
    [nc removeObserver:self name:HM_CAMERA_GOOD_BACKGROUND object:nil];
    [nc removeObserver:self name:HM_APP_WILL_RESIGN_ACTIVE object:nil];
    [nc removeObserver:self name:HM_APP_WILL_ENTER_FOREGROUND object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_PRESSING_LOCKED_RECORD_BUTTON object:nil];
}

#pragma mark - Observers handlers
-(void)onPressedLockedRecordButton:(NSNotification *)notification
{
    [self presentBadBackgroundAlert];
}

-(void)onStartedCountingDownToRecording:(NSNotification *)notification
{
    if (self.directionAudioPlayer) [self stopSceneDirectionAudioPlayback];
}

-(void)onBackCameraSelected:(NSNotification *)notification
{
    HMGLogDebug(@"Back camera selected");
    self.isSelfie = NO;
    [self updateUIForSceneID:self.currentSceneID];
}

-(void)onFrontCameraSelected:(NSNotification *)notification
{
    HMGLogDebug(@"Front camera selected");
    self.isSelfie = YES;
    [self updateUIForSceneID:self.currentSceneID];
}

-(void)onContourFileDownloaded:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *localURL = info[@"local_URL"];
    NSString *remoteURL = info[@"remote_URL"];
    
    Contour *contour = [Contour ContourWitRemoteURL:remoteURL inContext:DB.sh.context];
    Scene *scene = [Scene sceneWithID:info[@"sceneID"] story:self.remake.story inContext:DB.sh.context];
    contour.localURL = localURL;
    
    if (notification.isReportingError || !localURL)
    {
        scene.contourLocalURL = nil;
    } else
    {
        scene.contourLocalURL = contour.localURL;
    }
    
    if (scene.contourLocalURL && scene.sID == self.currentSceneID)
    {
        [_videoCameraVC updateContour:scene.contourLocalURL];
    }

}

-(void)onStartRecording:(NSNotification *)notification
{
    _lockedAutoRotation = YES;
    _stopRecordingFired = NO;
    
    Footage *footage = [self.remake footageWithSceneID:self.currentSceneID];
    NSString *remakeID = self.remake.sID? self.remake.sID:@"unknown";
    NSString *storyName = self.remake.story.name? self.remake.story.name:@"unknown";
    NSNumber *sceneID = self.currentSceneID? self.currentSceneID:@0;
    NSNumber *badBGDisplaying = [NSNumber numberWithBool:self.backgroundAlertDisplaying];
    
    NSDictionary *info = @{
                           @"remake_id": remakeID,
                           @"story": storyName,
                           @"scene_id": sceneID
                           };
    
    if (self.backgroundAlertDisplaying) {
        
        // Report about shooting the scene with bad background.
        [[Mixpanel sharedInstance] track:@"REShootSceneWithBadBackground" properties:info];
        [self.abTester reportEventType:@"shootSceneWithBadBackground"];
        footage.shotWithBadBG = @YES;
        
    } else {
        
        // Shooting the scene with good background.
        [[Mixpanel sharedInstance] track:@"REShootSceneWithGoodBackground" properties:info];
        [self.abTester reportEventType:@"shootSceneWithGoodBackground"];
        footage.shotWithBadBG = @NO;
        
    }
    
    [[Mixpanel sharedInstance] track:@"REStartRecording" properties:@{
                                                                      @"bad_background": badBGDisplaying,
                                                                      @"remake_id": remakeID,
                                                                      @"story": storyName,
                                                                      @"scene_id": sceneID
                                                                      }];
    
    [self presentRecordingUI];
}

-(void)presentRecordingUI
{
    [self hideDetailsOptionsAnimated:YES];

    self.guiDismissButton.enabled = NO;
    self.guiCameraSwitchingButton.enabled = NO;
    self.guiSceneDirectionButton.enabled = NO;

    self.guiWhileRecordingOverlay.hidden = NO;
    self.guiWhileRecordingOverlay.alpha = 0;
    self.guiBackgroundStatusButton.hidden = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        
        // Fade out silhouette image
        self.guiSilhouetteImageView.alpha = 0;
        self.guiSilhouetteImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        
        // Fade out unwanted buttons
        self.guiCameraSwitchingButton.alpha = 0;
        self.guiDismissButton.alpha = 0;
        self.guiSceneDirectionButtonContainer.alpha = 0;
        
        // Fade in "while recording" controls.
        self.guiWhileRecordingOverlay.alpha = 1;
        self.guiWhileRecordingOverlay.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        if (_stopRecordingFired)
        {
            [self presentRecorderIdleUI];
        } else {
            self.guiSilhouetteImageView.hidden = YES;
            self.guiDetailedOptionsBarContainer.hidden = YES;
            self.guiWhileRecordingOverlay.hidden = NO;
        }
        
    }];
}

-(void)onStopRecording:(NSNotification *)notification
{
    _lockedAutoRotation = NO;
    _stopRecordingFired = YES;
    HMRecordingStopReason stoppedReason = [notification.userInfo[HM_INFO_KEY_RECORDING_STOP_REASON] integerValue];
    if (stoppedReason == HMRecordingStopReasonEndedSuccessfully) {
        [HMMotionDetector.sh stopWithNotification:NO];
    } else if (stoppedReason == HMRecordingStopReasonCameraNotStable) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeSceneContext
                           checkNextStateOnDismiss:NO
                                              info:@{
                                                     @"icon name":@"iconEpicFail",
                                                     @"title":LS(@"CAMERA_NOT_STABLE_TITLE"),
                                                     @"text":LS(@"CAMERA_NOT_STABLE"),
                                                     @"ok button text":LS(@"OK_GOT_IT"),
                                                     }
         ];
        [self presentRecorderIdleUI];
    
    } else {
        [self presentRecorderIdleUI];
    }
}

-(void)presentRecorderIdleUI
{
    self.guiSilhouetteImageView.hidden = NO;
    self.guiSilhouetteImageView.transform = CGAffineTransformIdentity;
    [self closeDetailedOptionsAnimated:NO];
    
    self.guiDismissButton.enabled = YES;
    self.guiDismissButton.hidden = NO;
    self.guiCameraSwitchingButton.enabled = YES;
    self.guiCameraSwitchingButton.hidden = !self.frontCameraAllowed;

    self.guiSceneDirectionButton.enabled = YES;
    self.guiSceneDirectionButtonContainer.hidden = NO;
    
    self.guiBackgroundStatusButton.enabled = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        
        // Fade in silhouette image
        self.guiSilhouetteImageView.alpha = self.guiSilhouetteImageView.image ? SILHOUETTE_HARD_CODED_ALPHA : 0;
        
        // Fade in buttons
        self.guiDismissButton.alpha = 1;
        self.guiCameraSwitchingButton.alpha = 1;
        self.guiSceneDirectionButtonContainer.alpha = 1;
        
        // Fade out "while recording" controls.
        self.guiWhileRecordingOverlay.alpha = 0;
        
    } completion:^(BOOL finished) {
        self.guiWhileRecordingOverlay.hidden = YES;
    }];
}

-(void)onNewRawFootageFileAvailable:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *remakeID = info[@"remakeID"];
    NSString *rawMoviePath = info[@"rawMoviePath"];
    NSNumber *sceneID = info[@"sceneID"];
    BOOL isSelfie = [info[@"isSelfie"] boolValue];
    
    if (!sceneID)
    {
        HMGLogError(@"sceneID is missing");
    }
    
    if (![remakeID isEqualToString:self.remake.sID]) {
        // If happens, something went wrong is the timing. Maybe a leak of an old recorder?
        HMGLogError(@"Why is the remake ID (%@) on onNewRawFootageFileAvailable different than the current one? (%@)", remakeID, self.remake.sID);
        return;
    }
    
    Footage *footage = [self.remake footageWithSceneID:sceneID];
    if (footage.rawLocalFile) [footage deleteRawLocalFile];
    footage.rawLocalFile = rawMoviePath;
    footage.rawIsSelfie = @(isSelfie);
    [DB.sh save];

    // If uploader is currently uploading a file for this footage, cancel the upload (it is irelevant, a newer file is available).
    [HMUploadManager.sh cancelUploadForFootage:footage];
    
    // Tell the uploader to check for needed uploads. Give this footage, with the new rawLocalFile, priority.
    // Do this after waiting for 5 seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [HMUploadManager.sh checkForUploadsWithPrioritizedFootages:@[footage]];        
    });

    // Move along to the next state.
    [self presentRecorderIdleUI];
    [self advanceState];
}

-(void)onRecorderEpicFail:(NSNotification *)notification
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeSceneContext
                       checkNextStateOnDismiss:NO
                                          info:@{
                                                 @"icon name":@"iconEpicFail",
                                                 @"title":LS(@"EPIC_FAIL_TITLE"),
                                                 @"text":LS(@"EPIC_FAIL_MESSAGE"),
                                                 @"ok button text":LS(@"OK_GOT_IT"),
                                                 }];
    [self presentRecorderIdleUI];
}

-(void)onRender:(NSNotification *)notification
{
    if (notification.isReportingError) {
        // TODO: Epic fail
        HMGLogError(@"Epic fail");
        return;
    }
    self.guiTextsEditingContainer.hidden = YES;
    [self dismissWithReason:HMRecorderDismissReasonFinishedRemake];

    if ([self.abTester isABTestingProject:AB_PROJECT_RECORDER_BAD_BACKGROUNDS]) {
        // Finished remake flow event.
        [self.abTester reportEventType:@"finishedRemakeFlow"];
        
        // Finished remake flow event, report about bg quality.
        HMGRemakeBGQuality quality = [self.remake footagesBGQuality];
        switch (quality) {
            case HMGRemakeBGQualityGood:
                [self.abTester reportEventType:@"finishedAllGoodBGRemakeFlow"];
                break;
            case HMGRemakeBGQualityOK:
                [self.abTester reportEventType:@"finishedSomeOKBGRemakeFlow"];
                break;
            case HMGRemakeBGQualityBad:
                [self.abTester reportEventType:@"finishedAllBadBGRemakeFlow"];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Scenes selection
-(void)updateUIForSceneID:(NSNumber *)sceneID
{
    if (!sceneID)
    {
      sceneID = [self.remake lastSceneID];
    }
    
    Scene *scene = [self.remake.story findSceneWithID:sceneID];
    
    if (scene.isSelfie.boolValue && [HMVideoCameraViewController canFlipToFrontCamera]) {
        _frontCameraAllowed = YES;
    } else {
        _frontCameraAllowed = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_FLIP_CAMERA object:self userInfo:@{@"forceCameraSelection":@"front"}];
    }
    self.guiCameraSwitchingButton.hidden = !self.frontCameraAllowed;
    
    // Notify all child interfaces about the current scene ID.
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_CURRENT_SCENE object:nil userInfo:@{@"sceneID":sceneID}];

    // Show silhouete of the related scene (or lazy load it).
    [self silhouetteForScene:scene flipped:self.isSelfie];
    
    //update video camera controller with proper contour file
    NSString *contourFileLocalURL = [self contourFileForScene:scene];
    if (contourFileLocalURL) [_videoCameraVC updateContour:contourFileLocalURL];
    
    if (scene.script && scene.script.length>0) {
        self.guiScriptLabel.text = scene.script;
    } else {
        self.guiScriptLabel.text = @"";
    }
}

-(void)loadSilhouettes
{
    if (!self.preloadedImageViews) self.preloadedImageViews = [NSMutableArray new];
    for (Scene *scene in self.remake.story.scenes) {
        NSURL *url = [NSURL URLWithString:scene.silhouetteURL];
        [self preloadImageViewAtURL:url];
    }
}

-(void)preloadImageViewAtURL:(NSURL *)url
{
    UIImageView *imageView = [UIImageView new];
    imageView.hidden = YES;
    NSInteger i = self.preloadedImageViews.count;
    imageView.frame = CGRectMake(i * 50, 0, 50, 50);
    [self.preloadedImageViews addObject:imageView];
    [self.view addSubview:imageView];
    [imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed|SDWebImageHighPriority completed:nil];
    HMGLogDebug(@"Preloading silhoutte at url:%@", url);
}

-(void)loadContours
{
   for (Scene *scene in self.remake.story.scenes)
   {
       [self contourFileForScene:scene];
   }
}

#pragma mark - Lazy loading
-(UIImage *)silhouetteForScene:(Scene *)scene flipped:(BOOL)flipped
{
    self.guiSilhouetteImageView.alpha = 0;
    NSURL *thumbURL = [NSURL URLWithString:scene.silhouetteURL];
    [self.guiSilhouetteImageView sd_setImageWithURL:thumbURL placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        self.guiSilhouetteImageView.image = image;
        if (cacheType == SDImageCacheTypeNone) {
            // Reveal with animation
            [UIView animateWithDuration:0.7 animations:^{
                self.guiSilhouetteImageView.alpha = SILHOUETTE_HARD_CODED_ALPHA;
                self.guiSilhouetteImageView.hidden = NO;
                self.guiSilhouetteImageView.transform = CGAffineTransformIdentity;
            }];
        } else {
            // Reveal with no animation.
            self.guiSilhouetteImageView.alpha = SILHOUETTE_HARD_CODED_ALPHA;
            self.guiSilhouetteImageView.hidden = NO;
            self.guiSilhouetteImageView.transform = CGAffineTransformIdentity;
        }
    }];
    
    return nil;
}

-(UIImage *)flippedImageOfImage:(UIImage *)sourceImage
{
    UIImage* flippedImage = [UIImage imageWithCGImage:sourceImage.CGImage
                                                scale:sourceImage.scale
                                          orientation:UIImageOrientationUpMirrored];
    return flippedImage;
}

-(NSString *)contourFileForScene:(Scene *)scene
{
    NSString *contourURL = scene.contourRemoteURL;
    HMGLogDebug(@"scene remote url is: %@" , contourURL);
    if (!contourURL)
    {
        HMGLogError(@"contour url came back empty. check why");
        return nil;
    }
    
    Contour *contour = [Contour findWithRemoteURL:contourURL inContext: DB.sh.context];
    
    if (contour && [[NSFileManager defaultManager] fileExistsAtPath:contour.localURL])
    {
        return contour.localURL;
    } else
    {
        [HMServer.sh downloadFileFromURL:contourURL notificationName:HM_NOTIFICATION_SERVER_CONTOUR_FILE_RECIEVED info:@{@"sceneID":scene.sID}];
        return nil;
    }
}

#pragma mark - Orientations
-(BOOL)shouldAutorotate
{
    //return !self.lockedAutoRotation;
    return NO;
}


-(NSUInteger)supportedInterfaceOrientations
{
//    // Lock orientation on iOS8 for now (because willRotateToInterfaceOrientation was deprecated)
//    if ([self respondsToSelector:@selector(willTransitionToTraitCollection:withTransitionCoordinator:)]){
//        return UIInterfaceOrientationMaskLandscapeRight;
//    }
//    
//    // iOS7
//    return UIInterfaceOrientationMaskLandscape;
    
    // Locking orientation to all iOS versions starting 1.9.x
    return UIInterfaceOrientationMaskLandscapeRight;
}


//
// Bacward compatability: Oritentation support for iOS7
//
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.videoCameraVC cameraWillRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

//
// Backward compatability: Orientation support for iOS7
//
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.videoCameraVC cameraDidRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

//-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//}
//-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//}

#pragma mark - containment segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    id<HMRecorderChildInterface> vc = segue.destinationViewController;
    if ([vc conformsToProtocol:@protocol(HMRecorderChildInterface)]) {
        [vc setRemakerDelegate:self];
    }
    
    // Specific destination view controllers
    if ([segue.identifier isEqualToString:@"messages overlay containment segue"]) {
        _messagesOverlayVC = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"editing texts segue"]) {
        _editingTextsVC = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"tutorial screen segue"]) {
        _tutorialVC = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"video camera containment segue"]) {
        _videoCameraVC = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"recorder detailed options bar containment segue"]) {
        _optionsBarVC = segue.destinationViewController;
    }
}

// Used for debugging
//-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
//{
//    NSArray *allowSegueTo = @[
//                              @"while recording overlay containment segue",
//                              @"video camera containment segue",
//                              @"messages overlay containment segue",
//                              @"recorder detailed options bar containment segue",
//                              ];
//    for (NSString *s in allowSegueTo) if ([s isEqualToString:identifier]) return YES;
//    return NO;
//}

#pragma mark - Remaker protocol
-(void)dismissOverlay
{
    [self dismissOverlayAdvancingState:NO info:nil];
}

-(void)dismissOverlayAdvancingState:(BOOL)advancingState
{
    [self dismissOverlayAdvancingState:advancingState info:nil];
}

-(void)dismissOverlayAdvancingState:(BOOL)advancingState info:(NSDictionary *)info
{
    CGAffineTransform defaultTransform = CGAffineTransformMakeScale(1.4, 0);
    
    if (info[@"dismissing help screen"]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.guiHelperScreenContainer.alpha = 0;
        } completion:^(BOOL finished) {
            self.guiHelperScreenContainer.hidden = YES;
            [self postEnableBGDetectionNotification];
            // Check the recorder state and advance it if needed.
            if (advancingState) [self advanceState];
        }];
        return;
    }
    
    if (info[@"minimized scene direction"]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.guiMessagesOverlayContainer.transform = [self minimizedButtonTransform:self.guiSceneDirectionButtonContainer];
        } completion:^(BOOL finished) {
            self.guiMessagesOverlayContainer.hidden = YES;
            [self postEnableBGDetectionNotification];
            // Check the recorder state and advance it if needed.
            if (advancingState) [self advanceState];
        }];
        return;
    }
    
    if (info[@"minimized background status"]) {
        [UIView animateWithDuration:0.2 animations:^{
            self.guiMessagesOverlayContainer.transform = [self minimizedButtonTransform:self.guiBackgroundStatusButton];
        } completion:^(BOOL finished) {
            self.guiMessagesOverlayContainer.hidden = YES;
            [self postEnableBGDetectionNotification];
            // Check the recorder state and advance it if needed.
            if (advancingState) [self advanceState];
        }];
        return;
    }
    
    // Default dismiss animation
    [UIView animateWithDuration:0.3 animations:^{
        self.guiMessagesOverlayContainer.transform = defaultTransform;
    } completion:^(BOOL finished) {
        self.guiMessagesOverlayContainer.hidden = YES;
        [self postEnableBGDetectionNotification];
        // Check the recorder state and advance it if needed.
        if (advancingState) [self advanceState];
    }];
}

-(CGAffineTransform)minimizedButtonTransform:(UIView *)view
{
    CGPoint dc = view.center;
    CGPoint sc = self.guiMessagesOverlayContainer.center;
    
    double scaleX = 0.01;
    double scaleY = 0.01;
    
    double moveX = dc.x - sc.x;
    double moveY = dc.y - sc.y;
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(moveX, moveY);
    transform = CGAffineTransformScale(transform, scaleX, scaleY);
    return transform;
}

-(void)dismissOverlayAdvancingState:(BOOL)advancingState fromState:(HMRecorderState)fromState info:(NSDictionary *)info
{
    // Change state to this
    _recorderState = fromState;
    
    // Advance it if requested.
    [self dismissOverlayAdvancingState:advancingState info:info];
}

-(void)toggleOptions
{
    [self toggleOptionsAnimated:YES];
}

-(void)updateWithUpdateType:(HMRemakerUpdateType)updateType info:(NSDictionary *)info
{
    if (updateType == HMRemakerUpdateTypeScriptToggle) {
        if (self.detailedOptionsOpened) {
            [self showTopScriptViewIfUserPreffered];
        } else {
            [self hideTopScriptView];
        }
        return;
    }
    
    if (updateType == HMRemakerUpdateTypeCreateMovie) {
        _recorderState = HMRecorderStateUserRequestToCheckWhatNext;
        [self advanceState];
        return;
    }
    
    if (updateType == HMRemakerUpdateTypeCancelEditingTexts) {
        [self stateMakingAScene];
        return;
    }
    
    if (updateType == HMRemakerUpdateTypeRetakeScene) {
        NSNumber *sceneID = info[@"sceneID"];
        [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeAreYouSureYouWantToRetakeScene
                           checkNextStateOnDismiss:NO
                                              info:@{@"sceneID":sceneID,
                                                     @"dismissOnDecision":@YES
                                                     }
         ];
        return;
    }
    
    if (updateType == HMRemakerUpdateTypeSelectSceneAndPrepareToShoot) {
        NSNumber *sceneID = info[@"sceneID"];
        [self selectSceneID:sceneID];
        [self closeDetailedOptionsAnimated:YES];
        [self dismissOverlayAdvancingState:NO];
        [self stateMakingAScene];
    }
    
}

-(void)updateUIForCurrentScene
{
    [self updateUIForSceneID:self.currentSceneID];
}

-(void)selectSceneID:(NSNumber *)sceneID
{
    _currentSceneID = sceneID;
    [self updateUIForSceneID:sceneID];
    
    // Stop playing scene direction audio if playing
    if (self.directionAudioPlayer) [self stopSceneDirectionAudioPlayback];
}

-(void)showSceneContextMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info
{
    Scene *scene = [Scene sceneWithID:sceneID story:self.remake.story inContext:DB.sh.context];
    if (scene.directionAudioURL) {
        // If direction with audio, will toggle audio playback.
        [self toggleSceneDirectionAudioPlayback];
        return;
    }
    
    [[Mixpanel sharedInstance] track:@"RESceneDescriptionStart" properties:@{@"story" : self.remake.story.name ,@"remake_id": self.remake.sID, @"scene_id" : [NSString stringWithFormat:@"%ld" , sceneID.longValue]}];
    
    NSMutableDictionary *allInfo = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                   @"icon name":@"iconSceneDescription",
                                                                                   
                                                                                   @"title":[NSString stringWithFormat:LS(@"SCENE_TITLE") , sceneID.integerValue],
                                                                                   @"text":scene.context,
                                                                                   @"ok button text":LS(@"NEXT_SCENE"),
                                                                                   }];
    if (info) [allInfo addEntriesFromDictionary:info];
    
    [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeSceneContext
                       checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
                                          info:allInfo
     ];
}

#pragma mark - User messages
-(void)revealMessagesOverlayWithMessageType:(NSInteger)messageType checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info
{
    //
    // Setup the message.
    //
    [self.messagesOverlayVC showMessageOfType:messageType
                      checkNextStateOnDismiss:checkNextStateOnDismiss
                                         info:info];
    
    //
    // Show animated
    //
    self.guiMessagesOverlayContainer.hidden = NO;
    [self postDisableBGdetectionNotification];
    self.guiMessagesOverlayContainer.transform = CGAffineTransformMakeScale(1.2, 1.2);
    double animationDuration = 0.3; // default value
    
    if (info[@"minimized scene direction"]) {
        animationDuration = 0.2;
        self.guiMessagesOverlayContainer.transform = [self minimizedButtonTransform:self.guiSceneDirectionButtonContainer];
    }
    
    if (info[@"minimized background status"]) {
        animationDuration = 0.2;
        self.guiMessagesOverlayContainer.transform = [self minimizedButtonTransform:self.guiBackgroundStatusButton];
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.guiMessagesOverlayContainer.alpha = 1;
        self.guiMessagesOverlayContainer.transform = CGAffineTransformIdentity;
    }];
}

-(void)showFinishedSceneMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
{
    NSNumber *nextSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    Scene *nextScene = [self.remake.story findSceneWithID:nextSceneID];
    Scene *finishedScene = [self.remake.story findSceneWithID:sceneID];

    NSMutableDictionary *info = [NSMutableDictionary new];
    info[@"text"] = nextScene.context;
    info[@"sceneID"] = sceneID;
    info[@"nextSceneID"] = nextSceneID;
    if (finishedScene.postSceneAudio) {
        info[@"audioMessage"] = finishedScene.postSceneAudio;
    }
    
    NSString *eventName = [NSString stringWithFormat:@"REFinishedScene%ld" , sceneID.longValue];
    [[Mixpanel sharedInstance] track:eventName properties:@{@"story" : self.remake.story.name , @"scene_id" : [NSString stringWithFormat:@"%ld" , sceneID.longValue], @"remake_id" : self.remake.sID}];
    [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeFinishedScene
                       checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
                                          info:info
     ];
}

-(void)showFinishedAllScenesMessage
{
    NSDictionary *info = nil;
    Scene *finishedScene = [self.remake.story findSceneWithID:self.currentSceneID];
    if (finishedScene.postSceneAudio) {
        info = @{@"audioMessage":finishedScene.postSceneAudio};
    }
    
    _recorderState = HMRecorderStateFinishedAllScenesMessage;
    [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeFinishedAllScenes
                       checkNextStateOnDismiss:YES
                                          info:info
     ];
}

-(void)showEditingTextsScreen
{
    self.guiTextsEditingContainer.hidden = NO;
    self.guiTextsEditingContainer.center = CGPointMake(self.view.center.x, self.view.center.y + self.view.bounds.size.height / 2.0f);
    _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view.superview];
    UISnapBehavior *snap;
    snap = [[UISnapBehavior alloc] initWithItem:self.guiTextsEditingContainer snapToPoint:self.view.superview.center];
    [snap setDamping:0.3];
    [self.animator addBehavior:snap];
    
    [self.editingTextsVC updateValues];
}

#pragma mark - toggle options bar
-(void)initOptions
{
    [self closeDetailedOptionsAnimated:NO];
}

-(void)toggleOptionsAnimated:(BOOL)animated
{
    if (self.detailedOptionsOpened) {
        [self closeDetailedOptionsAnimated:animated];
        [self postEnableBGDetectionNotification];
    } else {
        [self openDetailedOptionsAnimated:animated];
        [self postDisableBGdetectionNotification];
        //THE HAND!!
        self.showHand = NO;
    }
}

-(void)closeDetailedOptionsAnimated:(BOOL)animated
{
    [self showTopButtons];
    [self hideTopScriptView];

    self.guiBackgroundStatusButton.transform = CGAffineTransformIdentity;
    _detailedOptionsOpened = NO;
    if (!animated) {
        self.guiDetailedOptionsBarContainer.hidden = NO;
        self.guiDetailedOptionsBarContainer.transform = OPTIONS_BAR_TRANSFORM_CLOSED;
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED object:nil userInfo:@{@"animated":@(animated)}];
        return;
    }
    
    self.guiDetailedOptionsBarContainer.hidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSING object:nil userInfo:@{@"animated":@(animated)}];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.guiDetailedOptionsBarContainer.transform = OPTIONS_BAR_TRANSFORM_CLOSED;
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED object:nil userInfo:@{@"animated":@(animated)}];
    }];
}

-(void)openDetailedOptionsAnimated:(BOOL)animated
{
    [self hideTopButtons];
    [self showTopScriptViewIfUserPreffered];
    
    self.guiDetailedOptionsBarContainer.hidden = !self.isBadBackgroundWarningOn;
    _detailedOptionsOpened = YES;
    if (!animated) {
        self.guiDetailedOptionsBarContainer.transform = OPTIONS_BAR_TRANSFORM_OPENED;
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENED object:nil userInfo:@{@"animated":@(animated)}];
        return;
    }
    
    self.guiDetailedOptionsBarContainer.hidden = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENING object:nil userInfo:@{@"animated":@(animated)}];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.guiDetailedOptionsBarContainer.transform = OPTIONS_BAR_TRANSFORM_OPENED;
    } completion:^(BOOL finished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_OPENED object:nil userInfo:@{@"animated":@(animated)}];
    }];
}

-(void)hideDetailsOptionsAnimated:(BOOL)animated
{
    if (!animated) {
        self.guiDetailedOptionsBarContainer.transform = OPTIONS_BAR_TRANSFORM_HIDDEN;
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED object:nil userInfo:@{@"animated":@(animated)}];
        self.guiDetailedOptionsBarContainer.hidden = YES;
        return;
    }
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.guiDetailedOptionsBarContainer.transform = OPTIONS_BAR_TRANSFORM_HIDDEN;
    } completion:^(BOOL finished) {
        
        if (_stopRecordingFired)
        {
            [self presentRecorderIdleUI];
        } else {
            self.guiDetailedOptionsBarContainer.hidden = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED object:nil userInfo:@{@"animated":@(animated)}];
        }
    }];
}

#pragma mark - Top buttons
-(void)showTopButtons
{
    self.guiDismissButton.hidden = NO;
    self.guiCameraSwitchingButton.hidden = !self.frontCameraAllowed;
    self.guiSceneDirectionButtonContainer.hidden = NO;
    self.guiBackgroundStatusButton.hidden = NO;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.guiDismissButton.alpha = 1;
        self.guiCameraSwitchingButton.alpha = 1;
        self.guiSceneDirectionButtonContainer.alpha = 1;
        self.guiBackgroundStatusButton.alpha = self.isBadBackgroundWarningOn ? 1:0;
    } completion:^(BOOL finished) {
    }];
}

-(void)hideTopButtons
{
    [UIView animateWithDuration:0.2 animations:^{
        self.guiDismissButton.alpha = 0;
        self.guiCameraSwitchingButton.alpha = 0;
        self.guiSceneDirectionButtonContainer.alpha = 0;
        self.guiBackgroundStatusButton.alpha = 0;
        
    } completion:^(BOOL finished) {
        self.guiDismissButton.hidden = YES;
        self.guiSceneDirectionButtonContainer.hidden = YES;
        self.guiCameraSwitchingButton.hidden = YES;
        self.guiBackgroundStatusButton.hidden = YES;
    }];
}

-(CGRect)sceneDirectionMinimizedFrame
{
    return self.guiSceneDirectionButtonContainer.frame;
}

#pragma mark - Top script view
-(void)showTopScriptViewIfUserPreffered
{
    Scene *scene = [self.remake.story findSceneWithID:self.currentSceneID];
    if (User.current.prefersToSeeScriptWhileRecording.boolValue && scene.hasScript) {
        [self showTopScriptView];
    } else {
        [self hideTopScriptView];
    }
}

-(void)showTopScriptView
{
    self.guiTopScriptView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.guiTopScriptView.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

-(void)hideTopScriptView
{
    if (self.guiTopScriptView.hidden == YES) return;
    [UIView animateWithDuration:0.2 animations:^{
        self.guiTopScriptView.alpha = 0;
    } completion:^(BOOL finished) {
        self.guiTopScriptView.hidden = YES;
    }];
}


#pragma mark - Dismiss
-(void)dismissWithReason:(HMRecorderDismissReason)reason
{
    if (reason == HMRecorderDismissReasonFinishedRemake) {
        // TODO: fix this
        //[HMCacheManager.sh clearTempFilesForRemake:self.remake];
    }
    
    if (self.delegate) {
        [self.delegate recorderAsksDismissalWithReason:reason
                                             remakeID:self.remake.sID
                                               sender:self
         ];
    } else {
        HMGLogWarning(@"No HMRecorderDelegate for recorder. HMRecorderViewController dismissed itself.");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)flipCamera
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_FLIP_CAMERA object:self];
    [self updateUIForSceneID:self.currentSceneID];
}

#pragma mark - Bad background
-(NSString *)badBackgroundStringKeyForMark:(NSInteger)mark
{
    NSString *stringKey = self.badBackgroundTextsMappings[@(mark)];
    
    // If a mapping exists, return it.
    if ([stringKey isKindOfClass:[NSString class]]) return stringKey;

    // If mapping not found, return the string key for the general bad background message.
    return self.badBackgroundTextsMappings[@(BBG_MARK_UNRECOGNIZED)];
}

-(void)presentBadBackgroundAlert
{
    NSString *badBackgroundMessageStringKey = [self badBackgroundStringKeyForMark:self.lastBadBackgroundMark];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *allInfo = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                       @"icon name":@"badBackground",
                                                                                       @"title":LS(@"BAD_BACKGROUND_TITLE"),
                                                                                       @"message":LS(badBackgroundMessageStringKey),
                                                                                       @"ok button text":LS(@"OK_GOT_IT"),
                                                                                       
                                                                                       @"blur alpha":@0.85,
                                                                                       @"minimized background status":@YES
                
                                                                                       }];
        [self revealMessagesOverlayWithMessageType:HMRecorderMessagesTypeBadBG
                           checkNextStateOnDismiss:NO
                                              info:allInfo
         ];
    });
}

#pragma mark - Audio direction
-(void)toggleSceneDirectionAudioPlayback
{
    // Current scene.
    if (self.directionAudioPlayer) {
        [self stopSceneDirectionAudioPlayback];
    } else {
        [self startSceneDirectionAudioPlayback];
    }
}

-(void)stopSceneDirectionAudioPlayback
{
    if (!self.directionAudioPlayer) return;
    
    self.directionAudioPlayer.delegate = nil;
    [self.directionAudioPlayer stop];
    self.directionAudioPlayer = nil;
    [UIView animateWithDuration:0.2 animations:^{
        self.guiSceneDirectionButton.alpha = 1.0;
    }];
}

-(void)startSceneDirectionAudioPlayback
{
    Scene *scene = [Scene sceneWithID:self.currentSceneID story:self.remake.story inContext:DB.sh.context];

    // Play the direction audio,
    NSString *url = scene.directionAudioURL;
    NSError *error;
    NSURL *soundURL = [HMCacheManager.sh urlForAudioResource:url];
    self.directionAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
    [self.directionAudioPlayer prepareToPlay];
    [self.directionAudioPlayer play];
    self.directionAudioPlayer.delegate = self;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.guiSceneDirectionButton.alpha = 0.2;
    }];
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self stopSceneDirectionAudioPlayback];
}

#pragma mark UITextView delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self stopSceneDirectionAudioPlayback]; // Stop if playing. Nothing otherwise.

    //leave recorder
    if (buttonIndex == 1) {
        NSString *storyName = self.remake.story.name ? self.remake.story.name : @"unknown";
        NSString *remakeID = self.remake.sID ? self.remake.sID : @"unknown";
        [[Mixpanel sharedInstance] track:@"UserClosedRecorder" properties:@{@"story": storyName, @"remake_id": remakeID}];
        [self dismissWithReason:HMRecorderDismissReasonUserAbortedPressingX];
        
        // Report about user exiting the recorder, if relevant test requires.
        if ([self.abTester isABTestingProject:AB_PROJECT_RECORDER_BAD_BACKGROUNDS]) {
            [self.abTester reportEventType:@"dismissedRecorderWithExitButton"];
            if ([self.currentSceneID integerValue] == 1) {
                [self.abTester reportEventType:@"dismissedRecorderOnFirstScene"];
            }
        }
    }
}

-(void)onCameraNotStable:(NSNotification *)notification
{
    NSDictionary *info = @{HM_INFO_KEY_RECORDING_STOP_REASON:@(HMRecordingStopReasonCameraNotStable)};
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                        object:self
                                                      userInfo:info];
}

-(void)onBadBackgroundDetected:(NSNotification *)notification
{
    if (self.backgroundStatusCounter <= BAD_BACKGROUND_TH)
    {
        // Store the latest bad background mark.
        NSNumber *badBackgroundMark = notification.userInfo[K_BAD_BACKGROUND_MARK];
        if (badBackgroundMark)
            self.lastBadBackgroundMark = [badBackgroundMark integerValue];
        
        // When the number of notifications about a bad background reach a given
        // threshold, popup a message to the user about the bad background.
        
        // Also, don't open a popup if user asked not to show again
        // or a popup for that bbg mark was already opened.
        if (self.backgroundStatusCounter <= BAD_BACKGROUND_PRESENT_POPUP_TH &&
            ![User.current.disableBadBackgroundPopup isEqualToNumber:@YES] &&
            !self.usedBadBackgroundMarks[@(self.lastBadBackgroundMark)]) {
            
            // Present the bad background alert.
            self.usedBadBackgroundMarks[@(self.lastBadBackgroundMark)]= @YES;
            [self presentBadBackgroundAlert];
            self.backgroundStatusCounter = 0;
        }
        self.backgroundStatusCounter--;

        // lock record button if required
        [self lockRecordButtonIfRequiredByBadBackgroundPolicy];
        
        // Show bad background indicator if needed.
        if (self.backgroundAlertDisplaying) return;
        [self setBGStatusButtonCrossfade:YES];
        self.backgroundAlertDisplaying = YES;
        return;
    }
    
    if (self.backgroundStatusCounter > 0) self.backgroundStatusCounter = 0;
    self.backgroundStatusCounter--;

}

-(void)onGoodBackgroundDetected:(NSNotification *)notification
{
    if (self.backgroundStatusCounter >= GOOD_BACKGROUND_TH)
    {
        [self unlockRecordButton];
        if (!self.backgroundAlertDisplaying) return;
        [self setBGStatusButtonCrossfade:NO];
        self.backgroundAlertDisplaying = NO;
        return;
    }
    
    if (self.backgroundStatusCounter < 0) self.backgroundStatusCounter = 0;
    self.backgroundStatusCounter++;
    
}


-(void)onAppMovedToBackground:(NSNotification *)notification
{
    [self stopSceneDirectionAudioPlayback]; // Stop if playing. Nothing otherwise.
    
    NSDictionary *info = @{HM_INFO_KEY_RECORDING_STOP_REASON:@(HMRecordingStopReasonAppWentToBackground)};
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                        object:self
                                                      userInfo:info];
}

-(void)onAppDidEnterForeground:(NSNotification *)notification
{
    [self.optionsBarVC checkMicrophoneAuthorization];
}

-(void)postDisableBGdetectionNotification
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:HM_DISABLE_BG_DETECTION object:self];
}

-(void)postEnableBGDetectionNotification
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:HM_ENABLE_BG_DETECTION object:self];
}

-(void)displayRect:(NSString *)name BoundsOf:(CGRect)rect
{
    CGSize size = rect.size;
    CGPoint origin = rect.origin;
    NSLog(@"%@ bounds: origin:(%f,%f) size(%f %f)" , name , origin.x , origin.y , size.width , size.height);
}

-(void)setBGStatusButtonCrossfade:(BOOL)activate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (activate)
        {
            // Show the bad background indicator.
            self.isBadBackgroundWarningOn = YES;
            [UIView animateWithDuration:0.3 animations:^{
                self.guiBackgroundStatusButton.alpha = 1;
            } completion:^(BOOL finished) {
                CABasicAnimation *crossFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
                crossFade.duration = 1.0;
                crossFade.fromValue = @(1.0);
                crossFade.toValue = @(0.5);
                crossFade.removedOnCompletion = NO;
                crossFade.autoreverses = YES;
                crossFade.repeatCount = HUGE_VALF;
                crossFade.fillMode = kCAFillModeForwards;
                [self.guiBackgroundStatusButton.imageView.layer addAnimation:crossFade forKey:@"animateContents"];
            }];
            
        } else {
            // Unlock record button.
            [self unlockRecordButton];
            
            // Remove the bad background indicator.
            [self.guiBackgroundStatusButton.imageView.layer removeAllAnimations];
            self.isBadBackgroundWarningOn = NO;
            [UIView animateWithDuration:0.1 animations:^{
                self.guiBackgroundStatusButton.alpha = 0;
            }];
            [self unlockRecordButton];
        }
    });
}

-(void)unlockRecordButton
{
    [self.optionsBarVC shouldUnlockRecordButton];
}

-(void)lockRecordButtonIfRequiredByBadBackgroundPolicy
{
    // Tolerant policy.
    // Warn the users, but let them shoot videos on bad backgrounds.
    if (self.badBackgroundPolicy == HMBadBackgroundPolicyTolerant) {
        [self unlockRecordButton];
        return;
    }
    
    // Strict policy.
    // Lock the record button in noisy or dark backgrounds.
    if (self.badBackgroundPolicy == HMBadBackgroundPolicyStrict) {
        if (self.lastBadBackgroundMark == BBG_MARK_NOISY ||
            self.lastBadBackgroundMark == BBG_MARK_DARK) {
            [self _lockRecordButton];
            return;
        }
        [self unlockRecordButton];
        return;
    }

    // BBG Nazi.
    // Lock the record button like a good old fashion dictator,
    // on bad background marks.
    if (self.badBackgroundPolicy == HMBadBackgroundPolicyNazi) {
        if (self.lastBadBackgroundMark == BBG_MARK_NOISY ||
            self.lastBadBackgroundMark == BBG_MARK_DARK ||
            self.lastBadBackgroundMark == BBG_MARK_SILHOUETTE ||
            self.lastBadBackgroundMark == BBG_MARK_SHADOW) {
            [self _lockRecordButton];
            return;
        }
        [self unlockRecordButton];
        return;
    }
    
    
}

-(void)_lockRecordButton
{
    [self.optionsBarVC shouldLockRecordButton];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedSceneDirectionButton:(id)sender
{
    // Scene direction has no audio. Will show a textual direction screen.
    // Show the scene context message for current scene.
    [self showSceneContextMessageForSceneID:self.currentSceneID
                    checkNextStateOnDismiss:NO
                                       info:@{
                                              @"blur alpha":@0.85,
                                              @"minimized scene direction":@YES}];
}

- (IBAction)onPressedBGStatusButton:(id)sender
{
    [self presentBadBackgroundAlert];
}

- (IBAction)onPressedDismissRecorderButton:(UIButton *)sender
{
    [self stopSceneDirectionAudioPlayback]; // Stop if playing. Nothing otherwise.
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: LS(@"LEAVE_RECORDER_TITLE") message:LS(@"LEAVE_RECORDER_MESSAGE") delegate:self cancelButtonTitle:LS(@"NO") otherButtonTitles:LS(@"YES") , nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView show];
    });
    
}


- (IBAction)onPressedFlipCameraButton:(UIButton *)sender
{
    [[Mixpanel sharedInstance] track:@"REFlipCamera" properties:@{@"story" : self.remake.story.name, @"remake_id": self.remake.sID}];
    [self flipCamera];
}


- (IBAction)onTappedDetailedOptionsBar:(UITapGestureRecognizer *)sender
{
    
    [self toggleOptionsAnimated:YES];
}

- (IBAction)onDraggingDetailedOptionsBar:(UIPanGestureRecognizer *)sender
{
    static double previousY;
    static double lastYChange;
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.startPanningY = self.guiDetailedOptionsBarContainer.transform.ty;
        previousY = self.startPanningY;
        lastYChange = 0;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        //
        // Drag it around
        //
        CGPoint delta = [sender translationInView:self.view];
        double y = MAX(MIN(self.startPanningY + delta.y, OPTIONS_BAR_TRANSFORM_MAX),0);
        self.guiDetailedOptionsBarContainer.transform = CGAffineTransformMakeTranslation(0, y);
        lastYChange = y-previousY;
        previousY = y;
        
        // Transform the bad background warning icon
        CGFloat scale = MAX(MIN(1-(self.startPanningY-y)/30.0f,1.0f),0);
        CGAffineTransform t = CGAffineTransformMakeTranslation(0, y-self.startPanningY);
        t = CGAffineTransformScale(t, scale, scale);
        self.guiBackgroundStatusButton.transform = t;
        
    } else if (sender.state == UIGestureRecognizerStateCancelled || sender.state == UIGestureRecognizerStateEnded) {
        //
        // Determine if to open or close at the end of the drag.
        //
        CGPoint delta = [sender translationInView:self.view];
        double y = MAX(MIN(self.startPanningY + delta.y, OPTIONS_BAR_TRANSFORM_MAX),0);
        lastYChange = y-previousY;
        if (lastYChange > 2.0f) {
            [self closeDetailedOptionsAnimated:YES];
        } else if (lastYChange < -2.0f) {
            [self openDetailedOptionsAnimated:YES];
        } else if (y>=OPTIONS_BAR_TRANSFORM_MAX/2.0f) {
            [self closeDetailedOptionsAnimated:YES];
        } else {
            [self openDetailedOptionsAnimated:YES];
        }
    }
}

- (IBAction)onPressedDebugButton:(id)sender
{
    //    CGAffineTransform transform;
    //    if (self.flagForDebugging) {
    //        transform = CGAffineTransformMakeRotation(M_PI/2);
    //    } else {
    //        transform = CGAffineTransformMakeRotation(M_PI/2*3);
    //    }
    //    [UIView beginAnimations:@"View Flip" context:nil];
    //    [UIView setAnimationDuration:0.5f];
    //    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    //    self.view.transform =transform;
    //    [UIView commitAnimations];
    //    self.flagForDebugging = !self.flagForDebugging;
}

@end
