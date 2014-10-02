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
#import "HMRegularFontButton.h"
#import "HMAvenirBookFontLabel.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AMBlurView.h"
#import "Mixpanel.h"
#import "HMNotificationCenter.h"
#import "NSNotificationCenter+Utils.h"
#import "HMServer+ReachabilityMonitor.h"

@interface HMsideBarViewController ()

@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiStoriesButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiMeButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiSettingsButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiHowToButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiShareAppButton;
@property (strong, nonatomic) IBOutletCollection(HMRegularFontButton) NSArray *tabButtonCollection;

@property (weak,nonatomic)  UIButton *selectedButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;


@property (weak, nonatomic) IBOutlet UIImageView *guiUserIcon;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *guiProfilePictureView;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiHelloUserLabel;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiJoinButton;

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

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initObservers];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}

-(void)initObservers
{
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self selector:@selector(onSwitchedTab:) name:HM_MAIN_SWITCHED_TAB object:nil];
    
    /*[[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onReachabilityStatusChange:)
                                                       name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE
                                                     object:nil];*/
}

-(void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HM_MAIN_SWITCHED_TAB object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:HM_NOTIFICATION_SERVER_REACHABILITY_STATUS_CHANGE object:nil];
}

-(void)initGUI
{
    for (HMAvenirBookFontButton *button in self.tabButtonCollection)
    {
        button.clipsToBounds = YES;
        
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.borderColor = [UIColor blackColor].CGColor;
        bottomBorder.borderWidth = 1;
        bottomBorder.frame = CGRectMake(0, button.frame.size.height - 1, button.frame.size.width,1);
        [button.layer addSublayer:bottomBorder];
        
        [self selectButton:self.guiStoriesButton];
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

-(void)onReachabilityStatusChange:(NSNotification *)notification
{
    for (UIButton *button in self.loginActionsButtonCollection)
    {
        //[button setEnabled:HMServer.sh.isReachable];
        button.enabled = HMServer.sh.isReachable;
    }
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

-(void)onSwitchedTab:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSNumber *tabIndex = info[@"tab"];
    NSInteger tabIndexInt = tabIndex.integerValue;
    
    switch (tabIndexInt) {
        case HMStoriesTab:
            [self onStoriesButtonPushed:self.guiStoriesButton];
            break;
        case HMMeTab:
            [self onMeButtonPushed:self.guiMeButton];
            break;
        case HMSettingsTab:
            [self onSettingsButtonPushed:self.guiSettingsButton];
            break;
        default:
            break;
    }
}

-(void)updateSideBarGUIWithName:(NSString *)userName FBProfile:(NSString *)fbProfileID
{
    self.guiProfilePictureView.profileID = fbProfileID;
    self.guiProfilePictureView.hidden = fbProfileID == nil;
    self.guiUserIcon.hidden = !self.guiProfilePictureView.hidden;
    
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

-(void)shareApp
{
    //
    // Get the urls for downloading iOS and android app from CFG file
    //
    #ifndef DEBUG
        NSString *urlIOS = [HMServer.sh absoluteURLNamed:@"prod_download_app_ios_url"];
        NSString *urlAndroid = [HMServer.sh absoluteURLNamed:@"prod_download_app_android_url"];
    #else
        NSString *urlIOS = [HMServer.sh absoluteURLNamed:@"test_download_app_ios_url"];
        NSString *urlAndroid = [HMServer.sh absoluteURLNamed:@"test_download_app_android_url"];
    #endif

    // Build the message text.
    NSString *sharingBodyText = [NSString stringWithFormat:LS(@"SHARING_APP_BODY_MESSAGE"), urlIOS, urlAndroid];
    NSString *sharingTitleText = LS(@"SHARING_APP_SUBJECT");
    
    // Open sharing activity.
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[sharingBodyText] applicationActivities:nil];
    [activityController setValue:sharingTitleText forKey:@"subject"];
    activityController.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList];
    [self presentViewController:activityController animated:YES completion:nil];

}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onLogoutButtonPushed:(HMAvenirBookFontButton *)sender
{
    [self.delegate logoutPushed];
}

- (IBAction)onJoinButtonPushed:(HMAvenirBookFontButton *)sender
{
    [self.delegate joinButtonPushed];
}

- (IBAction)onStoriesButtonPushed:(id)sender
{
    [self selectButton:sender];
    [[Mixpanel sharedInstance] track:@"UserPressedStoriesTab"];
    if ([self.delegate respondsToSelector:@selector(storiesButtonPushed)])
        [self.delegate storiesButtonPushed];
}

- (IBAction)onMeButtonPushed:(id)sender
{
    [self selectButton:sender];
    [[Mixpanel sharedInstance] track:@"UserPressedmeTab"];
    if ([self.delegate respondsToSelector:@selector(meButtonPushed)])
        [self.delegate meButtonPushed];
}

- (IBAction)onSettingsButtonPushed:(id)sender
{
    [self selectButton:sender];
    [[Mixpanel sharedInstance] track:@"UserPressedSettingsTab"];
    if ([self.delegate respondsToSelector:@selector(settingsButtonPushed)])
        [self.delegate settingsButtonPushed];
}

- (IBAction)onHowToButtonPushed:(UIButton *)sender
{
    [[Mixpanel sharedInstance] track:@"UserPressedIntroStoryTab"];
    if ([self.delegate respondsToSelector:@selector(howToButtonPushed)])
        [self.delegate howToButtonPushed];
}

- (IBAction)onShareAppButtonPushed:(UIButton *)sender {
    [self shareApp];
}


@end
