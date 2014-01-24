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

@interface HMRecorderMessagesOverlayViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;

@property (weak, nonatomic) IBOutlet UIView *guiGeneralMessageContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiGeneralMessageSwipeUpIcon;
@property (weak, nonatomic) IBOutlet UIButton *guiGeneralMessageOKButton;


@property (weak, nonatomic) IBOutlet UIView *guiTextMessageContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiTextMessageIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiTextMessageTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiTextMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;

@property (weak, nonatomic) IBOutlet UIView *guiFinishedSceneButtonsContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiFinishedSceneRetakeButton;
@property (weak, nonatomic) IBOutlet UIButton *guiFinishedScenePreviewButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@property (weak, nonatomic) IBOutlet UIView *guiAreYouSureToRetakeContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiAreYouSureToRetakeIcon;
@property (weak, nonatomic) IBOutlet UILabel *guiAreYouSureYouWantToRetakeLabel;

@property (nonatomic, readonly) HMRecorderMessagesType messageType;
@property (nonatomic, readonly) BOOL shouldCheckNextStateOnDismiss;

@end

@implementation HMRecorderMessagesOverlayViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.guiDismissButton addMotionEffectWithAmount:15];
    [self.guiTextMessageIcon addMotionEffectWithAmount:15];
    [self.guiTextMessageTitleLabel addMotionEffectWithAmount:15];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[AMBlurView new] insertIntoView:self.guiBlurredView];
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

-(void)dealloc
{
    // NSLog(@">>> dealloc %@", [self class]);
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
    [self.guiActivity stopAnimating];
    self.guiDismissButton.enabled = YES;
}


#pragma mark - Selecting and showing messages
-(void)showMessageOfType:(HMRecorderMessagesType)messageType checkNextStateOnDismiss:(BOOL)checkNextStateOnDismiss info:(NSDictionary *)info
{
    _messageType = messageType;
    _shouldCheckNextStateOnDismiss = checkNextStateOnDismiss;
    self.guiGeneralMessageContainer.hidden = messageType != HMRecorderMessagesTypeGeneral;
    self.guiGeneralMessageSwipeUpIcon.hidden = messageType != HMRecorderMessagesTypeGeneral;

    self.guiTextMessageContainer.hidden = messageType == HMRecorderMessagesTypeGeneral;
    self.guiFinishedSceneButtonsContainer.hidden = messageType != HMRecorderMessagesTypeFinishedScene && messageType != HMRecorderMessagesTypeFinishedAllScenes ;
    self.guiAreYouSureToRetakeContainer.hidden = YES;
    
    if (self.messageType == HMRecorderMessagesTypeGeneral) {

        //
        // The intro message.
        //
        
        // Animate swipe up/down icon repeatedly.
        self.guiGeneralMessageSwipeUpIcon.transform = CGAffineTransformMakeTranslation(0, 5);
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:1.3 delay:0 options:HM_ANIMATION_OPTION_PING_PONG animations:^{
                self.guiGeneralMessageSwipeUpIcon.transform = CGAffineTransformMakeTranslation(0, -5);
            } completion:nil];
        });
        
        // Show the "Got it" button.
        [self.guiGeneralMessageOKButton addMotionEffectWithAmount:10];
        
    } else if (self.messageType == HMRecorderMessagesTypeSceneContext) {
        
        //
        //  The scene context message.
        //
        
        self.guiTextMessageTitleLabel.text = info[@"title"];
        self.guiTextMessageLabel.text = info[@"text"];
        [self.guiDismissButton setTitle:info[@"ok button text"] forState:UIControlStateNormal];
        NSString *iconName = info[@"icon name"];
        self.guiTextMessageIcon.image = [UIImage imageNamed:iconName];
        
    } else if (self.messageType == HMRecorderMessagesTypeFinishedScene ) {
        
        //
        //  The finished scene and next scene info message.
        //
        self.guiTextMessageTitleLabel.text = LS(@"GREAT JOB!");
        self.guiTextMessageIcon.image = [UIImage imageNamed:@"iconTrophy"];
        self.guiTextMessageLabel.text = [NSString stringWithFormat:LS(@"At the next scene %@"), info[@"text"]];
        [self.guiDismissButton setTitle:LS(@"NEXT SCENE") forState:UIControlStateNormal];
        [self.guiDismissButton setImage:[UIImage imageNamed:@"iconNextScene"] forState:UIControlStateNormal];
        
    } else if (self.messageType == HMRecorderMessagesTypeFinishedAllScenes ) {

        //
        //  The finished all scenes message + make movie button.
        //
        self.guiTextMessageTitleLabel.text = LS(@"GREAT JOB!");
        self.guiTextMessageIcon.image = [UIImage imageNamed:@"iconTrophy"];
        self.guiTextMessageLabel.text = LS(@"You nailed all scenes and ready to launch a movie");
        [self.guiDismissButton setTitle:LS(@"CREATE MOVIE") forState:UIControlStateNormal];
        [self.guiDismissButton setImage:[UIImage imageNamed:@"iconCreateMovie"] forState:UIControlStateNormal];
        
    }
}

-(void)serverCreateMovie
{
    [self.guiActivity startAnimating];
    Remake *remake = [self.remakerDelegate remake];
    [HMServer.sh renderRemakeWithID:remake.sID];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissButton:(UIButton *)sender
{
    if (self.messageType == HMRecorderMessagesTypeFinishedAllScenes) {
        sender.enabled = NO;
        [self serverCreateMovie];
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

//
// Finished scene message box buttons
//
- (IBAction)onPressedRetakeLastSceneButton:(UIButton *)sender
{
    self.guiTextMessageContainer.hidden = YES;
    self.guiAreYouSureToRetakeContainer.hidden = NO;
    [self.guiAreYouSureYouWantToRetakeLabel addMotionEffectWithAmount:20];
    [self.guiAreYouSureToRetakeIcon.layer removeAllAnimations];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.3 delay:0 options:HM_ANIMATION_OPTION_PING_PONG animations:^{
            self.guiAreYouSureToRetakeIcon.transform = CGAffineTransformMakeRotation(0.5);
        } completion:nil];
    });
}

- (IBAction)onPressedPreviewLastSceneButton:(UIButton *)sender
{
}

//
// Are you sure you want to retake buttons
//
- (IBAction)onPressedOopsDontRetakeButton:(UIButton *)sender
{
    self.guiTextMessageContainer.hidden = NO;
    self.guiAreYouSureToRetakeContainer.hidden = YES;
    [self.guiAreYouSureToRetakeIcon.layer removeAllAnimations];
}

- (IBAction)onPressedYeahRetakeThisScene:(UIButton *)sender
{
    //
    // Just stay in the same scene and allow user to retake.
    //
    [self.remakerDelegate updateUIForCurrentScene];
    [self.remakerDelegate dismissOverlayAdvancingState:NO fromState:HMRecorderStateMakingAScene];
}

@end
