//
//  HMRecorderTutorialViewController.m
//  Homage
//
//  Created by Aviv Wolf on 3/2/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderTutorialViewController.h"

#import "DB.h"
#import "HMAppDelegate.h"
#import "HMABTester.h"
#import "HMStyle.h"
#import "HMServer+AppConfig.h"

#import "HMTOSViewController.h"
#import "HMPrivacyPolicyViewController.h"

#import <PSTAlertController/PSTAlertController.h>
#import "HMParentalControlViewController.h"
#import "HMParentalControlDelegate.h"

@interface HMRecorderTutorialViewController () <
    HMParentalControlDelegate
>

@property (nonatomic) NSInteger index;

@property (weak, nonatomic) IBOutlet UIView *guiDarkOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiSilIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIView *guiSolidBGIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIView *guiSceneIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIView *guiInspiredIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiContinueButton;
@property (weak, nonatomic) IBOutlet UIButton *guiNextCoverAllButton;

@property (weak, nonatomic) IBOutlet UILabel *guiSceneDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiUseSolidBGLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiPlaceActorHereLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiGetInspiredLabel;

@property (weak, nonatomic) IBOutlet UIImageView *guiGetInspiredIcon;

@property (weak, nonatomic) IBOutlet UIView *guiDisclaimerContainer;


@property (nonatomic) UINavigationController *legalNavVC;
@property (nonatomic) HMTOSViewController *tosVC;
@property (nonatomic) HMPrivacyPolicyViewController *privacyVC;
@property (nonatomic) NSInteger screensCount;

@end

@implementation HMRecorderTutorialViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.index = 0;
    self.screensCount = 2;
    if ([HMServer.sh.configurationInfo[@"recorder_disclaimer"] boolValue]) {
        self.screensCount += 1;
    }
    
    
    [self hideAllAnimated:NO];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUI];
    [self initABTesting];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self fixLayout];
}

-(void)initGUI
{
    self.guiSceneDurationLabel.text = LS(@"HELP_LABEL_SCENE_DURATION");
    self.guiUseSolidBGLabel.text = LS(@"HELP_LABEL_SOLID_BG");
    self.guiPlaceActorHereLabel.text = LS(@"HELP_LABEL_PLACE_ACTOR");
    self.guiGetInspiredLabel.text = LS(@"HELP_LABEL_GET_INSPIRED");
    
    
    self.tosVC = [[HMTOSViewController alloc] init];
    self.privacyVC = [[HMPrivacyPolicyViewController alloc] init];
    self.legalNavVC = [[UINavigationController alloc] init];
    

    
    // ************
    // *  STYLES  *
    // ************
    UIColor *textColor = [HMStyle.sh colorNamed:C_RECORDER_TUTORIAL_TEXT];
    self.guiSceneDurationLabel.textColor = textColor;
    self.guiUseSolidBGLabel.textColor = textColor;
    self.guiPlaceActorHereLabel.textColor = textColor;
    self.guiGetInspiredLabel.textColor = textColor;
    
    UIColor *buttonsColor = [HMStyle.sh colorNamed:C_RECORDER_TUTORIAL_BUTTON];
    [self.guiContinueButton setTitleColor:buttonsColor forState:UIControlStateNormal];
}

-(void)initABTesting
{
    HMAppDelegate *app = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
    HMABTester *abTester = app.abTester;
    
    // Get inspired icon
    NSString *abTestGetInspiredIconName = [abTester stringValueForProject:@"recorder icons"
                                                                  varName:@"getInspiredIcon"
                                                    hardCodedDefaultValue:@"iconUpArrow"];
    self.guiGetInspiredIcon.image = [UIImage imageNamed:abTestGetInspiredIconName];
}


-(void)hideAllAnimated:(BOOL)animated
{
    if (!animated) {
        self.guiNextCoverAllButton.alpha = 0;
        self.guiContinueButton.alpha = 0;
        self.guiDarkOverlay.alpha = 0;
        self.guiInspiredIndicatorContainer.alpha = 0;
        self.guiSceneIndicatorContainer.alpha = 0;
        self.guiSilIndicatorContainer.alpha = 0;
        self.guiSolidBGIndicatorContainer.alpha = 0;
        self.guiDisclaimerContainer.alpha = 0;
        return;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self hideAllAnimated:NO];
    }];
}

