//
//  HMRecorderMessagesOverlayViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAnimationsFX.h"
#import "DB.h"
#import "HMRecorderMessagesOverlayViewController.h"
#import "AMBlurView.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMNotificationCenter.h"
#import "HMServer+Render.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMRecorderPreviewViewController.h"
#import "mixpanel.h"

@interface HMRecorderMessagesOverlayViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;

@property (nonatomic, readonly) BOOL alreadyInitializedGUI;

@property (weak, nonatomic) IBOutlet UIView *guiGeneralMessageContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiGeneralMessageSwipeUpIcon;
@property (weak, nonatomic) IBOutlet UIButton *guiGeneralMessageOKButton;

@property (weak, nonatomic) IBOutlet UIView *guiTextMessageContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiTextMessageIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiTextMessageTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiTextMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;

@property (strong, nonatomic) IBOutlet UIView *guiBigImageViewContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiBigImageViewImage;
@property (weak, nonatomic) IBOutlet UILabel *guiBigImageTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiBigImagedismissButton;

@property (weak, nonatomic) IBOutlet UIView *guiFinishedSceneButtonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiFinishedSceneRetakeButton;
@property (weak, nonatomic) IBOutlet UIButton *guiFinishedScenePreviewButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@property (weak, nonatomic) IBOutlet UIView *guiAreYouSureToRetakeContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiAreYouSureToRetakeIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiAreYouSureYouWantToRetakeLabel;

@property (nonatomic, readonly) HMRecorderMessagesType messageType;
@property (nonatomic, readonly) BOOL shouldCheckNextStateOnDismiss;
@property (nonatomic) BOOL shouldDismissOnDecision;
@property (nonatomic, readonly) NSDictionary *info;

@end

@implementation HMRecorderMessagesOverlayViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadSubviews];
    
    [self.guiDismissButton addMotionEffectWithAmount:15];
    [self.guiTextMessageIcon addMotionEffectWithAmount:15];
    [self.guiTextMessageTitleLabel addMotionEffectWithAmount:15];
    [self.guiGeneralMessageOKButton addMotionEffectWithAmount:15];
    [self.guiAreYouSureYouWantToRetakeLabel addMotionEffectWithAmount:15];
}


-(void)loadSubviews
{
    //
    //  Because the messages UI started to contain different layouts on the same view controller
    //  Each particular message layout was moved to it's own xib file, in order to reduce clutter
    //  in the story board.
    //  Each type of message screen has it's own xib file (all using this same view controller)
    //
    // Load subview from xibs
    
    UIView *generalMessageView = [[NSBundle mainBundle] loadNibNamed:@"HMRecorderMessageGeneralView" owner:self options:nil][0];
    generalMessageView.frame = self.view.bounds;
    generalMessageView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:generalMessageView];

    UIView *commonMessageView = [[NSBundle mainBundle] loadNibNamed:@"HMRecorderMessageCommonView" owner:self options:nil][0];
    commonMessageView.frame = self.view.bounds;
    commonMessageView.backgroundColor = [UIColor clearColor];
    commonMessageView.hidden = YES;
    [self.view addSubview:commonMessageView];
    
    UIView *areYouSureMessageView = [[NSBundle mainBundle] loadNibNamed:@"HMRecorderMessageRetakeAreYouSureView" owner:self options:nil][0];
    areYouSureMessageView.frame = self.view.bounds;
    areYouSureMessageView.backgroundColor = [UIColor clearColor];
    areYouSureMessageView.hidden = YES;
    [self.view addSubview:areYouSureMessageView];
    
    UIView *bigImageView = [[NSBundle mainBundle] loadNibNamed:@"HMRecorderMessageBigImageView" owner:self options:nil][0];
    bigImageView.frame = self.view.bounds;
    bigImageView.backgroundColor = [UIColor clearColor];
    bigImageView.hidden = YES;
    [self.view addSubview:bigImageView];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initGUIOnceAfterFirstAppearance];
    [self initObservers];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeObservers];
}

#pragma mark - UI init
-(void)initGUIOnceAfterFirstAppearance
{
    if (self.alreadyInitializedGUI) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[AMBlurView new] insertIntoView:self.guiBlurredView];
        self.guiBlurredView.alpha = 0.0;
        [UIView animateWithDuration:1.0 animations:^{
            self.guiBlurredView.alpha = 1.0;
        }];
    });
    
    // Mark that GUI already initialized once.
    _alreadyInitializedGUI = YES;
}

