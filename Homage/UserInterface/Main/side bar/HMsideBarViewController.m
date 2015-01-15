//
//  HMSideBarViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSideBarViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "HMStyle.h"
#import "HMRegularFontButton.h"
#import "HMRegularFontLabel.h"
#import "HMRegularFontLabel.h"
#import "HMAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "AMBlurView.h"
#import "Mixpanel.h"
#import "HMNotificationCenter.h"
#import "NSNotificationCenter+Utils.h"
#import "HMServer+ReachabilityMonitor.h"
#import "HMServer+AppConfig.h"
#import "HMInAppStoreViewController.h"
#import "HMABTester.h"

@interface HMSideBarViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiStatusBarBG;

@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiStoriesButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiMeButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiSettingsButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiHowToButton;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiShareAppButton;
@property (strong, nonatomic) IBOutletCollection(HMRegularFontButton) NSArray *guiNavButtonsCollection;

@property (weak,nonatomic)  UIButton *selectedButton;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;

@property (weak, nonatomic) IBOutlet UIView *guiSideNavBarContainer;


@property (weak, nonatomic) IBOutlet UIView *guiNavTitleContainer;
@property (weak, nonatomic) IBOutlet UIImageView *guiUserIcon;
@property (weak, nonatomic) IBOutlet FBProfilePictureView *guiProfilePictureView;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiHelloUserLabel;
@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiJoinButton;

@property (strong, nonatomic) IBOutletCollection(HMRegularFontButton) NSArray *guiLoginActionsButtonCollection;

@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiLogoutButton;

@property (weak, nonatomic) IBOutlet HMRegularFontButton *guiStoreButton;


@property (weak, nonatomic) HMABTester *abTester;

@property (nonatomic) BOOL shouldAnimateStoreIcon;
@property (nonatomic) NSString *storeIconName;

@end

@implementation HMSideBarViewController

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
    [self initStrings];
    [self initGUI];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self initObservers];
}

-(void)storeIconAnimate {
    [UIView animateWithDuration:1.0
                          delay:0.0
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.guiStoreButton.transform = CGAffineTransformMakeScale(1.2, 1.1);
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:2.0
                                               delay:0
                                             options:UIViewAnimationOptionCurveLinear|UIViewAnimationOptionAllowUserInteraction
                                          animations:^{
                                              self.guiStoreButton.transform = CGAffineTransformIdentity;
                                          } completion:nil];
                     }];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeObservers];
}


-(void)initGUI
{
    // In app purchases button. Shown only if supported.
    self.guiStoreButton.hidden = ![HMServer.sh supportsInAppPurchases];
    
    // ************
    // *  STYLES  *
    // ************

    // Status 
    
    // Background color
    self.guiSideNavBarContainer.backgroundColor = [HMStyle.sh colorNamed:C_SIDE_NAV_BAR_BG];
    
    // Status bar background color
    self.guiStatusBarBG.backgroundColor = [HMStyle.sh colorNamed:C_STATUS_BAR_BG];
    
    // Nav Buttons
    UIColor *bottomBorderColor = [HMStyle.sh colorNamed:C_SIDE_NAV_BAR_SEPARATOR];
    for (UIButton *button in self.guiNavButtonsCollection) {
        [button setTitleColor:[HMStyle.sh colorNamed:C_SIDE_NAV_BAR_OPTION_TEXT] forState:UIControlStateNormal];
        button.clipsToBounds = YES;
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.borderColor = bottomBorderColor.CGColor;
        bottomBorder.borderWidth = 1;
        bottomBorder.frame = CGRectMake(0, button.frame.size.height - 1, button.frame.size.width,1);
        [button.layer addSublayer:bottomBorder];
        [self selectButton:self.guiStoriesButton];
    }
    
    // Top user name and buttons
    self.guiNavTitleContainer.backgroundColor = [HMStyle.sh colorNamed:C_SIDE_NAV_BAR_TOP_CONTAINER];
    self.guiHelloUserLabel.textColor = [HMStyle.sh colorNamed:C_SIDE_NAV_BAR_USER];
    for (UIButton *button in self.guiLoginActionsButtonCollection) {
        [button setTitleColor:[HMStyle.sh colorNamed:C_SIDE_NAV_BAR_LOGIN_BUTTON] forState:UIControlStateNormal];
    }
    
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addUniqueObserver:self selector:@selector(onSwitchedTab:) name:HM_MAIN_SWITCHED_TAB object:nil];
    [nc addUniqueObserver:self selector:@selector(onSideBarShown:) name:HM_NOTIFICATION_UI_SIDE_BAR_SHOWN object:nil];
    [nc addUniqueObserver:self selector:@selector(onABTestingVariantsUpdated:) name:HM_NOTIFICATION_AB_TESTING_VARIATIONS_UPDATED object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_MAIN_SWITCHED_TAB object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_UI_SIDE_BAR_SHOWN object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_AB_TESTING_VARIATIONS_UPDATED object:nil];
}