#pragma mark - Layout fixes
-(void)fixLayout
{
    
}

#pragma mark - Flow
-(void)start
{
    self.index = 0;
    [self handleState];
}

-(void)next
{
    self.index++;
    [self handleState];
}

-(void)done
{
    [self.remakerDelegate dismissOverlayAdvancingState:YES info:@{@"dismissing help screen":@YES}];
    User *user = [User current];
    user.skipRecorderTutorial = @YES;
}

#pragma mark - segues
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"parental control segue"]) {
        HMParentalControlViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }
}

#pragma mark - Showing tutorial messages
-(void)handleState
{
    if (self.index >= self.screensCount) {
        [self done];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showTutorialForCurrentIndex];
    });
}

-(void)showTutorialForCurrentIndex
{
    self.guiDarkOverlay.layer.mask = nil;
    
    [self fadeInView:self.guiDarkOverlay delay:0.0];
    [self fadeInView:self.guiNextCoverAllButton delay:0.3];

    if (self.index==0) {
    
        [self.guiContinueButton setTitle:LS(@"HELP_BUTTON_NEXT") forState:UIControlStateNormal];
        [self revealView:self.guiSolidBGIndicatorContainer delay:0.0];
        [self fadeInView:self.guiSilIndicatorContainer delay:0.8];
        [self fadeInView:self.guiContinueButton delay:0.3];
    
    } else if (self.index==1) {
        
        [self.guiContinueButton setTitle:LS(@"HELP_BUTTON_NEXT") forState:UIControlStateNormal];
        [self fadeInView:self.guiContinueButton delay:0.3];
        
        // Punch holes in the dark overlay
        [self punchHoles];
        
        // Reveal indicators
        [self revealView:self.guiSceneIndicatorContainer delay:0.4];
        [self revealView:self.guiInspiredIndicatorContainer delay:0.8];
        
    } else if (self.index == 2) {

        [self.guiContinueButton setTitle:LS(@"HELP_BUTTON_FINISH") forState:UIControlStateNormal];
        [self fadeInView:self.guiDisclaimerContainer delay:0.2];
        
    }
}

-(void)punchHoles
{
    UIView *viewWithHoles = self.guiDarkOverlay;
    
    CGRect bounds = viewWithHoles.bounds;
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = bounds;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    
    CGPoint point1;
    CGPoint point2;

    if (IS_IPAD) {
        // IPad (Retina and none retina)
        
    } else if (IS_16_9_LANDSCAPE) {
        // 16/9 screens (iPhone5, 5s, 5c)
        point1 = CGPointMake(191, 289);
        point2 = CGPointMake(534, 287);
    } else {
        // 4/3 screens (iPhone 4, 4s)
        point1 = CGPointMake(166, 289);
        point2 = CGPointMake(445, 287);
    }
    
    UIBezierPath *path = [UIBezierPath new];
    [self punchHoleInBounds:bounds atPoint:point1 radius:28 toPath:path];
    [self punchHoleInBounds:bounds atPoint:point2 radius:28 toPath:path];
    [path appendPath:[UIBezierPath bezierPathWithRect:bounds]];

    maskLayer.path = path.CGPath;
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    viewWithHoles.layer.mask = maskLayer;
}

-(void)punchHoleInBounds:(CGRect)bounds
                 atPoint:(CGPoint)point
                  radius:(CGFloat)radius
                  toPath:(UIBezierPath *)path
{
    CGRect const circleRect = CGRectMake(point.x - radius,
                                         point.y - radius,
                                         2 * radius,
                                         2 * radius);
    [path appendPath:[UIBezierPath bezierPathWithOvalInRect:circleRect]];
}

-(void)revealView:(UIView *)view delay:(CGFloat)delay
{
    view.alpha = 0;
    [UIView animateWithDuration:0.3/1.5 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
        view.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                view.transform = CGAffineTransformIdentity;
            }];
        }];
    }];
}

-(void)fadeInView:(UIView *)view delay:(CGFloat)delay
{
    [UIView animateWithDuration:0.3/1.5 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        view.alpha = 1;
    } completion:nil];
}

