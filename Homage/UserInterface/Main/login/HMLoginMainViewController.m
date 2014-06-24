//
//  HMLoginMainViewController.m
//  Homage
//
//  Created by Yoav Caspin on 3/13/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMLoginMainViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "HMNotificationCenter.h"
#import "HMServer+Users.h"
#import "DB.h"
#import "Mixpanel.h"
#import "HMAppDelegate.h"
#import "HMIntroMovieViewController.h"
#import "HMIntroMovieDelagate.h"
#import "UIImage+ImageEffects.h"
#import "HMAvenirBookFontButton.h"
#import "HMAvenirBookFontLabel.h"
#import "HMColor.h"
#import "HMTOSViewController.h"
#import "HMPrivacyPolicyViewController.h"
#import "HMServer+ReachabilityMonitor.h"
#import "AMBlurView.h"


typedef NS_ENUM(NSInteger, HMMethodOfLogin) {
    HMFaceBookConnect,
    HMMailConnect,
    HMGuest,
    HMTwitterConnect,
};

typedef NS_ENUM(NSInteger, HMLoginError) {
    HMUnknownMailAddress,
    HMIncorrectPassword,
    HMBadPassword,
    HMIncorrectMailAddressFormat,
    HMMailAddressAlreadyTaken,
    HMExistingFacebookUser,
    HMNoConnectivity,
    HMUnknownError,
};


@interface HMLoginMainViewController () <FBLoginViewDelegate,UITextFieldDelegate,HMIntroMovieDelegate>


@property (weak, nonatomic) IBOutlet UIView *guiIntroMovieContainerView;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiSignupButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiLoginButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiGuestButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiForgotPasswordButton;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontButton *guiCancelButton;
@property (weak, nonatomic) IBOutlet UITextField *guiMailTextField;
@property (weak, nonatomic) IBOutlet UITextField *guiPasswordTextField;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *guiLoginErrorLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *guiSignUpView;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;
@property (weak, nonatomic) IBOutlet UIView *guiBlurredView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivityView;

@property (strong, nonatomic) IBOutletCollection(HMAvenirBookFontButton) NSArray *buttonCollection;
@property (strong, nonatomic) IBOutletCollection(HMAvenirBookFontLabel) NSArray *labelCollection;


@property (strong , nonatomic) id<FBGraphUser> cachedUser;
@property (strong,nonatomic) HMIntroMovieViewController *introMovieController;
@property (nonatomic) BOOL userJoinFlow;
@property (nonatomic) UINavigationController *legalNavVC;
@property (nonatomic) HMTOSViewController *tosVC;
@property (nonatomic) HMPrivacyPolicyViewController *privacyVC;

@property NSString *loginMethod;

@end

