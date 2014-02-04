//
//  HMLoginViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMLoginViewController.h"
#import "HMFontLabel.h"
#import "HMFontButton.h"
#import "DB.h"
#import "HMNotificationCenter.h"
#import "HMServer+Users.h"
#import "HMServer+Remakes.h"
#import "HMRecorderViewController.h"
#import "UIView+MotionEffect.h"
#import "UIImage+ImageEffects.h"
#import "Mixpanel.h"


@interface HMLoginViewController ()



@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;


@property (weak, nonatomic) IBOutlet UIView *guiSignUpView;
@property (weak, nonatomic) IBOutlet UIView *guiIntroView;

@property (weak, nonatomic) IBOutlet UITextField *guiSignUpMailTextField;
@property (weak, nonatomic) IBOutlet UIButton *guiSignUpButton;


@property (weak, nonatomic) IBOutlet UIButton *guiIntroSkipButton;
@property (weak, nonatomic) IBOutlet UIButton *guiShootFirstStoryButton;

@property (weak, nonatomic) IBOutlet HMFontLabel *guiIntroLabel1;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiIntroLabel2;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiIntrolabel3;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiIntroLabel4;

@property (weak, nonatomic) IBOutlet HMFontLabel *guiSignupLabel1;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiSignupLabel2;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiSignupLabel3;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivityIndicator;


@end

@implementation HMLoginViewController

#define DIVE_SCHOOL "52de83db8bc427751c000305";

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initObservers];
    [self initGUI];
    NSLog(@"self.view.frame = origin(%f,%f) , size(%f,%f)" , self.view.frame.origin.x , self.view.frame.origin.y , self.view.frame.size.height , self.view.frame.size.width);
    NSLog(@"self.guiBGImageView.frame = origin(%f,%f) , size(%f,%f)" , self.guiBGImageView.frame.origin.x , self.guiBGImageView.frame.origin.y , self.guiBGImageView.frame.size.height , self.guiBGImageView.frame.size.width);
}

-(void)initGUI
{
    self.guiIntroView.alpha = 0;
    self.guiBGImageView.image = [self.guiBGImageView.image applyBlurWithRadius:2.0 tintColor:nil saturationDeltaFactor:0.3 maskImage:nil];
    self.guiActivityIndicator.hidden = YES;
    self.guiSignUpMailTextField.keyboardType = UIKeyboardTypeEmailAddress;
}
-(void)initObservers
{
    // Observe creation of user
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onUserCreated:)
                                                       name:HM_NOTIFICATION_SERVER_USER_CREATION
                                                     object:nil];
    
    /*[[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeCreated:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE_CREATION
                                                     object:nil];*/
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self removeObservers];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_SERVER_USER_CREATION object:nil];
    //[nc removeObserver:self name:HM_NOTIFICATION_SERVER_REMAKE_CREATION object:nil];
}


- (IBAction)onPressedSignUp:(UIButton *)sender
{
    NSString *emailAsddress = self.guiSignUpMailTextField.text;
    BOOL isCorrectFormat = [self validateEmail:emailAsddress];
    
    if (!isCorrectFormat)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"incoerrct Email format"
                                                        message:@"please enter a valid email address"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil
                              ];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
    } else {
        [HMServer.sh createUserWithID:emailAsddress];
        self.guiActivityIndicator.hidden = NO;
        [self.guiActivityIndicator startAnimating];
    }
}

-(void)onUserCreated:(NSNotification *)notifictation
{
    NSDictionary *userInfo = notifictation.userInfo;
    NSString *userID = userInfo[@"userID"];
    User *user = [User userWithID:userID inContext:DB.sh.context];
    [user loginInContext:DB.sh.context];
    [DB.sh save];
    [[NSUserDefaults standardUserDefaults] setValue:userID forKey:@"useremail"];
    
    //mixPanel analitics
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"userlogin" properties:@{
                                              @"useremail" : [User current].userID}];
    
    [self.guiActivityIndicator stopAnimating];
    [self switchToIntroView];
}

-(void)switchToIntroView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.guiSignUpView.alpha = 0;
        self.guiIntroView.alpha = 1;
    } completion:nil];
}


- (BOOL) validateEmail:(NSString *)emailAddress {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailAddress];
}


- (IBAction)onPressedSkipButton:(UIButton *)sender {
    //[self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate onLoginPressedSkip];
}



- (IBAction)onPressedShootFirstMovie:(UIButton *)sender
{
    
    NSString *storyID = @DIVE_SCHOOL;
    //NSString *userID = [User current].userID;
    [self.delegate onLoginPressedShootWithStoryID:storyID];
    //[HMServer.sh createRemakeForStoryWithID:storyID forUserID:userID];
}

/*-(void)onRemakeCreated:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSString *remakeID = info[@"remakeID"];
    
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    [self.delegate onLoginPressedShootWithRemake:remake];
}*/

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.guiSignUpMailTextField resignFirstResponder];
}


@end
