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
#import "HMFontButton.h"
#import "HMFontLabel.h"
#import "HMColor.h"

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
};


@interface HMLoginMainViewController () <FBLoginViewDelegate,UITextFieldDelegate,HMIntroMovieDelegate>


@property (weak, nonatomic) IBOutlet UIView *guiIntroMovieContainerView;
@property (weak, nonatomic) IBOutlet HMFontButton *guiSignupButton;
@property (weak, nonatomic) IBOutlet HMFontButton *guiLoginButton;
@property (weak, nonatomic) IBOutlet HMFontButton *guiGuestButton;
@property (weak, nonatomic) IBOutlet HMFontButton *guiForgotPasswordButton;
@property (weak, nonatomic) IBOutlet UITextField *guiMailTextField;
@property (weak, nonatomic) IBOutlet UITextField *guiPasswordTextField;
@property (weak, nonatomic) IBOutlet UILabel *guiLoginErrorLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *guiSignUpView;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;

@property (strong, nonatomic) IBOutletCollection(HMFontButton) NSArray *buttonCollection;
@property (strong, nonatomic) IBOutletCollection(HMFontLabel) NSArray *labelCollection;


@property (strong, nonatomic) IBOutlet FBLoginView *guiFBLoginView;
@property (strong,nonatomic) HMIntroMovieViewController *introMovieController;
@property (nonatomic) BOOL userJoinFlow;

@property NSString *loginMethod;

@end

@implementation HMLoginMainViewController

- (void)viewDidLoad
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    
    [super viewDidLoad];
    
    self.userJoinFlow = NO;
    
    //FBloginView
    FBLoginView *loginView = [[FBLoginView alloc] initWithReadPermissions:@[@"basic_info", @"email" , @"user_birthday"]];
    loginView.delegate = self;
    self.guiFBLoginView = loginView;
    
    /*// Align the button in the center horizontally
    loginView.frame = CGRectOffset(loginView.frame,
                                   (self.view.center.x - (loginView.frame.size.width / 2)),
                                   5);
    
    // Align the button in the center vertically
    loginView.center = self.guiSignUpView.center;
    
    // Add the button to the view
    [self.guiSignUpView addSubview:loginView];*/
    
    [self initGUI];
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewDidAppear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    [self initObservers];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)viewWillDisappear:(BOOL)animated
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
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
    self.guiGuestButton.hidden = NO;
    
    self.guiBGImageView.image = [self.guiBGImageView.image applyBlurWithRadius:7.0 tintColor:[[UIColor blackColor] colorWithAlphaComponent:0.6] saturationDeltaFactor:0.3 maskImage:nil];
    
    for (HMFontButton *button in self.buttonCollection)
    {
        [button setTitleColor:[HMColor.sh textImpact] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont fontWithName:@"DINOT-regular" size:button.titleLabel.font.pointSize];
    }
    
    for (HMFontLabel *label in self.labelCollection)
    {
        [label setTextColor:[HMColor.sh textImpact]];
    }
    
    //text field stuff
    self.guiMailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.guiMailTextField.returnKeyType = UIReturnKeyDone;
    self.guiPasswordTextField.returnKeyType = UIReturnKeyDone;
    self.guiMailTextField.delegate = self;
    self.guiPasswordTextField.delegate = self;
    
    //sign up scrool view stuff
    self.guiSignUpView.contentSize = self.guiSignUpView.frame.size;
    self.guiSignUpView.scrollEnabled = NO;
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
                                                       name:HM_NOTIFICATION_SERVER_USER_UPDATE
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
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(BOOL)checkCredentials
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    NSString *emailAddress = self.guiMailTextField.text;
    
    // TODO: REMOVE!!!!! Ran's hack - always using the Test environment
    if ([emailAddress isEqualToString:@"ranpeer@gmail.com"])
    {
        [[HMServer sh] ranHack];
    }
    
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
            [self showErrorLabelWithString:LS(@"UNSUFFICIENT PASSWORD")];
             break;
        case HMMailAddressAlreadyTaken:
            [self showErrorLabelWithString:LS(@"EMAIL_TAKEN")];
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
    [UIView animateWithDuration:0.3 animations:^{
        self.guiLoginErrorLabel.alpha = 0;
    } completion:^(BOOL finished) {
        self.guiLoginErrorLabel.hidden = YES;
    }];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