@implementation HMLoginMainViewController

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    [super viewDidLoad];
    
    self.userJoinFlow = NO;
    
    
    //FBloginView
    FBLoginView *loginView = [[FBLoginView alloc] initWithReadPermissions:@[@"email",@"user_birthday",@"public_profile"]];
    loginView.delegate = self;
    
    // Align the button in the center horizontally
    loginView.frame = CGRectMake(54, 110, 212, 50);
    
    // Align the button in the center vertically
    //loginView.center = self.guiSignUpView.center;
    
    // Add the button to the view
    [self.guiSignUpView addSubview:loginView];
    
    [self initGUI];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.tosVC = [[HMTOSViewController alloc] init];
    self.privacyVC = [[HMPrivacyPolicyViewController alloc] init];
    self.legalNavVC = [[UINavigationController alloc] init];
    [self initObservers];
    self.guiLoginErrorLabel.alpha = 0;
    self.guiLoginErrorLabel.hidden = YES;
    self.guiLoginErrorLabel.text = @"";
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self.guiActivityView stopAnimating];
    self.guiActivityView.hidden = YES;
    [self removeObservers];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)initGUI
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiIntroMovieContainerView.alpha = 0;
    self.guiIntroMovieContainerView.hidden = YES;
    self.guiLoginErrorLabel.alpha = 0;
    self.guiLoginErrorLabel.hidden = YES;
    self.guiLoginErrorLabel.text = @"";
    self.guiGuestButton.hidden = NO;
    self.guiCancelButton.hidden = YES;
    
    //self.guiBGImageView.image = [self.guiBGImageView.image applyBlurWithRadius:7.0 tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.6] saturationDeltaFactor:0.3 maskImage:nil];
    [[AMBlurView new] insertIntoView:self.guiBlurredView];
    
    for (HMAvenirBookFontButton *button in self.buttonCollection)
    {
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    
    for (HMAvenirBookFontLabel *label in self.labelCollection)
    {
        [label setTextColor:[UIColor whiteColor]];
    }
    
    //[self.guiSignupButton setTitleColor:[HMColor.sh textImpact] forState:UIControlStateNormal];
    
    //text field stuff
    self.guiMailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.guiMailTextField.returnKeyType = UIReturnKeyDone;
    self.guiPasswordTextField.returnKeyType = UIReturnKeyDone;
    self.guiPasswordTextField.secureTextEntry = YES;
    self.guiMailTextField.delegate = self;
    self.guiPasswordTextField.delegate = self;
    
    //sign up scrool view stuff
    self.guiSignUpView.contentSize = self.guiSignUpView.frame.size;
    self.guiSignUpView.scrollEnabled = NO;
    
    //TODO: hide forgot pass for now
    self.guiForgotPasswordButton.hidden = YES;
    
    //activity view
    self.guiActivityView.hidden = YES;
    [self.guiActivityView stopAnimating];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);

}

-(void)initObservers
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    // Observe creation of user
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserCreated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_CREATION
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserUpdated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_UPDATED
                                                     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)removeObservers
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_CREATION object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_UPDATED object:nil];
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(BOOL)checkCredentials
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSString *emailAddress = self.guiMailTextField.text;
    
    /*
    // TODO: REMOVE!!!!! Ran's hack - always using the Test environment
    if ([emailAddress isEqualToString:@"ranpeer@gmail.com"])
    {
        [[HMServer sh] ranHack];
    }
    */
    
    BOOL isMailCorrectFormat = [self validateEmail:emailAddress];
    
    if (!isMailCorrectFormat)
    {
        [self presentErrorLabelWithReason:HMIncorrectMailAddressFormat];
        HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
        return NO;
    }
    
    NSString *password = self.guiPasswordTextField.text;
    BOOL isPasswordCorrectFormat = [self validatePassword:password];
    if (!isPasswordCorrectFormat)
    {
        [self presentErrorLabelWithReason:HMBadPassword];
        HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
        return NO;
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    
    return YES;
}

-(BOOL)validatePassword:(NSString *)password
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if ([password length] < 4) return NO;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return YES;
}

-(void)presentErrorLabelWithReason:(NSInteger)reason
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    switch (reason) {
        case HMUnknownMailAddress:
            [self showErrorLabelWithString:LS(@"UNKNOWN_MAIL_ADDRESS")];
            break;
        case HMIncorrectPassword:
            [self showErrorLabelWithString:LS(@"INCORRECT_PASSWORD")];
            break;
        case HMIncorrectMailAddressFormat:
            [self showErrorLabelWithString:LS(@"INCORRECT_EMAIL_ADDRESS_FORMAT")];
            break;
        case HMBadPassword:
            [self showErrorLabelWithString:LS(@"UNSUFFICIENT_PASSWORD")];
             break;
        case HMMailAddressAlreadyTaken:
            [self showErrorLabelWithString:LS(@"EMAIL_TAKEN")];
            break;
        case HMExistingFacebookUser:
            [self showErrorLabelWithString:LS(@"EXISTING_FACEBOOK_USER")];
            break;
        case HMNoConnectivity:
            [self showErrorLabelWithString:LS(@"NO_CONNECTIVITY")];
            break;
        case HMUnknownError:
            [self showErrorLabelWithString:LS(@"UNKNOWN_ERROR")];
            break;
        default:
            break;
    }
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)showErrorLabelWithString:(NSString *)errorString
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiLoginErrorLabel.hidden = NO;
    self.guiLoginErrorLabel.text = errorString;
    [UIView animateWithDuration:0.3 animations:^{
        self.guiLoginErrorLabel.alpha = 1;
    }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)hideErrorLabel
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if (self.guiLoginErrorLabel.hidden) return;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.guiLoginErrorLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.guiLoginErrorLabel.hidden = YES;
    }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}



