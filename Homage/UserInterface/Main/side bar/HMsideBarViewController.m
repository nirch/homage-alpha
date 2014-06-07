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
#import "HMAvenirBookFontButton.h"
#import "HMAvenirBookFontLabel.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AMBlurView.h"
#import "Mixpanel.h"

@interface HMsideBarViewController ()

@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *storiesButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *settingsButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *meButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *howToButton;
@property (weak,nonatomic)  UIButton *selectedButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;


@property (weak, nonatomic) IBOutlet FBProfilePictureView *guiProfilePictureView;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiHelloUserLabel;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiJoinButton;
@property (strong, nonatomic) IBOutletCollection(HMAvenirBookFontButton) NSArray *tabButtonCollection;
@property (strong, nonatomic) IBOutletCollection(HMAvenirBookFontButton) NSArray *loginActionsButtonCollection;

@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiLogoutButton;


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

    //self.guiBGImageView.image = [self.guiBGImageView.image applyBlurWithRadius:10.0 tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.8] saturationDeltaFactor:0.3 maskImage:nil];
    [[AMBlurView new] insertIntoView:self.guiBlurredView];
    
    [self.guiHelloUserLabel setTextColor:[HMColor.sh textImpact]];
    
    for (HMAvenirBookFontButton *button in self.tabButtonCollection)
    {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        
        button.clipsToBounds = YES;
        
        CALayer *bottomBorder = [CALayer layer];
        
        bottomBorder.borderColor = [HMColor.sh greyLine].CGColor;
        bottomBorder.borderWidth = 1;
        bottomBorder.frame = CGRectMake(0, button.frame.size.height - 1, button.frame.size.width,1);
        
        [button.layer addSublayer:bottomBorder];
        
        [self selectButton:self.storiesButton];
    }
    
    for (HMAvenirBookFontButton *button in self.loginActionsButtonCollection)
    {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)storiesButtonPushed:(id)sender
{
    [self selectButton:sender];
    [[Mixpanel sharedInstance] track:@"UserPressedStoriesTab"];
    if ([self.delegate respondsToSelector:@selector(storiesButtonPushed)])
        [self.delegate storiesButtonPushed];
}

- (IBAction)meButtonPushed:(id)sender
{
    [self selectButton:sender];
    [[Mixpanel sharedInstance] track:@"UserPressedmeTab"];
    if ([self.delegate respondsToSelector:@selector(meButtonPushed)])
        [self.delegate meButtonPushed];
}

- (IBAction)settingsButtonPushed:(id)sender
{
    [self selectButton:sender];
    [[Mixpanel sharedInstance] track:@"UserPressedSettingsTab"];
    if ([self.delegate respondsToSelector:@selector(settingsButtonPushed)])
        [self.delegate settingsButtonPushed];
}

- (IBAction)HowToPushed:(UIButton *)sender
{
    [[Mixpanel sharedInstance] track:@"UserPressedIntroStoryTab"];
    if ([self.delegate respondsToSelector:@selector(howToButtonPushed)])
        [self.delegate howToButtonPushed];
}

-(void)selectButton:(UIButton *)sender
{
    [UIView animateWithDuration:0.1 animations:
     ^{
         [self.selectedButton setBackgroundColor:[UIColor clearColor]];
         [sender setBackgroundColor:[[HMColor.sh textImpact] colorWithAlphaComponent:0.5]];
     }];
    
    self.selectedButton = sender;
}

- (IBAction)logoutButtonPushed:(HMAvenirBookFontButton *)sender
{
    [self.delegate logoutPushed];
}

- (IBAction)joinButtonPushed:(HMAvenirBookFontButton *)sender
{
    [self.delegate joinButtonPushed];
}

-(void)updateSideBarGUIWithName:(NSString *)userName FBProfile:(NSString *)fbProfileID
{
    self.guiProfilePictureView.profileID = fbProfileID;
    self.guiHelloUserLabel.text = [NSString stringWithFormat:LS(@"HELLO_USER") , userName];
    if (![userName isEqualToString:@"Guest"])
    {
        self.guiJoinButton.hidden = YES;
        self.guiLogoutButton.hidden = NO;
    } else
    {
        self.guiJoinButton.hidden = NO;
        self.guiLogoutButton.hidden = YES;
    }
}
@end