//FBLoginView delegate
-(void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                           user:(id<FBGraphUser>)user
{
    self.loginMethod = @"facebook";
    
    NSDictionary *deviceInfo = [self getDeviceInformation];
    
    
    NSDictionary *FBDictionary = @{@"id" : user.id , @"name" : user.name , @"first_name" : user.first_name , @"last_name" : user.last_name , @"link" : user.link , @"username" : user.username , @"location" : user.location};
    
    if ([user objectForKey:@"birthday"])
    {
        NSMutableDictionary *temp = [FBDictionary mutableCopy];
        [temp setValue:[user objectForKey:@"birthday"] forKey:@"birthday"];
        FBDictionary = [NSDictionary dictionaryWithDictionary:temp];
    }
    
    NSDictionary *FBSignupDictionary = @{@"facebook" : FBDictionary , @"device" : deviceInfo , @"is_public" : @YES , @"email" : [user objectForKey:@"email"]};
    
    
    if (!self.userJoinFlow)
    {
       [HMServer.sh createUserWithDictionary:FBSignupDictionary];
    } else if (self.userJoinFlow && [User current])
    {
        NSDictionary *FBUpdateDictionary = @{@"user_id" : [User current].userID , @"facebook" : FBDictionary , @"device" : deviceInfo , @"is_public" : @YES , @"email" : [user objectForKey:@"email"]};
        [HMServer.sh updateUserWithDictionary:FBUpdateDictionary];
    }
    
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}


-(IBAction)onPressedSignUpLogin:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.loginMethod = @"mail";
    
    if (![self checkCredentials]) return;
    
    [self.view endEditing:YES];
    NSDictionary *deviceInfo = [self getDeviceInformation];
    NSDictionary *mailSignUpDictionary = @{@"email" : self.guiMailTextField.text , @"password" : self.guiPasswordTextField , @"is_public" : @YES , @"device" : deviceInfo };
    
    if (!self.userJoinFlow)
    {
       [HMServer.sh createUserWithDictionary:mailSignUpDictionary];
    } else if(self.userJoinFlow && [User current])
    {
        NSDictionary *mailSignUpDictionary = @{@"user_id" : [User current].userID , @"email" : self.guiMailTextField.text , @"password" : self.guiPasswordTextField , @"is_public" : [User current].isPublic , @"device" : deviceInfo};
        [HMServer.sh updateUserWithDictionary:mailSignUpDictionary];
    }
    
    self.guiMailTextField.text = @"";
    self.guiPasswordTextField.text = @"";

    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

- (IBAction)onPressedGuest:(UIButton *)sender
{
    HMGLogDebug(@"%s started" , __PRETTY_FUNCTION__);
    self.loginMethod = @"guest";
    
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
            case 1004:
                [self presentErrorLabelWithReason:HMMailAddressAlreadyTaken];
                return;
                break;
            default:
                break;
        }
        
        
        
        if (errorCode == 1001)
        {
            [self presentErrorLabelWithReason:HMIncorrectPassword];
            return;
        }
    }

    if ([User current]) return;

    NSDictionary *userInfo = notification.userInfo;
    NSString *userID = userInfo[@"userID"];
    User *user = [User userWithID:userID inContext:DB.sh.context];
    
    if (user)
    {
        [user loginInContext:DB.sh.context];
        [DB.sh save];
        [self.delegate onUserLoginStateChange:user];
    }
    
    NSString *userEmail = user.email;
    
    //mixPanel analitics
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    if (userID)[mixpanel identify:userID];
    if (userEmail)
    {
        [[NSUserDefaults standardUserDefaults] setValue:userEmail forKey:@"useremail"];
        [mixpanel registerSuperProperties:@{@"email": userEmail}];
        [mixpanel.people set:@{@"user" : userEmail}];
    }
    [mixpanel track:@"UserSignup" properties:@{@"login_method" : self.loginMethod}];
    [self displayIntroMovieView];
    HMGLogDebug(@"%s finished" , __PRETTY_FUNCTION__);
}

-(void)onUserUpdated:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *userID = userInfo[@"userID"];
    [User userWithID:userID inContext:DB.sh.context];
    
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
         [self.introMovieController initStoryMoviePlayer];
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
    
    /*HMAppDelegate *myDelegate = (HMAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSData *pushToken = myDelegate.pushToken;
    
    if (pushToken) [deviceDictionary setValue:pushToken forKey:@"push_token"];*/
    
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
    }
    
    self.guiGuestButton.hidden = NO;
}

-(void)onUserJoin
{
    self.guiGuestButton.hidden = YES;
    self.userJoinFlow = YES;
}

/*Implementing the loginViewShowingLoggedInUser: delegate method allows you to modify your app's UI to show a logged in experience. In the example below, we notify the user that they are logged in by changing the status:*/

// Logged-in user experience
- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView {
   NSLog(@"You're logged in");
}

/*Implementing the loginViewShowingLoggedOutUser: delegate method allows you to modify your app's UI to show a logged out experience. In the example below, the user's profile picture is removed, the user's name set to blank, and the status is changed to reflect that the user is not logged in:*/

// Logged-out user experience
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView {
    NSLog(@"your are logged out");
}

// Handle possible errors that can occur during login
- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
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



@end