-(IBAction)onPressedSignUpLogin:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.loginMethod = @"mail";
    self.guiLoginErrorLabel.text = @"";
    
    if (!HMServer.sh.isReachable)
    {
        [self presentErrorLabelWithReason:HMNoConnectivity];
        return;
    }
    
    if (![self checkCredentials]) return;
    
    [self.view endEditing:YES];
    NSDictionary *deviceInfo = [self getDeviceInformation];
    NSDictionary *mailSignUpDictionary = @{@"email" : self.guiMailTextField.text , @"password" : self.guiPasswordTextField.text , @"is_public" : @YES , @"device" : deviceInfo };
    
    if (!self.userJoinFlow)
    {
       [HMServer.sh createUserWithDictionary:mailSignUpDictionary];
    } else if(self.userJoinFlow && [User current])
    {
        NSDictionary *mailSignUpDictionary = @{@"user_id" : [User current].userID , @"email" : self.guiMailTextField.text , @"password" : self.guiPasswordTextField.text , @"is_public" : @YES , @"device" : deviceInfo};
        [HMServer.sh updateUserUponJoin:mailSignUpDictionary];
    }
    
    self.guiMailTextField.text = @"";
    self.guiPasswordTextField.text = @"";

    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (IBAction)onPressedGuest:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.loginMethod = @"guest";
    
    if (!HMServer.sh.isReachable)
    {
        [self presentErrorLabelWithReason:HMNoConnectivity];
        return;
    }
    
    [self.view endEditing:YES];
    NSDictionary *deviceInfo = [self getDeviceInformation];
    NSDictionary *guestDictionary = @{@"is_public" : @NO , @"device" : deviceInfo};
    [HMServer.sh createUserWithDictionary:guestDictionary];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onLoginPressedSkip
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self hideIntroMovieView];
    [self.delegate dismissLoginScreen];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onLoginPressedShootFirstStory
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self hideIntroMovieView];
    [self.delegate dismissLoginScreen];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(void)onUserCreated:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);

    if (notification.isReportingError)
    {
        NSDictionary *userInfo = notification.userInfo;
        NSError *error = userInfo[@"error"];
        NSDictionary *body = error.userInfo[@"body"];
        long errorCode = [body[@"error_code"] longValue];
        
        switch (errorCode) {
            case 1001: //incorrect password
                [self presentErrorLabelWithReason:HMIncorrectPassword];
                return;
                break;
            case 1004: //existing fb user
                [self presentErrorLabelWithReason:HMExistingFacebookUser];
                return;
                break;
            default:
                [self presentErrorLabelWithReason:HMUnknownError];
                return;
                break;
        }
    }

    NSDictionary *userInfo = notification.userInfo;
    NSString *userID = userInfo[@"userID"];
    HMGLogDebug(@"user created with userID: %@" , userID);
    
    User *user = [User userWithID:userID inContext:DB.sh.context];
    
    // This makes the current ID (an auto-generated GUID)
    // and 'joe@example.com' interchangeable distinct ids.
    
    //[mixpanel createAlias:user.userID
      //      forDistinctID:mixpanel.distinctId];
    
    // You must call identify if you haven't already
    // (e.g., when your app launches).
    //[mixpanel identify:mixpanel.distinctId];
    
    //IMPORTANT !!!! this must be called before changing the user isfirstuse property further on!
    [self registerLoginAnalyticsForUser:user];
    
    [user loginInContext:DB.sh.context];
    [HMServer.sh updateServerContext:user.userID];
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_REFRESH_USER_DATA object:nil userInfo:nil];
    [[NSUserDefaults standardUserDefaults] setBool:user.isPublic.boolValue forKey:@"remakesArePublic"];
    
    if (user.isGuestUser)
    {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"remakesArePublic"];
    }
    
    if (user.isFirstUse.boolValue)
    {
        user.isFirstUse = @NO;
        [self displayIntroMovieView];
    } else {
        [self.delegate dismissLoginScreen];
    }
    
    [DB.sh save];
    [self.delegate onUserLoginStateChange:user];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onUserUpdated:(NSNotification *)notification
{

    if (notification.isReportingError)
    {
        NSDictionary *userInfo = notification.userInfo;
        NSError *error = userInfo[@"error"];
        NSDictionary *body = error.userInfo[@"body"];
        long errorCode = [body[@"error_code"] longValue];
        
        switch (errorCode) {
            case 1001: //incorrect password
                [self presentErrorLabelWithReason:HMIncorrectPassword];
                return;
                break;
            case 1004:
                [self presentErrorLabelWithReason:HMExistingFacebookUser];
                return;
                break;
            default:
                [self presentErrorLabelWithReason:HMUnknownError];
                return;
                break;
        }
    }
    
    NSDictionary *userInfo = notification.userInfo;
    NSString *userID = userInfo[@"userID"];
    User *user = [User userWithID:userID inContext:DB.sh.context];
    
    //mixpanel analitics
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    //this is a case where a user got a user id as guest, signed up with any non guest signup method, and then got a previous user id from previous uses
    if (![user.userID isEqualToString:[User current].userID])
    {
        [mixpanel createAlias:user.userID
                forDistinctID:[User current].userID];
        [mixpanel identify:user.userID];
    }
    
    if (user.email)
    {
        [mixpanel registerSuperProperties:@{@"email": user.email , @"homage_id": user.userID}];
        [mixpanel.people set:@{@"user" : user.email , @"homage_id":user.userID}];
        
        //this excludes us from being tracked on mixpanel
        if ([self shouldExcludethisAdressFromMixpanelData:user.email])
        {
            [mixpanel registerSuperProperties:@{@"$ignore": @"true"}];
        }
    } else {
        [mixpanel registerSuperProperties:@{@"email" : @"unknown" , @"homage_id" : user.userID}];
        [mixpanel.people set:@{@"homage_id":user.userID}];
    }
    [mixpanel track:@"UserUpdate" properties:@{@"login_method" : self.loginMethod}];
    
    //when a user upgrades from guest to fb or mail, his default sharing prefrence is public
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"remakesArePublic"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_REFRESH_USER_DATA object:nil userInfo:nil];
    
    [user loginInContext:DB.sh.context];
    [HMServer.sh updateServerContext:user.userID];
    [self.delegate onUserLoginStateChange:[User current]];
    [self.delegate dismissLoginScreen];
    self.userJoinFlow = NO;
}

