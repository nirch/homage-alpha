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

@property (weak, nonatomic) IBOutlet UILabel *guiSceneDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *guiSceneDurationPosition;

@property (weak, nonatomic) IBOutlet UILabel *guiGetInspiredLabel;
@property (weak, nonatomic) IBOutlet UIView *guiGetInspiredPosition;

@property (weak, nonatomic) IBOutlet UILabel *guiFigureLabel;
@property (weak, nonatomic) IBOutlet UIView *guiFigurePosition;

@property (weak, nonatomic) IBOutlet UILabel *guiWallLabel;
@property (weak, nonatomic) IBOutlet UIView *guiWallPosition;

@property (nonatomic) NSArray *labels;
@property (nonatomic) NSArray *positions;
@property (nonatomic) NSMutableArray *arrows;
@property (nonatomic) NSInteger index;
@property (nonatomic) NSArray *tutorials;

@end

@implementation HMRecorderTutorialViewController

@synthesize remakerDelegate = _remakerDelegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    self.index = 0;
    
    self.tutorials = @[
                       @[@0,@1],
                       @[@2,@3]
                       ];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [self initGUI];
    [self hideAllAnimated:NO];
}

-(void)viewWillDisappear:(BOOL)animated
{

}

-(void)initGUI
{
    self.labels = @[self.guiSceneDurationLabel,
                    self.guiGetInspiredLabel,
                    self.guiFigureLabel,
                    self.guiWallLabel];
    
    self.positions = @[self.guiSceneDurationPosition,
                       self.guiGetInspiredPosition,
                       self.guiFigurePosition,
                       self.guiWallPosition];
    
    self.arrows = [NSMutableArray new];
    
    for (NSInteger i=0;i<self.labels.count;i++) {
        [self.arrows addObject:[self createArrowForIndex:i]];
    }
    
    [self hideAllAnimated:NO];

}

-(void)hideAllAnimated:(BOOL)animated
{
    if (!animated) {
        for (UIView *view in self.positions) view.hidden = YES;
        for (UILabel *label in self.labels) label.alpha = 0;
        for (UIImageView *arrow in self.arrows) arrow.alpha = 0;
        return;
    }
    
    [UIView animateWithDuration:0.7 animations:^{
        [self hideAllAnimated:NO];
    }];
}

#pragma mark - Arrows
-(UIImageView *)createArrowForIndex:(NSInteger)index
{
    UIImage *image = [UIImage imageNamed:@"ToturialArrow"];
    UIImageView *arrow = [[UIImageView alloc] initWithImage:image];
    arrow.frame = CGRectMake(0, 0, image.size.width, image.size.height);

    UILabel *label = self.labels[index];
    UIView *position = self.positions[index];
    
    CGFloat x1 = label.center.x;
    CGFloat y1 = label.center.y;
    CGFloat x2 = position.center.x;
    CGFloat y2 = position.center.y;
    
    CGFloat x = (x1+x2)/2.0f;
    CGFloat y = (y1+y2)/2.0f;
    
    [self.view addSubview:arrow];
    
    arrow.center = CGPointMake(x, y);
    
    CGFloat angle = atan2( x2 - x1 , y1 - y2);
    
    arrow.transform = CGAffineTransformMakeRotation(angle);
    
    return arrow;
}

#pragma mark - Flow
-(void)start
{
    self.index = 0;
    [self showTutorialAtIndex:self.index];
}

-(void)next
{
    self.index++;
    [self showTutorialAtIndex:self.index];
}

-(void)done
{
    [self.remakerDelegate dismissOverlayAdvancingState:YES info:@{@"dismissing help screen":@YES}];
    
    User *user = [User current];
    user.skipRecorderTutorial = @YES;
}

#pragma mark - Showing tutorial messages
-(void)showTutorialAtIndex:(NSInteger)index
{
    [self hideAllAnimated:YES];

    if (self.index >= self.tutorials.count) {
        [self done];
        return;
    }
    
    NSArray *indexesToReveal = self.tutorials[index];

    for (NSNumber *indexNumber in indexesToReveal) {
        NSInteger index = indexNumber.integerValue;
        UILabel *label = self.labels[index];
        UIImageView *arrow = self.arrows[index];
        [self revealView:label delay:0.5];
        [self fadeInView:arrow delay:0.7];
    };
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
    [self next];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
