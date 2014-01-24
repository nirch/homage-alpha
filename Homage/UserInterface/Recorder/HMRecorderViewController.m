//
//  HMRecorderViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#define OPTIONS_BAR_TRANSFORM_MAX 167.0f
#define OPTIONS_BAR_TRANSFORM_CLOSED CGAffineTransformMakeTranslation(0, OPTIONS_BAR_TRANSFORM_MAX)
#define OPTIONS_BAR_TRANSFORM_OPENED CGAffineTransformIdentity
#define OPTIONS_BAR_TRANSFORM_HIDDEN CGAffineTransformMakeTranslation(0, 260)

#import "HMRecorderViewController.h"
#import "HMRecorderChildInterface.h"
#import "HMRecorderMessagesOverlayViewController.h"
#import "DB.h"
#import "HMServer+LazyLoading.h"
#import "HMNotificationCenter.h"

@interface HMRecorderViewController ()

// IB outlets

// Child interfaces containers (overlay, messages, detailed options/action bar etc).
@property (weak, nonatomic) IBOutlet UIView *guiCameraContainer;
@property (weak, nonatomic) IBOutlet UIView *guiDetailedOptionsBarContainer;
@property (weak, nonatomic) IBOutlet UIView *guiWhileRecordingOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiMessagesOverlayContainer;

// Silhouette background image
@property (weak, nonatomic) IBOutlet UIImageView *guiSilhouetteImageView;

// Overlay recorder buttons
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;
@property (weak, nonatomic) IBOutlet UIButton *guiCameraSwitchingButton;

// Weak pointers to child view controllers
@property (weak, nonatomic, readonly) HMRecorderMessagesOverlayViewController *messagesOverlayVC;

// UI State
@property (nonatomic, readonly) BOOL detailedOptionsOpened;
@property (nonatomic, readonly) HMRecorderState recorderState;
@property (nonatomic) double startPanningY;
@property (nonatomic, readonly) BOOL lockedAutoRotation;

@end

@implementation HMRecorderViewController

@synthesize remake = _remake;
@synthesize currentSceneID = _currentSceneID;


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
    HMGLogInfo(@"Opened recorder for remake:%@ story:%@",self.remake.sID, self.remake.story.name);
    [self initRemakerState];
    [self initOptions];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Recorder state flow
-(void)initRemakerState
{
    // Critical error if remake doesn't exist in local storage!
    if (!self.remake) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Critical error"
                                                        message:@"Recorder missing reference to a 'REMAKE'."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        [alert show];
    }
    
    // Currently edited scene
    _recorderState = HMRecorderStateJustStarted;
    [self checkState];
}

-(void)checkState
{
    //
    // The flow state machine.
    // Moves to next stage according to current state.
    //
    NSLog(@"%d", self.recorderState);
    if (self.recorderState == HMRecorderStateJustStarted) {
        
        // 0 - HMRecorderStateJustStarted --> HMRecorderStateGeneralMessage
        [self stateShowGeneralIntroStateIfNeeded];
        
    } else if (self.recorderState == HMRecorderStateGeneralMessage) {
        
        // 1 - HMRecorderStateGeneralMessage --> HMRecorderStateSceneContextMessage
        [self stateShowContextForNextScene];
        
    } else if (self.recorderState == HMRecorderStateSceneContextMessage) {
        
        // 2 - HMRecorderStateSceneContextMessage --> HMRecorderStateMakingAScene
        [self stateMakingAScene];
        
    } else if (self.recorderState == HMRecorderStateMakingAScene) {
        
        // 3- HMRecorderStateMakingAScene --> HMRecorderStateFinishedASceneMessage  or  ?
        [self stateFinishedMakingASceneAndCheckingWhatsNext];
        
    } else if (self.recorderState == HMRecorderStateFinishedASceneMessage) {
        
        // 4 - HMRecorderStateFinishedASceneMessage --> going to next scene --> HMRecorderStateMakingAScene
        [self stateMakingNextScene];
        
    }
}