-(void)displayIntroMovieView
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiIntroMovieContainerView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^
     {
         self.guiIntroMovieContainerView.alpha = 1;
         self.guiSignUpView.alpha = 0;
     } completion:^(BOOL finished)
     {
         self.guiSignUpView.hidden = YES;
         [self.introMovieController initIntroMoviePlayer];
     }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)hideIntroMovieView
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.guiSignUpView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^
    {
        self.guiIntroMovieContainerView.alpha = 0;
        self.guiSignUpView.alpha = 1;
    } completion:^(BOOL finished)
    {
        self.guiIntroMovieContainerView.hidden = YES;
        [self.introMovieController stopMoviePlayer];
    }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [textField resignFirstResponder];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return YES;
}


#pragma mark Text Field/Keyboard stuff
-(void)keyboardWasShown:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSDictionary* info = notification.userInfo;
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height + 80, 0.0);
    self.guiSignUpView.contentInset = contentInsets;
    self.guiSignUpView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.guiMailTextField.frame.origin) ) {
        [self.guiSignUpView scrollRectToVisible:self.guiMailTextField.frame animated:YES];
    }
    self.guiLoginErrorLabel.hidden = YES;
    self.guiLoginErrorLabel.text = @"";
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)keyboardWillBeHidden:(NSNotification *)notification
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.guiSignUpView.contentInset = contentInsets;
    self.guiSignUpView.scrollIndicatorInsets = contentInsets;
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (BOOL) validateEmail:(NSString *)emailAddress {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailAddress];
}


