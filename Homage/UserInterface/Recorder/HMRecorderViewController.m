//
//  HMRecorderViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#define SILHOUETTE_HARD_CODED_ALPHA 0.2f

#define OPTIONS_BAR_TRANSFORM_MAX 167.0f
#define OPTIONS_BAR_TRANSFORM_CLOSED CGAffineTransformMakeTranslation(0, OPTIONS_BAR_TRANSFORM_MAX)
#define OPTIONS_BAR_TRANSFORM_OPENED CGAffineTransformIdentity
#define OPTIONS_BAR_TRANSFORM_HIDDEN CGAffineTransformMakeTranslation(0, 260)

#import "HMRecorderViewController.h"
#import "DB.h"
#import "HMRecorderChildInterface.h"
#import "HMRecorderMessagesOverlayViewController.h"
#import "HMNotificationCenter.h"
#import "HMServer+LazyLoading.h"

// TODO: Temporary. This is for fake footages upload updates.
// This will be the responsibility of the uploader and not the recorder.
#import "HMServer+Footages.h"

@interface HMRecorderViewController ()

// IB outlets

// Child interfaces containers (overlay, messages, detailed options/action bar etc).
@property (weak, nonatomic) IBOutlet UIView *guiCameraContainer;
@property (weak, nonatomic) IBOutlet UIView *guiDetailedOptionsBarContainer;
@property (weak, nonatomic) IBOutlet UIView *guiWhileRecordingOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiTextsEditingContainer;
@property (weak, nonatomic) IBOutlet UIView *guiMessagesOverlayContainer;

// Silhouette background image
@property (weak, nonatomic) IBOutlet UIImageView *guiSilhouetteImageView;

// Top recorder buttons
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;
@property (weak, nonatomic) IBOutlet UIButton *guiCameraSwitchingButton;

// Top script view
@property (weak, nonatomic) IBOutlet UIView *guiTopScriptView;
@property (weak, nonatomic) IBOutlet UILabel *guiScriptLabel;

// Weak pointers to child view controllers
@property (weak, nonatomic, readonly) HMRecorderMessagesOverlayViewController *messagesOverlayVC;

// UI State
@property (nonatomic, readonly) BOOL detailedOptionsOpened;
@property (nonatomic, readonly) HMRecorderState recorderState;
@property (nonatomic) double startPanningY;
@property (nonatomic, readonly) BOOL lockedAutoRotation;

// Some physics animations
@property (nonatomic, readonly) UIDynamicAnimator *animator;

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

-(void)dealloc
{
    HMGLogInfo(@"Recorder deallocated successfully for remakeID:%@", self.remake.sID);
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - UI initializations
-(void)initGUI
{
    self.guiSilhouetteImageView.alpha = 0;
}

#pragma mark - Recorder state flow
-(void)initRemakerState
{
    // Critical error if remake doesn't exist in local storage!
    if (!self.remake) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LS(@"Critical error")
                                                        message:LS(@"Recorder missing reference to a 'REMAKE'.")
                                                       delegate:nil
                                              cancelButtonTitle:LS(@"OK")
                                              otherButtonTitles:nil
                              ];
        [alert show];
    }
    
    // Currently edited scene
    _recorderState = HMRecorderStateJustStarted;
    [self advanceState];
}

-(void)advanceState
{
    //
    // The flow state machine.
    // Moves to next stage according to current state.
    //
    NSLog(@"%ld", (long)self.recorderState);
    if (self.recorderState == HMRecorderStateJustStarted) {
        
        // 0 - HMRecorderStateJustStarted --> 1 - HMRecorderStateGeneralMessage
        [self stateShowGeneralIntroStateIfNeeded];
        
    } else if (self.recorderState == HMRecorderStateGeneralMessage) {
        
        // 1 - HMRecorderStateGeneralMessage --> 2 - HMRecorderStateSceneContextMessage
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
        [self stateEditingTexts];
        
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
    if ([User.current.skipRecorderTutorial isEqualToNumber:@YES]) {
        // Skip to next state without showing the general message.
        [self advanceState];
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
    [self updateUIForCurrentScene];
    [self closeDetailedOptionsAnimated:YES];
    self.guiTextsEditingContainer.hidden = YES;
    
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

-(void)stateEditingTexts
{
    // TODO: implement
}

-(void)stateDoneIfUserRequestToCreateMovieIsASuccess
{
    // TODO: implement
    [self dismissWithReason:HMRecorderDismissReasonFinishedRemake];
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
    
    // Observe telling server to render
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRender:)
                                                       name:HM_NOTIFICATION_SERVER_RENDER
                                                     object:nil];


}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_SCENE_SILHOUETTE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_EPIC_FAIL object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_RENDER object:nil];
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
            // TODO: Make silhouette alpha dynamic
            self.guiSilhouetteImageView.alpha = SILHOUETTE_HARD_CODED_ALPHA;
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
        self.guiSilhouetteImageView.alpha = self.guiSilhouetteImageView.image ? SILHOUETTE_HARD_CODED_ALPHA : 0;
        
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

    // TODO: Temporary. This is for fake footages upload updates.
    // This will be the responsibility of the uploader and not the recorder.
    [HMServer.sh updateFootageForRemakeID:remakeID sceneID:sceneID];
    
    // Move along to the next state.
    [self advanceState];
}

