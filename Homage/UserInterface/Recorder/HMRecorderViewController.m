//
//  HMRecorderViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderViewController.h"
#import "HMRecorderChildInterface.h"
#import "HMRecorderMessagesOverlayViewController.h"
#import "DB.h"

typedef NS_ENUM(NSInteger, HMRecorderState) {
    HMRecorderStateJustStarted,
    HMRecorderStateGeneralMessage,
    HMRecorderStateRemakeContext,
    HMRecorderStateRemakingScenes,
    HMRecorderStateFinishedAllScenesMessage
};

@interface HMRecorderViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiMessagesOverlayContainer;
@property (weak, nonatomic) IBOutlet UIView *guiCameraContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;
@property (weak, nonatomic) IBOutlet UIButton *guiCameraSwitchingButton;
@property (weak, nonatomic) IBOutlet UIView *guiOptionsBarContainer;
@property (weak, nonatomic) IBOutlet UIView *guiDetailedOptionsBarContainer;

@property (nonatomic) BOOL detailedOptionsShown;
@property (weak, nonatomic, readonly) HMRecorderMessagesOverlayViewController *messagesOverlayVC;

@property (nonatomic, readonly) HMRecorderState recorderState;

@end

@implementation HMRecorderViewController

@synthesize remake = _remake;
@synthesize currentSceneID = _currentSceneID;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initRemakerState];
    [self initGUI];
}

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
    _currentSceneID = @(1);
    _recorderState = HMRecorderStateJustStarted;

    [self checkState];
}

-(void)initGUI
{
    [self initOptions];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Recorder state flow
-(void)checkState
{
    if (self.recorderState == HMRecorderStateJustStarted) {
        // Show general message
        _recorderState = HMRecorderStateGeneralMessage;
        [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeGeneral];
        return;
    } else if (self.recorderState == HMRecorderStateGeneralMessage) {
        // Dismissed general message. Show first
        _recorderState = HMRecorderStateRemakeContext;
        [self showRemakeContextMessage];
    }
}

#pragma mark - Orientations
-(BOOL)shouldAutorotate
{
    return YES;
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
-(void)showMessagesOverlayWithMessageType:(NSInteger)messageType
{
    [self showMessagesOverlayWithMessageType:messageType info:nil];
}

-(void)showMessagesOverlayWithMessageType:(NSInteger)messageType info:(NSDictionary *)info
{
    [self.messagesOverlayVC showMessageOfType:messageType info:info];

    // Show animated
    self.guiMessagesOverlayContainer.hidden = NO;
    self.guiMessagesOverlayContainer.transform = CGAffineTransformMakeScale(1.2, 1.2);
    [UIView animateWithDuration:0.3 animations:^{
        self.guiMessagesOverlayContainer.alpha = 1;
        self.guiMessagesOverlayContainer.transform = CGAffineTransformIdentity;
    }];
}

-(void)dismissMessagesOverlay
{
    // hide animted
    [UIView animateWithDuration:0.3 animations:^{
        self.guiMessagesOverlayContainer.alpha = 0;
        self.guiMessagesOverlayContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        self.guiMessagesOverlayContainer.hidden = YES;

        // Check the recorder state and advance it if needed.
        [self checkState];
    }];
}

-(void)showRemakeContextMessage
{
    [self showMessagesOverlayWithMessageType:HMRecorderMessagesTypeRemakeContext
                                        info:@{
                                               @"title":self.remake.story.name,
                                               @"text":self.remake.story.descriptionText
                                               }
     ];
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
    if (self.detailedOptionsShown) {
        [self closeDetailedOptionsAnimated:animated];
    } else {
        [self openDetailedOptionsAnimated:animated];
    }
}

-(void)closeDetailedOptionsAnimated:(BOOL)animated
{
    self.detailedOptionsShown = NO;
    if (!animated) {
        self.guiDetailedOptionsBarContainer.hidden = YES;
        self.guiOptionsBarContainer.hidden = NO;
        self.guiDetailedOptionsBarContainer.transform = CGAffineTransformMakeTranslation(0, 167);
        return;
    }

    // Animation start state.
    self.guiDetailedOptionsBarContainer.hidden = NO;
    self.guiOptionsBarContainer.hidden = NO;

    // Animation start state.
    self.guiDetailedOptionsBarContainer.hidden = NO;
    self.guiOptionsBarContainer.hidden = NO;
    
    // Translate animation
    [UIView animateWithDuration:0.3 animations:^{
        self.guiDetailedOptionsBarContainer.transform = CGAffineTransformMakeTranslation(0, 167);
    } completion:^(BOOL finished) {
        // Alpha animation
        [UIView animateWithDuration:0.15 animations:^{
            self.guiDetailedOptionsBarContainer.alpha = 0;
            self.guiOptionsBarContainer.alpha = 1;
        } completion:^(BOOL finished) {
            // Animation end state
            self.guiDetailedOptionsBarContainer.hidden = YES;
            self.guiOptionsBarContainer.hidden = NO;
        }];
        
    }];
}

-(void)openDetailedOptionsAnimated:(BOOL)animated
{
    self.detailedOptionsShown = YES;
    if (!animated) {
        self.guiDetailedOptionsBarContainer.hidden = NO;
        self.guiOptionsBarContainer.hidden = YES;
        self.guiDetailedOptionsBarContainer.transform = CGAffineTransformIdentity;
        return;
    }
    
    // Animation start state.
    self.guiDetailedOptionsBarContainer.hidden = NO;
    self.guiOptionsBarContainer.hidden = NO;
    
    // Alpha animation
    [UIView animateWithDuration:0.2 animations:^{
        self.guiDetailedOptionsBarContainer.alpha = 1;
        self.guiOptionsBarContainer.alpha = 0;
    }];
    
    // Translate animation
    [UIView animateWithDuration:0.4 animations:^{
        self.guiDetailedOptionsBarContainer.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        // Animation end state
        self.guiDetailedOptionsBarContainer.hidden = NO;
        self.guiOptionsBarContainer.hidden = YES;
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


@end