-(NSDictionary *)getDeviceInformation
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    UIDevice *device = [UIDevice currentDevice];
    
    NSDictionary *deviceDictionary =  @{@"name" : device.name , @"system_name" : device.systemName , @"system_version" : device.systemVersion , @"model" : device.model , @"identifier_for_vendor" : [device.identifierForVendor UUIDString]};
    
    HMAppDelegate *myDelegate = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSData *pushToken = myDelegate.pushToken;
    
    if (pushToken)
    {
        deviceDictionary =  @{@"name" : device.name , @"system_name" : device.systemName , @"system_version" : device.systemVersion , @"model" : device.model , @"identifier_for_vendor" : [device.identifierForVendor UUIDString] , @"push_token" : pushToken};
    }
        
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return deviceDictionary;
}

+(HMLoginMainViewController *)instantiateLoginScreen
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"OnBoarding" bundle:nil];
    HMLoginMainViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginMainVC"];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
    return vc;
}

-(void)onUserLogout
{
    if ([self.loginMethod isEqualToString: @"facebook"])
    {
        if (FBSession.activeSession.state == FBSessionStateOpen
            || FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
        {
            
            // Close the session and remove the access token from the cache
            // The session state handler (in the app delegate) will be called automatically
            [FBSession.activeSession closeAndClearTokenInformation];
        }
        self.cachedUser = nil;
    }
    
    self.guiGuestButton.hidden = NO;
    self.guiCancelButton.hidden = YES;
}

-(void)onUserJoin
{
    self.guiGuestButton.hidden = YES;
    self.guiCancelButton.hidden = NO;
    self.userJoinFlow = YES;
}

#pragma mark FBLoginView delegate
-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                           user:(id<FBGraphUser>)user
{
    
    HMGLogInfo(@"fb login view fetched user info start");
    //[self.guiActivityView stopAnimating];
    //self.guiActivityView.hidden = YES;
    
    
    if ([self isFacebookUser:self.cachedUser equalToFacebookUser:user])
    {
        [self.delegate dismissLoginScreen];
        [self hideIntroMovieView];
        return;
    }
    
    self.loginMethod = @"facebook";
    self.cachedUser = user;
    
    NSDictionary *deviceInfo = [self getDeviceInformation];
    
    NSDictionary *FBDictionary = @{@"id" : user.objectID , @"name" : user.name , @"first_name" : user.first_name , @"last_name" : user.last_name , @"link" : user.link};
    
    if ([user objectForKey:@"birthday"])
    {
        NSMutableDictionary *temp = [FBDictionary mutableCopy];
        [temp setValue:[user objectForKey:@"birthday"] forKey:@"birthday"];
        FBDictionary = [NSDictionary dictionaryWithDictionary:temp];
    }
    
    if ([user objectForKey:@"location"])
    {
        NSMutableDictionary *temp = [FBDictionary mutableCopy];
        [temp setValue:[user objectForKey:@"location"] forKey:@"location"];
        FBDictionary = [NSDictionary dictionaryWithDictionary:temp];
    }
    
    NSDictionary *FBSignupDictionary = @{@"facebook" : FBDictionary , @"device" : deviceInfo , @"is_public" : @YES};
    
    if ([user objectForKey:@"email"])
    {
        NSMutableDictionary *temp = [FBSignupDictionary mutableCopy];
        [temp setValue:[user objectForKey:@"email"] forKey:@"email"];
        FBSignupDictionary = [NSDictionary dictionaryWithDictionary:temp];
    }
    
    
    if (!self.userJoinFlow)
    {
        [HMServer.sh createUserWithDictionary:FBSignupDictionary];
        HMGLogInfo(@"requesting to create user with email: %@" , [user objectForKey:@"email"]);
        [[Mixpanel sharedInstance] track:@"FBcreateNewUser" properties:FBSignupDictionary];
    
    } else if (self.userJoinFlow && [User current])
    {
        HMGLogInfo(@"updating guest user to registered user");
        NSDictionary *FBUpdateDictionary = @{@"user_id" : [User current].userID , @"facebook" : FBDictionary , @"device" : deviceInfo , @"is_public" : @YES};
        
        if ([user objectForKey:@"email"])
        {
            NSMutableDictionary *temp = [FBUpdateDictionary mutableCopy];
            [temp setValue:[user objectForKey:@"email"] forKey:@"email"];
            FBUpdateDictionary = [NSDictionary dictionaryWithDictionary:temp];
        }
        
        [[Mixpanel sharedInstance] track:@"FBGuestUserUpdated" properties:FBUpdateDictionary];
        [HMServer.sh updateUserUponJoin:FBUpdateDictionary];
    }
    
    HMGLogInfo(@"fb login view fetched user info finish");
}

-(BOOL)isFacebookUser:(id<FBGraphUser>)firstUser equalToFacebookUser:(id<FBGraphUser>)secondUser
{
    return [firstUser.objectID isEqual:secondUser.objectID];
}


/*Implementing the loginViewShowingLoggedInUser: delegate method allows you to modify your app's UI to show a logged in experience. In the example below, we notify the user that they are logged in by changing the status:*/

// Logged-in user experience
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    HMGLogInfo(@"fb login");
    self.guiActivityView.hidden = NO;
    [self.guiActivityView startAnimating];
}