-(void)stateShowGeneralIntroStateIfNeeded
{
    // HMRecorderStateJustStarted --> HMRecorderStateGeneralMessage
    
    //
    // Select the first scene requiring a first retake.
    // If none found (all footages already taken by the user),
    // will select the last scene for this remake instead.
    //
    _currentSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    if (!self.currentSceneID) _currentSceneID = [self.remake lastSceneID];
    [self updateUIForSceneID:self.currentSceneID];
    
    // Just started. Show general message.
    // But if user chosen not to show that message, skip it.
    _recorderState = HMRecorderStateGeneralMessage;
    if ([User.current.skipRecorderTutorial isEqualToNumber:@(YES)]) {
        [self checkState]; // Don't show and skip state.
    } else {
        [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeGeneral checkNextStateOnDismiss:YES info:nil];
    }
    
}

-(void)stateShowContextForNextScene
{
    // HMRecorderStateGeneralMessage --> HMRecorderStateSceneContextMessage
    
    //
    // Showing context for the next scene needing a first retake.
    //
    _recorderState = HMRecorderStateSceneContextMessage;
    [self showSceneContextMessageForSceneID:self.currentSceneID checkNextStateOnDismiss:YES];
}

-(void)stateMakingAScene
{
    // HMRecorderStateSceneContextMessage || HMRecorderStateFinishedASceneMessage --> HMRecorderStateMakingAScene
    
    //
    // Making a scene :-)
    //
    _recorderState = HMRecorderStateMakingAScene;
    [self closeDetailedOptionsAnimated:YES];
    
    // Now the user has control of the flow...
}

-(void)stateFinishedMakingASceneAndCheckingWhatsNext
{
    // HMRecorderStateMakingAScene --> ?
    
    //
    // Check if we can continue to the next scene.
    //
    NSNumber *nextSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    
    if (!nextSceneID) {
        // HMRecorderStateMakingAScene --> HMRecorderStateFinishedAllScenesMessage
        
        // All scenes retaken by the user.
        _recorderState = HMRecorderStateFinishedAllScenesMessage;
        [self showFinishedSceneMessageForSceneID:self.currentSceneID checkNextStateOnDismiss:YES];
        
        return;
    }
    
    if (nextSceneID.integerValue <= self.currentSceneID.integerValue) {
        // ?
        return;
    }
    
    //
    // Showing "finished a scene" message.
    // And change to the next scene.
    //
    [self showFinishedSceneMessageForSceneID:self.currentSceneID checkNextStateOnDismiss:YES];
    _recorderState = HMRecorderStateFinishedASceneMessage;
}

-(void)stateMakingNextScene
{
    _currentSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    [self updateUIForCurrentScene];
    [self stateMakingAScene];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe lazy loading thumbnails
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onSilhouetteLoaded:)
                                                       name:HM_NOTIFICATION_SERVER_SCENE_SILHOUETTE
                                                     object:nil];
    
    // Observe started recording
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onStartRecording:)
                                                       name:HM_NOTIFICATION_RECORDER_START_RECORDING
                                                     object:nil];

    // Observe stop recording
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onStopRecording:)
                                                       name:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                                                     object:nil];

    // Observe raw user's take file is available and
    // needs to be added to the related Footage object in local storage
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onNewRawFootageFileAvailable:)
                                                       name:HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE
                                                     object:nil];
    
    // Handle recording errors by showing the FAIL message
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRecorderEpicFail:)
                                                       name:HM_NOTIFICATION_RECORDER_EPIC_FAIL
                                                     object:nil];


}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SCENE_SILHOUETTE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
}

#pragma mark - Observers handlers
-(void)onSilhouetteLoaded:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    UIImage *image = info[@"image"];
    Scene *scene = [Scene sceneWithID:info[@"sceneID"] story:self.remake.story inContext:DB.sh.context];
    
    if (notification.isReportingError || !image) {
        scene.silhouette = nil;
    } else {
        scene.silhouette = image;
    }

    // If related to current scene, display it.
    if ([scene.sID isEqualToNumber:self.currentSceneID]) {
        self.guiSilhouetteImageView.image = image;
        self.guiSilhouetteImageView.alpha = 0;
        self.guiSilhouetteImageView.hidden = NO;
        [UIView animateWithDuration:0.7 animations:^{
            self.guiSilhouetteImageView.alpha = 1;
        }];
    }
}