#pragma mark - Obesrvers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // Observe telling server to render
    [nc addUniqueObserver:self
                 selector:@selector(onRender:)
                     name:HM_NOTIFICATION_SERVER_RENDER
                   object:nil];
    
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_RENDER object:nil];
}


#pragma mark - Observers handlers
-(void)onRender:(NSNotification *)notification
{
    if (notification.isReportingError) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed"
                                                        message:LS(@"Something went wrong. Check your connectivity and try again.")
                                                       delegate:nil
                                              cancelButtonTitle:LS(@"OK")
                                              otherButtonTitles:nil];
        [alert show];
        [self.guiActivity stopAnimating];
        self.guiDismissButton.enabled = YES;
    } else {
        [self dismissActivityView];
    }
}

-(void)dismissActivityView
{
    [self.guiActivity stopAnimating];
    self.guiDismissButton.enabled = YES;
}

#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"see preview segue"]) {
        HMRecorderPreviewViewController *vc = segue.destinationViewController;
        Remake *remake = [self.remakerDelegate remake];
        Footage *footage = [remake footageWithSceneID:[self.remakerDelegate currentSceneID]];
        vc.footage = footage;
    }
}

#pragma mark - Selecting and showing messages
-(void)showMessageOfType:(HMRecorderMessagesType)messageType checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info
{
    _messageType = messageType;
    _shouldCheckNextStateOnDismiss = checkNextStateOnDismiss;
    _info = info;
    self.guiGeneralMessageContainer.hidden = messageType != HMRecorderMessagesTypeGeneral;
    //THE HAND!!!
    //self.guiGeneralMessageSwipeUpIcon.hidden = messageType != HMRecorderMessagesTypeGeneral;
    self.guiGeneralMessageSwipeUpIcon.hidden = messageType == HMRecorderMessagesTypeGeneral;
    self.guiTextMessageContainer.hidden = messageType == HMRecorderMessagesTypeGeneral || messageType == HMRecorderMessagesTypeBigImage;
    self.guiBigImageViewContainer.hidden = messageType != HMRecorderMessagesTypeBigImage;
    
    self.guiFinishedSceneButtonsContainer.hidden = messageType != HMRecorderMessagesTypeFinishedScene && messageType != HMRecorderMessagesTypeFinishedAllScenes ;
    self.guiAreYouSureToRetakeContainer.hidden = YES;
    
    self.guiBlurredView.alpha = 1;
    //self.guiBlurredView.alpha = info[@"blur alpha"] ? [info[@"blur alpha"] doubleValue] : 1;
    
    //THE HAND!!
    if (self.messageType == HMRecorderMessagesTypeGeneral) {

        //
        // The intro message.
        //
        
        //the hand!!
        // Animate swipe up/down icon repeatedly.
        /*self.guiGeneralMessageSwipeUpIcon.transform = CGAffineTransformMakeTranslation(0, 5);
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.3 delay:0 options:HM_ANIMATION_OPTION_PING_PONG animations:^{
                self.guiGeneralMessageSwipeUpIcon.transform = CGAffineTransformMakeTranslation(0, -5);
            } completion:nil];
        });*/
        
        self.guiGeneralMessageOKButton.alpha = 1;
        /*HMGLogDebug(@"alpha started");
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 animations:^{
                self.guiGeneralMessageOKButton.alpha = 1;
            }];
        });*/
        
        
       
    } else if (self.messageType == HMRecorderMessagesTypeSceneContext) {
        
        //
        //  The scene context message.
        //
        
        self.guiTextMessageTitleLabel.text = info[@"title"];
        self.guiTextMessageLabel.text = info[@"text"];
        [self.guiDismissButton setTitle:info[@"ok button text"] forState:UIControlStateNormal];
        [self.guiDismissButton setImage:[UIImage imageNamed:@"iconGotIt"] forState:UIControlStateNormal];

        NSString *iconName = info[@"icon name"];
        self.guiTextMessageIcon.image = iconName ? [UIImage imageNamed:iconName] : [UIImage imageNamed:@"iconGotIt"];;
        
        self.guiDismissButton.alpha = 1;
        /*HMGLogDebug(@"alpha started");
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 animations:^{
                self.guiDismissButton.alpha = 1;
            }];
        });*/
        
    } else if (self.messageType == HMRecorderMessagesTypeBigImage) {
        
        self.guiBigImageTextLabel.text = info[@"text"];
        NSString *iconName = info[@"icon name"];
        self.guiBigImageViewImage.image = iconName ? [UIImage imageNamed:iconName] : [UIImage imageNamed:@"badBackground"];
        [self.guiDismissButton setTitle:info[@"ok button text"] forState:UIControlStateNormal];
        [self.guiDismissButton setImage:[UIImage imageNamed:@"iconGotIt"] forState:UIControlStateNormal];
    
        self.guiBigImagedismissButton.alpha = 1;
        /*HMGLogDebug(@"alpha started");
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.1 animations:^{
                self.guiBigImagedismissButton.alpha = 1;
            }];
        });*/

    } else if (self.messageType == HMRecorderMessagesTypeFinishedScene ) {
        
        //
        //  The finished scene and next scene info message.
        //
        self.guiTextMessageTitleLabel.text = LS(@"GREAT_JOB");
        self.guiTextMessageIcon.image = [UIImage imageNamed:@"iconTrophy"];
        self.guiTextMessageLabel.text = [NSString stringWithFormat:LS(@"AT_THE_NEXT_SCENE"), info[@"text"]];
        [self.guiDismissButton setTitle:LS(@"NEXT_SCENE") forState:UIControlStateNormal];
        [self.guiDismissButton setImage:[UIImage imageNamed:@"iconNextScene"] forState:UIControlStateNormal];
        
    } else if (self.messageType == HMRecorderMessagesTypeFinishedAllScenes ) {

        //
        //  The finished all scenes message + make movie button.
        //
        self.guiTextMessageTitleLabel.text = LS(@"GREAT_JOB");
        self.guiTextMessageIcon.image = [UIImage imageNamed:@"iconTrophy"];
        self.guiTextMessageLabel.text = LS(@"NAILED_ALL_SCENES");
        [self.guiDismissButton setTitle:LS(@"CREATE_MOVIE") forState:UIControlStateNormal];
        [self.guiDismissButton setImage:[UIImage imageNamed:@"iconCreateMovie"] forState:UIControlStateNormal];
        
    } else if (self.messageType == HMRecorderMessagesTypeAreYouSureYouWantToRetakeScene) {
        
        self.shouldDismissOnDecision = [info[@"dismissOnDecision"] isEqualToNumber:@YES];
        
        //
        //  Are you sure you want to retake a scene?
        //
        self.guiTextMessageContainer.hidden = YES;
        self.guiAreYouSureToRetakeContainer.hidden = NO;
        [self.guiAreYouSureToRetakeIcon.layer removeAllAnimations];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:1.3 delay:0 options:HM_ANIMATION_OPTION_PING_PONG animations:^{
                self.guiAreYouSureToRetakeIcon.transform = CGAffineTransformMakeRotation(0.5);
            } completion:nil];
        });
        
    }
}