/*Implementing the loginViewShowingLoggedOutUser: delegate method allows you to modify your app's UI to show a logged out experience. In the example below, the user's profile picture is removed, the user's name set to blank, and the status is changed to reflect that the user is not logged in:*/

// Logged-out user experience
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    HMGLogInfo(@"fb logout");
    self.guiActivityView.hidden = YES;
    [self.guiActivityView stopAnimating];
}

// Handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error
{
    HMGLogInfo(@"got fb error");
    NSString *alertMessage, *alertTitle;
    
    // If the user should perform an action outside of you app to recover,
    // the SDK will provide a message for the user, you just need to surface it.
    // This conveniently handles cases like Facebook password change or unverified Facebook accounts.
    if ([FBErrorUtility shouldNotifyUserForError:error]) {
        alertTitle = @"Facebook error";
        alertMessage = [FBErrorUtility userMessageForError:error];
        
        // This code will handle session closures that happen outside of the app
        // You can take a look at our error handling guide to know more about it
        // https://developers.facebook.com/docs/ios/errors
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession) {
        alertTitle = @"Session Error";
        alertMessage = @"Your current session is no longer valid. Please log in again.";
        
        // If the user has cancelled a login, we will do nothing.
        // You can also choose to show the user a message if cancelling login will result in
        // the user not being able to complete a task they had initiated in your app
        // (like accessing FB-stored information or posting to Facebook)
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        NSLog(@"user cancelled login");
        
        // For simplicity, this sample handles other errors with a generic message
        // You can checkout our error handling guide for more detailed information
        // https://developers.facebook.com/docs/ios/errors
    } else {
        alertTitle  = @"Something went wrong";
        alertMessage = @"Please try again later.";
        NSLog(@"Unexpected error:%@", error);
    }
    
    if (alertMessage) {
        [[Mixpanel sharedInstance] track:@"FBError" properties:@{@"title" : alertTitle , @"message" : alertMessage}];
        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMessage
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    if ([segue.identifier isEqualToString:@"IntroSegue"])
    {
        self.introMovieController = segue.destinationViewController;
        self.introMovieController.delegate = self;
    }
}


- (void)didReceiveMemoryWarning
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)cancelButtonPushed:(id)sender
{
    [self.delegate dismissLoginScreen];
    self.guiCancelButton.hidden = YES;
    [self hideErrorLabel];
}

