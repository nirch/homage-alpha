//
//  HMsideBarViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMsideBarViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMColor.h"
#import "HMFontButton.h"

@interface HMsideBarViewController ()

@property (weak, nonatomic) IBOutlet HMFontButton *storiesButton;
@property (weak, nonatomic) IBOutlet HMFontButton *settingsButton;
@property (weak, nonatomic) IBOutlet HMFontButton *meButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;

@property (strong, nonatomic) IBOutletCollection(HMFontButton) NSArray *buttonCollection;

@end

@implementation HMsideBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
	// Do any additional setup after loading the view.
}

-(void)initGUI
{
   self.guiBGImageView.image = [self.guiBGImageView.image applyBlurWithRadius:4.0 tintColor:nil saturationDeltaFactor:0.0
 maskImage:nil];
    [self.guiBGImageView addMotionEffectWithAmount:-30];
    for (HMFontButton *button in self.buttonCollection)
    {
        [button setTitleColor:[HMColor.sh textImpact] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"DINOT-regular" size:button.titleLabel.font.pointSize];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)storiesButtonPushed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(storiesButtonPushed)])
        [self.delegate storiesButtonPushed];
}

- (IBAction)meButtonPushed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(meButtonPushed)])
        [self.delegate meButtonPushed];
}

- (IBAction)settingsButtonPushed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(settingsButtonPushed)])
        [self.delegate settingsButtonPushed];
}

@end
