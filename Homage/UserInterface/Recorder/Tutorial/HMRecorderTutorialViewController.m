//
//  HMRecorderTutorialViewController.m
//  Homage
//
//  Created by Aviv Wolf on 3/2/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderTutorialViewController.h"

#import "DB.h"

@interface HMRecorderTutorialViewController ()

@property (nonatomic) NSInteger index;

@property (weak, nonatomic) IBOutlet UIView *guiDarkOverlay;
@property (weak, nonatomic) IBOutlet UIView *guiSilIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIView *guiSolidBGIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIView *guiSceneIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIView *guiInspiredIndicatorContainer;
@property (weak, nonatomic) IBOutlet UIButton *guiContinueButton;

@property (weak, nonatomic) IBOutlet UILabel *guiSceneDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiUseSolidBGLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiPlaceActorHereLabel;
@property (weak, nonatomic) IBOutlet UILabel *guiGetInspiredLabel;

@end

@implementation HMRecorderTutorialViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.index = 0;
    [self hideAllAnimated:NO];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

-(void)initGUI
{
    self.guiSceneDurationLabel.text = LS(@"HELP_LABEL_SCENE_DURATION");
    self.guiUseSolidBGLabel.text = LS(@"HELP_LABEL_SOLID_BG");
    self.guiPlaceActorHereLabel.text = LS(@"HELP_LABEL_PLACE_ACTOR");
    self.guiGetInspiredLabel.text = LS(@"HELP_LABEL_GET_INSPIRED");
}

-(void)hideAllAnimated:(BOOL)animated
{
    if (!animated) {
        self.guiContinueButton.alpha = 0;
        self.guiDarkOverlay.alpha = 0;
        self.guiInspiredIndicatorContainer.alpha = 0;
        self.guiSceneIndicatorContainer.alpha = 0;
        self.guiSilIndicatorContainer.alpha = 0;
        self.guiSolidBGIndicatorContainer.alpha = 0;
        return;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        [self hideAllAnimated:NO];
    }];
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

#pragma mark - Showing tutorial messages
-(void)handleState
{
    if (self.index >= 2) {
        [self done];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showTutorialForCurrentIndex];
    });
}

-(void)showTutorialForCurrentIndex
{
    [self fadeInView:self.guiDarkOverlay delay:0.0];
    [self fadeInView:self.guiContinueButton delay:0.3];
    if (self.index==0) {
        [self.guiContinueButton setTitle:LS(@"HELP_BUTTON_NEXT") forState:UIControlStateNormal];
        [self revealView:self.guiSolidBGIndicatorContainer delay:0.0];
        [self fadeInView:self.guiSilIndicatorContainer delay:0.8];
    } else if (self.index==1) {
        [self.guiContinueButton setTitle:LS(@"HELP_BUTTON_FINISH") forState:UIControlStateNormal];
        
        // Punch holes in the dark overlay
        [self punchHoles];
        
        // Reveal indicators
        [self revealView:self.guiSceneIndicatorContainer delay:0.4];
        [self revealView:self.guiInspiredIndicatorContainer delay:0.8];
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

    // TODO: support iPhone 6, 6 Plus, iPads layouts
    if (IS_16_9_LANDSCAPE) {
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

@end