- (IBAction)termsOfServicePushed:(id)sender
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissLegalNavcontroller:)];
    [self.legalNavVC setViewControllers:@[self.tosVC] animated:YES];
    self.tosVC.navigationItem.hidesBackButton = YES;
    self.tosVC.navigationItem.leftBarButtonItem = doneButton;
    UIBarButtonItem *privacyButton = [[UIBarButtonItem alloc] initWithTitle:@"Privacy Policy" style:UIBarButtonItemStylePlain target:self action:@selector(showPrivacy:)];
    self.tosVC.navigationItem.rightBarButtonItem = privacyButton;
    self.tosVC.navigationItem.hidesBackButton = YES;
    [self presentViewController:self.legalNavVC animated:YES completion:nil];
}



- (IBAction)privacyPolicyPushed:(id)sender
{
   UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(dismissLegalNavcontroller:)];
    [self.legalNavVC setViewControllers:@[self.privacyVC] animated:YES];
    self.privacyVC.navigationItem.hidesBackButton = YES;
    self.privacyVC.navigationItem.leftBarButtonItem = doneButton;
    UIBarButtonItem *tosButton = [[UIBarButtonItem alloc] initWithTitle:@"Terms Of Service" style:UIBarButtonItemStylePlain target:self action:@selector(showTOS:)];
    self.privacyVC.navigationItem.rightBarButtonItem = tosButton;
    self.privacyVC.navigationItem.hidesBackButton = YES;
    [self presentViewController:self.legalNavVC animated:YES completion:nil];
}


-(void)dismissLegalNavcontroller:(UIBarButtonItem *)sender
{
    [self.legalNavVC dismissViewControllerAnimated:YES completion:nil];
}

-(void)showTOS:(UIBarButtonItem *)sender
{
    [self.legalNavVC pushViewController:self.tosVC animated:YES];
}

-(void)showPrivacy:(UIBarButtonItem *)sender
{
   
    [self.legalNavVC pushViewController:self.privacyVC animated:YES];
}

-(void)registerLoginAnalyticsForUser:(User *)user
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel identify:user.userID];
    
    if (user.email)
    {
        [mixpanel registerSuperProperties:@{@"email": user.email , @"homage_id":user.userID}];
        [mixpanel.people set:@{@"user" : user.email ,@"homage_id":user.userID}];
        
        //this excludes us from being tracked on mixpanel
        if ([self shouldExcludethisAdressFromMixpanelData:user.email])
        {
            [mixpanel registerSuperProperties:@{@"$ignore": @"true"}];
        }
    } else {
        [mixpanel registerSuperProperties:@{@"email" : @"guest" , @"homage_id" : user.userID}];
        [mixpanel.people set:@{@"user" : @"guest" ,@"homage_id":user.userID}];
    }
    
    //TODO: this should not be neeeded. verify for sure if it can be removed completly
    if ([user.userID isEqualToString:[User current].userID])
    {
        //TODO: fix self.loginMethod
        //[mixpanel track:@"UserLogin" properties:@{@"login_method" : self.loginMethod}];
        [mixpanel track:@"UserLogin"];
        [self.delegate dismissLoginScreen];
        return;
    }
    
    if (user.isFirstUse.boolValue)
    {
        [mixpanel track:@"UserSignup" properties:@{@"login_method" : self.loginMethod}];
    } else {
        [mixpanel track:@"UserLogin" properties:@{@"login_method" : self.loginMethod}];
    }
}

-(BOOL)shouldExcludethisAdressFromMixpanelData:(NSString *)email_address
{
    for (NSString *toBeExcludedMail in @[@"yoavcaspin@gmail.com",@"nir@homage.it",@"tomer@homage.it",@"yoav@homage.it",@"nirh2@yahoo.com",@"nir.channes@gmail.com",@"ranpeer@gmail.com",@"tomer.harry@gmail.com",@"hiorit@gmail.com",@"ari1822@gmail.com",@"ari@temple.edu"])
    {
        if ([email_address isEqualToString:toBeExcludedMail]) return YES;
    }
    
    return NO;
}

-(void)onPresentLoginCalled
{
    self.guiLoginErrorLabel.text = @"";
}

@end