-(void)onStartRecording:(NSNotification *)notification
{
    _lockedAutoRotation = YES;
    
    [self hideDetailsOptionsAnimated:YES];

    self.guiDismissButton.enabled = NO;
    self.guiCameraSwitchingButton.enabled = NO;

    self.guiWhileRecordingOverlay.hidden = NO;
    self.guiWhileRecordingOverlay.alpha = 0;
    
    [UIView animateWithDuration:0.2 animations:^{
        
        // Fade out silhouette image
        self.guiSilhouetteImageView.alpha = 0;
        self.guiSilhouetteImageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
        
        // Fade out unwanted buttons
        self.guiCameraSwitchingButton.alpha = 0;
        self.guiDismissButton.alpha = 0;
        
        // Fade in "while recording" controls.
        self.guiWhileRecordingOverlay.alpha = 1;
        self.guiWhileRecordingOverlay.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
        self.guiSilhouetteImageView.hidden = YES;
        self.guiDetailedOptionsBarContainer.hidden = YES;
        self.guiWhileRecordingOverlay.hidden = NO;
    }];

}

-(void)onStopRecording:(NSNotification *)notification
{
    _lockedAutoRotation = NO;
    
    self.guiSilhouetteImageView.hidden = NO;
    self.guiSilhouetteImageView.transform = CGAffineTransformIdentity;
    self.guiDetailedOptionsBarContainer.hidden = NO;

    self.guiDismissButton.enabled = YES;
    self.guiDismissButton.hidden = NO;
    self.guiCameraSwitchingButton.enabled = YES;
    self.guiCameraSwitchingButton.hidden = NO;
    
    [self closeDetailedOptionsAnimated:YES]; // Show in closed state.
    [UIView animateWithDuration:0.2 animations:^{
        
        // Fade in silhouette image
        self.guiSilhouetteImageView.alpha = 1;
        
        // Fade in buttons
        self.guiDismissButton.alpha = 1;
        self.guiCameraSwitchingButton.alpha = 1;
        
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
    
    if (![remakeID isEqualToString:self.remake.sID]) {
        // If happens, something went wrong is the timing. Maybe a leak of an old recorder?
        HMGLogError(@"Why is the remake ID (%@) on onNewRawFootageFileAvailable different than the current one? (%@)", remakeID, self.remake.sID);
        return;
    }
    
    Footage *footage = [self.remake footageWithSceneID:sceneID];
    if (footage.rawLocalFile) [footage deleteRawLocalFile];
    footage.rawLocalFile = rawMoviePath;
    [DB.sh save];

    // Move along to the next state.
    [self checkState];
}

-(void)onRecorderEpicFail:(NSNotification *)notification
{
    // TODO: open error screen here
    NSLog(@"Epic fail!");
}

#pragma mark - Scenes selection
-(void)updateUIForSceneID:(NSNumber *)sceneID
{
    Scene *scene = [self.remake.story findSceneWithID:sceneID];

    // Notify all child interfaces about the current scene ID.
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_CURRENT_SCENE object:nil userInfo:@{@"sceneID":sceneID}];

    // Show silhouete of the related scene (or lazy load it).
    self.guiSilhouetteImageView.image = [self silhouetteForScene:scene];
    self.guiSilhouetteImageView.hidden = NO;
    self.guiSilhouetteImageView.transform = CGAffineTransformIdentity;
}

-(void)selectSceneID:(NSNumber *)sceneID
{
    _currentSceneID = sceneID;
    [self updateUIForSceneID:sceneID];
}

-(void)updateUIForCurrentScene
{
    [self updateUIForSceneID:self.currentSceneID];
}

#pragma mark - Lazy loading
-(UIImage *)silhouetteForScene:(Scene *)scene
{
    if (scene.silhouette) return scene.silhouette;
    [HMServer.sh lazyLoadImageFromURL:scene.silhouetteURL
                     placeHolderImage:nil
                     notificationName:HM_NOTIFICATION_SERVER_SCENE_SILHOUETTE
                                 info:@{@"sceneID":scene.sID}
     ];
    return nil;
}

#pragma mark - Orientations
-(BOOL)shouldAutorotate
{
    return !self.lockedAutoRotation;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - containment segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Pass self as delegate to those who conform to the HMRecorderChildInterface protocol.
    id<HMRecorderChildInterface> vc = segue.destinationViewController;
    if ([vc conformsToProtocol:@protocol(HMRecorderChildInterface)]) {
        [vc setRemakerDelegate:self];
    }
    
    // Specific destination view controllers
    if ([segue.identifier isEqualToString:@"messages overlay containment segue"]) {
        _messagesOverlayVC = segue.destinationViewController;
    }
}

#pragma mark - Messages overlay
-(void)dismissMessagesOverlay
{
    [self dismissMessagesOverlayAndCheckNextState:NO];
}

-(void)dismissMessagesOverlayAndCheckNextState:(BOOL)checkNextState
{
    // hide animted
    [UIView animateWithDuration:0.3 animations:^{
        //self.guiMessagesOverlayContainer.alpha = 0;
        self.guiMessagesOverlayContainer.transform = CGAffineTransformMakeScale(1.4, 0);
    } completion:^(BOOL finished) {
        self.guiMessagesOverlayContainer.hidden = YES;
        
        // Check the recorder state and advance it if needed.
        if (checkNextState) [self checkState];
    }];
}

-(void)dismissMessagesOverlayWithRecorderState:(HMRecorderState)recorderState checkNextState:(BOOL)checkNextState
{
    _recorderState = recorderState;
    [self dismissMessagesOverlayAndCheckNextState:checkNextState];
}

//
//  Show message with message type.
//
-(void)showMessagesOverlayWithMessageType:(NSInteger)messageType checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info
{
    [self.messagesOverlayVC showMessageOfType:messageType checkNextStateOnDismiss:checkNextStateOnDismiss info:info];
    
    // Show animated
    self.guiMessagesOverlayContainer.hidden = NO;
    self.guiMessagesOverlayContainer.transform = CGAffineTransformMakeScale(1.2, 1.2);
    [UIView animateWithDuration:0.3 animations:^{
        self.guiMessagesOverlayContainer.alpha = 1;
        self.guiMessagesOverlayContainer.transform = CGAffineTransformIdentity;
    }];
}

//
//  Scene context message.
//
-(void)showSceneContextMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
{
    Scene *scene = [self.remake.story findSceneWithID:sceneID];
    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeSceneContext
                     checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
                                        info:@{
                                               @"icon name":@"iconSceneDescription",
                                               @"title":scene.story.name.uppercaseString,
                                               @"text":scene.context,
                                               @"ok button text":@"OK, GOT IT!"
                                               }
     ];
}

