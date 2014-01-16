//
//  HMRecorderViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderViewController.h"
#import "HMRecorderChildInterface.h"

@interface HMRecorderViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiGeneralInstructionsOverlayContainer;
@property (weak, nonatomic) IBOutlet UIView *guiCameraContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiDismissButton;
@property (weak, nonatomic) IBOutlet UIButton *guiCameraSwitchingButton;
@property (weak, nonatomic) IBOutlet UIView *guiOptionsBarContainer;
@property (weak, nonatomic) IBOutlet UIView *guiDetailedOptionsBarContainer;

@property (nonatomic) BOOL detailedOptionsShown;

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
}

-(void)initGUI
{
    [self initOptions];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
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
    id<HMRecorderChildInterface> vc = segue.destinationViewController;

    if ([vc conformsToProtocol:@protocol(HMRecorderChildInterface)]) {
        [vc setRemakerDelegate:self];
    }
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