-(void)serverCreateMovie
{
    [self.guiActivity startAnimating];
    Remake *remake = [self.remakerDelegate remake];
    [[Mixpanel sharedInstance] track: @"RECreateMovie" properties:@{@"story" : remake.story.name, @"remake_id": remake.sID}];
    [HMServer.sh renderRemakeWithID:remake.sID];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissButton:(UIButton *)sender
{
    if (self.messageType == HMRecorderMessagesTypeFinishedAllScenes)
    {
        sender.enabled = NO;
        
        /*if (!HMServer.sh.isReachable)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:LS(@"NO_CONNECTIVITY")                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil
                                  ];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
        }*/
        
        [self serverCreateMovie];
        return;
    } else if (self.messageType == HMRecorderMessagesTypeSceneContext)
    {
        [[Mixpanel sharedInstance] track: @"RESceneDescriptionDone"];
        [self.remakerDelegate dismissOverlayAdvancingState:self.shouldCheckNextStateOnDismiss info:@{@"minimized scene direction":@YES}];
        return;
    } else if (self.messageType == HMRecorderMessagesTypeBigImage)
    {
        [self.remakerDelegate dismissOverlayAdvancingState:self.shouldCheckNextStateOnDismiss info:@{@"minimized background status":@YES}];
        return;
    }
    [self.remakerDelegate dismissOverlayAdvancingState:self.shouldCheckNextStateOnDismiss];
}

- (IBAction)onPressedDismissAndDontShowIntroMessageAgainButton:(UIButton *)sender
{
    [self.remakerDelegate dismissOverlayAdvancingState:self.shouldCheckNextStateOnDismiss];
    User.current.skipRecorderTutorial = @YES;
    [DB.sh save];
}


- (IBAction)onPressedDismissAndDontShowBadBackgroundPopoup:(UIButton *)sender
{
    [self.remakerDelegate dismissOverlayAdvancingState:self.shouldCheckNextStateOnDismiss info:@{@"minimized background status":@YES}];
    User.current.disableBadBackgroundPopup = @YES;
    sender.hidden = YES;
    [DB.sh save];
}

//
// Finished scene message box buttons
//
- (IBAction)onPressedRetakeLastSceneButton:(UIButton *)sender
{
    Remake *remake = [self.remakerDelegate remake];
    NSString *sceneID = [NSString stringWithFormat:@"%ld" , [self.remakerDelegate currentSceneID].longValue];
    NSString *storyName = remake.story.name;
    NSString *remakeID = remake.sID;

    NSDictionary *props = @{
                            @"scene_id": sceneID ,
                            @"story": storyName,
                            @"remake_id": remakeID
                            };
    
    [[Mixpanel sharedInstance] track:@"RERetakeLast" properties:props];
    
    NSDictionary *info = @{
                           @"sceneID":[self.remakerDelegate currentSceneID],
                           @"dismissOnDecision":@NO
                           };
    
    HMRecorderMessagesType messageType = HMRecorderMessagesTypeAreYouSureYouWantToRetakeScene;
    [self showMessageOfType:messageType checkNextStateOnDismiss:NO info:info];
    
}

- (IBAction)onPressedPreviewLastSceneButton:(UIButton *)sender
{
    [[Mixpanel sharedInstance] track:@"RESeePreview" properties:@{@"scene_number" : [NSString stringWithFormat:@"%ld" , [self.remakerDelegate currentSceneID].longValue] , @"story" : [self.remakerDelegate remake].story.name, @"remake_id": [self.remakerDelegate remake].sID}];
    Remake *remake = [self.remakerDelegate remake];
    Footage *footage = [remake footageWithSceneID:[self.remakerDelegate currentSceneID]];
    if (footage.rawLocalFile) {
        [self performSegueWithIdentifier:@"see preview segue" sender:nil];
    } else {
        HMGLogDebug(@"Missing raw local file error");
    }
}

- (IBAction)onPressedOopsDontRetakeButton:(UIButton *)sender
{
    [[Mixpanel sharedInstance] track:@"REOopsNope" properties:@{@"scene_id" : [NSString stringWithFormat:@"%ld" , [self.remakerDelegate currentSceneID].longValue] , @"story" : [self.remakerDelegate remake].story.name, @"remake_id": [self.remakerDelegate remake].sID}];
    
    if (self.shouldDismissOnDecision) {
        [self.remakerDelegate dismissOverlayAdvancingState:self.shouldCheckNextStateOnDismiss];
        return;
    }
    //
    // Go back to the message leading here.
    //
    self.guiTextMessageContainer.hidden = NO;
    self.guiAreYouSureToRetakeContainer.hidden = YES;
    self.guiFinishedSceneButtonsContainer.hidden = NO;
    [self.guiAreYouSureToRetakeIcon.layer removeAllAnimations];
}

- (IBAction)onPressedYeahRetakeThisScene:(UIButton *)sender
{
     Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"YeahRetakeThisScene" properties:@{@"scene_id" : [NSString stringWithFormat:@"%ld" , [self.remakerDelegate currentSceneID].longValue] , @"story" : [self.remakerDelegate remake].story.name, @"remake_id": [self.remakerDelegate remake].sID}];
    if (self.shouldDismissOnDecision) {
        //
        //  Want to retake the scene
        //
        [self.remakerDelegate updateWithUpdateType:HMRemakerUpdateTypeSelectSceneAndPrepareToShoot info:self.info];
        return;
    }
    
    //
    // Just stay in the same scene and allow user to retake.
    //
    [self.remakerDelegate updateUIForCurrentScene];
    [self.remakerDelegate dismissOverlayAdvancingState:NO fromState:HMRecorderStateMakingAScene info:nil];
}

- (IBAction)onPressedSeePreviewButton:(id)sender
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
   
    
    Remake *remake = [self.remakerDelegate remake];
    [mixpanel track:@"RESeePreview" properties:@{@"scene_id" : [NSString stringWithFormat:@"%ld" , [self.remakerDelegate currentSceneID].longValue] , @"story" : [self.remakerDelegate remake].story.name, @"remake_id": [self.remakerDelegate remake].sID}];
    Footage *footage = [remake footageWithSceneID:[self.remakerDelegate currentSceneID]];
    if (footage.rawLocalFile) {
        [self performSegueWithIdentifier:@"see preview segue" sender:nil];
    } else {
        HMGLogDebug(@"Missing raw local file error");
    }
}

// ============
// Rewind segue
// ============
-(IBAction)unwindToThisViewController:(UIStoryboardSegue *)unwindSegue
{
    self.view.backgroundColor = [UIColor clearColor];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