-(void)onRecorderEpicFail:(NSNotification *)notification
{
    // TODO: open error screen here
    NSLog(@"Epic fail!");
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
}

#pragma mark - Scenes selection
-(void)updateUIForSceneID:(NSNumber *)sceneID
{
    Scene *scene = [self.remake.story findSceneWithID:sceneID];

    // Notify all child interfaces about the current scene ID.
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_UI_NOTIFICATION_RECORDER_CURRENT_SCENE object:nil userInfo:@{@"sceneID":sceneID}];

    // Show silhouete of the related scene (or lazy load it).
    UIImage *sillhouetterImage = [self silhouetteForScene:scene];
    self.guiSilhouetteImageView.image = sillhouetterImage;
    self.guiSilhouetteImageView.alpha = sillhouetterImage ? SILHOUETTE_HARD_CODED_ALPHA : 0;
    self.guiSilhouetteImageView.hidden = NO;
    self.guiSilhouetteImageView.transform = CGAffineTransformIdentity;
    
    if (scene.script && scene.script.length>0) {
        self.guiScriptLabel.text = scene.script;
    } else {
        self.guiScriptLabel.text = @"";
    }
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
    [self dismissOverlayAdvancingState:NO];
}

-(void)dismissOverlayAdvancingState:(BOOL)advancingState
{
    // hide animted
    [UIView animateWithDuration:0.3 animations:^{
        self.guiMessagesOverlayContainer.transform = CGAffineTransformMakeScale(1.4, 0);
    } completion:^(BOOL finished) {
        self.guiMessagesOverlayContainer.hidden = YES;
        // Check the recorder state and advance it if needed.
        if (advancingState) [self advanceState];
    }];
}

-(void)dismissOverlayAdvancingState:(BOOL)advancingState fromState:(HMRecorderState)fromState
{
    // Change state to this
    _recorderState = fromState;
    
    // Advance it if requested.
    [self dismissOverlayAdvancingState:advancingState];
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
    
}

-(void)updateUIForCurrentScene
{
    [self updateUIForSceneID:self.currentSceneID];
}

-(void)selectSceneID:(NSNumber *)sceneID
{
    _currentSceneID = sceneID;
    [self updateUIForSceneID:sceneID];
}

-(void)showSceneContextMessageForSceneID:(NSNumber *)sceneID checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
{
    Scene *scene = [self.remake.story findSceneWithID:sceneID];
    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeSceneContext
                     checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss
                                        info:@{
                                               @"icon name":@"iconSceneDescription",
                                               @"title":scene.story.name.uppercaseString,
                                               @"text":scene.context,
                                               @"ok button text":LS(@"OK, GOT IT!")
                                               }
     ];
}


#pragma mark - Sort this out
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
    _recorderState = HMRecorderStateFinishedAllScenesMessage;
    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeFinishedAllScenes
                     checkNextStateOnDismiss:YES
                                        info:nil
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
    } else {
        [self openDetailedOptionsAnimated:animated];
    }
}

-(void)closeDetailedOptionsAnimated:(BOOL)animated
{
    [self showTopButtons];
    [self hideTopScriptView];

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

#pragma mark - Top buttons
-(void)showTopButtons
{
    self.guiDismissButton.hidden = NO;
    self.guiCameraSwitchingButton.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.guiDismissButton.alpha = 1;
        self.guiCameraSwitchingButton.alpha = 1;
    } completion:^(BOOL finished) {
    }];
}

-(void)hideTopButtons
{
    [UIView animateWithDuration:0.2 animations:^{
        self.guiDismissButton.alpha = 0;
        self.guiCameraSwitchingButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.guiDismissButton.hidden = YES;
        self.guiCameraSwitchingButton.hidden = YES;
    }];
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
    if (self.delegate) {
        [self.delegate recorderAsksDismissalWithReaon:reason
                                             remakeID:self.remake.sID
                                               sender:self
         ];
    } else {
        HMGLogWarning(@"No HMRecorderDelegate for recorder. HMRecorderViewController dismissed itself.");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissRecorderButton:(UIButton *)sender
{
    [self dismissWithReason:HMRecorderDismissReasonUserAbortedPressingX];
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

- (IBAction)onPressedDebugButton:(id)sender
{
//    for (Footage *footage in self.remake.footagesOrdered) {
//        [HMServer.sh updateFootageForRemakeID:footage.remake.sID sceneID:footage.sceneID];
//    }
//    Footage *footage = self.remake.footagesOrdered[0];
//    [HMServer.sh updateFootageForRemakeID:footage.remake.sID sceneID:footage.sceneID];
//    
//    
}


@end
