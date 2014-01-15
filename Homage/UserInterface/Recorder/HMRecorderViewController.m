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
    [self toggleOptionsAnimated:NO];
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
    if (!animated) {
        self.guiDetailedOptionsBarContainer.hidden = YES;
        self.guiOptionsBarContainer.hidden = NO;
        self.detailedOptionsShown = NO;
        return;
    }
}

-(void)openDetailedOptionsAnimated:(BOOL)animated
{
    if (!animated) {
        self.guiDetailedOptionsBarContainer.hidden = NO;
        self.guiOptionsBarContainer.hidden = YES;
        self.detailedOptionsShown = YES;
        return;
    }
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