#pragma mark - Legal
-(void)dismissLegalNavcontroller:(UIBarButtonItem *)sender
{
    [self.legalNavVC dismissViewControllerAnimated:YES completion:nil];
}

-(void)pushTOSVC:(UIBarButtonItem *)sender
{
    [self.legalNavVC pushViewController:self.tosVC animated:YES];
}

-(void)pushPrivacyVC:(UIBarButtonItem *)sender
{
    
    [self.legalNavVC pushViewController:self.privacyVC animated:YES];
}

- (void)showTermsOfService
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissLegalNavcontroller:)];
    [self.legalNavVC setViewControllers:@[self.tosVC] animated:YES];
    self.tosVC.navigationItem.hidesBackButton = YES;
    self.tosVC.navigationItem.leftBarButtonItem = doneButton;
    UIBarButtonItem *privacyButton = [[UIBarButtonItem alloc] initWithTitle:@"Privacy Policy" style:UIBarButtonItemStylePlain target:self action:@selector(pushPrivacyVC:)];
    self.tosVC.navigationItem.rightBarButtonItem = privacyButton;
    self.tosVC.navigationItem.hidesBackButton = YES;
    [self presentViewController:self.legalNavVC animated:YES completion:nil];
}


- (void)showPrivacyPolicy
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissLegalNavcontroller:)];
    [self.legalNavVC setViewControllers:@[self.privacyVC] animated:YES];
    self.privacyVC.navigationItem.hidesBackButton = YES;
    self.privacyVC.navigationItem.leftBarButtonItem = doneButton;
    UIBarButtonItem *tosButton = [[UIBarButtonItem alloc] initWithTitle:@"Terms Of Service" style:UIBarButtonItemStylePlain target:self action:@selector(pushTOSVC:)];
    self.privacyVC.navigationItem.rightBarButtonItem = tosButton;
    self.privacyVC.navigationItem.hidesBackButton = YES;
    [self presentViewController:self.legalNavVC animated:YES completion:nil];
}

#pragma mark - Parental control delegate
-(void)parentalControlValidatedSuccessfully
{
    [self done];
}

-(void)parentalControlActionWithInfo:(NSDictionary *)info
{
    if ([info[@"action"] isEqualToString:@"privacy"]) {
        [self showPrivacyPolicy];
    } else if ([info[@"action"] isEqualToString:@"tos"]) {
        [self showTermsOfService];
    }
}


#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedNextButton:(id)sender
{
    [self hideAllAnimated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self next];
    });
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (IBAction)onTermsOfServicePushed:(id)sender
{
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissLegalNavcontroller:)];
//    [self.legalNavVC setViewControllers:@[self.tosVC] animated:YES];
//    self.tosVC.navigationItem.hidesBackButton = YES;
//    self.tosVC.navigationItem.leftBarButtonItem = doneButton;
//    UIBarButtonItem *privacyButton = [[UIBarButtonItem alloc] initWithTitle:@"Privacy Policy" style:UIBarButtonItemStylePlain target:self action:@selector(showPrivacy:)];
//    self.tosVC.navigationItem.rightBarButtonItem = privacyButton;
//    self.tosVC.navigationItem.hidesBackButton = YES;
//    [self presentViewController:self.legalNavVC animated:YES completion:nil];
}


- (IBAction)onPrivacyPolicyPushed:(id)sender
{
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissLegalNavcontroller:)];
//    [self.legalNavVC setViewControllers:@[self.privacyVC] animated:YES];
//    self.privacyVC.navigationItem.hidesBackButton = YES;
//    self.privacyVC.navigationItem.leftBarButtonItem = doneButton;
//    UIBarButtonItem *tosButton = [[UIBarButtonItem alloc] initWithTitle:@"Terms Of Service" style:UIBarButtonItemStylePlain target:self action:@selector(showTOS:)];
//    self.privacyVC.navigationItem.rightBarButtonItem = tosButton;
//    self.privacyVC.navigationItem.hidesBackButton = YES;
//    [self presentViewController:self.legalNavVC animated:YES completion:nil];
}

@end