-(void)showFinishedSceneMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
{
    NSNumber *nextSceneID = [self.remake nextReadyForFirstRetakeSceneID];
    Scene *nextScene = [self.remake.story findSceneWithID:nextSceneID];
    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeFinishedScene
                     checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
                                        info:@{@"text":nextScene.context,
                                               @"sceneID":sceneID,
                                               @"nextSceneID":nextSceneID
                                               }
     ];
}

-(void)showFinishedAllScenesMessage
{
    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeFinishedAllScenes
                     checkNextStateOnDismiss:YES
                                        info:nil
     ];
}


//
//  Finished all scenes message!
//
-(void)showFinishedAllSceneMessage
{
//    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeSceneContext
//                                        info:@{
//                                               @"title":[NSString stringWithFormat:@"%@ - %@", scene.story.name, scene.titleForSceneID],
//                                               @"text":scene.context,
//                                               @"ok button text":@"START!"
//                                               }
//     ];
}


#pragma mark - toggle options bar
-(void)initOptions
{
    [self closeDetailedOptionsAnimated:NO];
}

-(void)toggleOptions
{
    [self toggleOptionsAnimated:YES];
}

-(void)toggleOptionsAnimated:(BOOL)animated
{
    if (self.detailedOptionsOpened) {
        [self closeDetailedOptionsAnimated:animated];
    } else {
        [self openDetailedOptionsAnimated:animated];
    }
}

-(void)closeDetailedOptionsAnimated:(BOOL)animated
{
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
    _detailedOptionsOpened = YES;
    if (!animated) {
        self.guiDetailedOptionsBarContainer.hidden = NO;
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
        self.guiDetailedOptionsBarContainer.hidden = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_DETAILED_OPTIONS_CLOSED object:nil userInfo:@{@"animated":@(animated)}];
    }];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissRecorderButton:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

@end