#pragma mark - Observers handlers
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

-(void)onSideBarShown:(NSNotification *)notification
{
    [self.abTester reportEventType:@"sidebarShown"];
    if (self.shouldAnimateStoreIcon)
        [self storeIconAnimate];
}

-(void)onABTestingVariantsUpdated:(NSNotification *)notification
{
    [self initABTesting];
}

#pragma mark - AB Testing
-(void)initABTesting
{
    HMAppDelegate *app = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.abTester = app.abTester;
    
    // Get the variant variables or use defaults.
    self.shouldAnimateStoreIcon = [self.abTester boolValueForProject:AB_PROJECT_STORE_ICONS
                                                             varName:@"storeIconAnimation"
                                               hardCodedDefaultValue:NO];
    
    self.storeIconName = [self.abTester stringValueForProject:AB_PROJECT_STORE_ICONS
                                                      varName:@"storeIconName"
                                        hardCodedDefaultValue:@"storeIcon1"];
    
    // Set the store icon.
    UIImage *buttonImage = [UIImage imageNamed:self.storeIconName];
    [self.guiStoreButton setImage:buttonImage
                         forState:UIControlStateNormal];
}

#pragma mark - Localized strings
-(void)initStrings
{
    [self.guiStoriesButton setTitle:LS(@"NAV_STORIES_BUTTON") forState:UIControlStateNormal];
    [self.guiMeButton setTitle:LS(@"NAV_MY_STORIES_BUTTON") forState:UIControlStateNormal];
    [self.guiSettingsButton setTitle:LS(@"NAV_SETTINGS_BUTTON") forState:UIControlStateNormal];
    [self.guiHowToButton setTitle:LS(@"NAV_HOWTO_BUTTON") forState:UIControlStateNormal];
    [self.guiShareAppButton setTitle:LS(@"NAV_SHARE_APP_BUTTON") forState:UIControlStateNormal];
}


#pragma mark - (Give some logical order to yoav's mess)
-(void)selectButton:(UIButton *)sender
{
    [UIView animateWithDuration:0.1 animations:
     ^{
         [self.selectedButton setBackgroundColor:[UIColor clearColor]];
         //[sender setBackgroundColor:[[HMColor.sh textImpact] colorWithAlphaComponent:0.5]];
     }];
    
    self.selectedButton = sender;
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
    NSString *urlIOS;
    NSString *urlAndroid;
    
    if (IS_TEST_APP) {
        // Release, but just a beta test application.
        urlIOS = [HMServer.sh absoluteURLNamed:@"test_download_app_ios_url"];
        urlAndroid = [HMServer.sh absoluteURLNamed:@"test_download_app_android_url"];
    } else {
        // Release app for production.
        urlIOS = [HMServer.sh absoluteURLNamed:@"prod_download_app_ios_url"];
        urlAndroid = [HMServer.sh absoluteURLNamed:@"prod_download_app_android_url"];
    }
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

#pragma mark - In App Store
-(void)openInAppStore
{
    HMInAppStoreViewController *vc = [HMInAppStoreViewController storeVC];
    vc.delegate = self;
    vc.openedFor = HMStoreOpenedForSideBarStoreButton;
    [self presentViewController:vc animated:YES completion:nil];
}

#pragma mark - HMStoreDelegate
-(void)storeDidFinishWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:^{
        // Do something here (if required) when the in app store is dismissed.
    }];
    
    // Check the info returned from the store.
    if (info == nil) return;
    
    // AB Test (conversion - user made a purchase in the store in current session)
    // Report that the user purchased something while in store.
    HMStoreOpenedFor storeOpenedFor = [info[K_STORE_OPENED_FOR] integerValue];
    if (storeOpenedFor != HMStoreOpenedForSideBarStoreButton) return;
    NSInteger purchasesMade = [info[K_STORE_PURCHASES_COUNT] integerValue];
    if (purchasesMade > 0) {
        // At least one purchase was made.
        // Report about it as a conversion event.
        [self.abTester reportEventType:@"userPurchasedItemAfterPressingStoreButton"];
    }
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onLogoutButtonPushed:(HMRegularFontButton *)sender
{
    [self.delegate logoutPushed];
}

- (IBAction)onJoinButtonPushed:(HMRegularFontButton *)sender
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
    [[Mixpanel sharedInstance] track:@"UserPressedShareApp"];
    [self shareApp];
}

- (IBAction)onPressedMonkeyShop:(id)sender
{
    // Report to AB testing service
    // TODO: remove this when experiment is over.
    [self.abTester reportEventType:@"userPressedStoreButton"];
    
    // Report to mixpanel
    [[Mixpanel sharedInstance] track:@"StoreSideBarButtonClicked"];

    // Open the in app store.
    [self openInAppStore];
}

@end
