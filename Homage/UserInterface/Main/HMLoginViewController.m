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
#import "HMColor.h"
@import MediaPlayer;
@import AVFoundation;



@interface HMLoginViewController () <UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;

@property (weak, nonatomic) IBOutlet UIScrollView *guiSignUpView;

@property (weak, nonatomic) IBOutlet UIView *guiIntroView;

@property (weak, nonatomic) IBOutlet UITextField *guiSignUpMailTextField;
@property (weak, nonatomic) IBOutlet UIButton *guiSignUpButton;

@property (weak, nonatomic) IBOutlet UIButton *guiIntroSkipButton;
@property (weak, nonatomic) IBOutlet UIButton *guiShootFirstStoryButton;

@property (weak, nonatomic) IBOutlet HMFontLabel *guiSignupLabel1;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiSignupLabel2;
@property (weak, nonatomic) IBOutlet HMFontLabel *guiSignupLabel3;

@property (weak, nonatomic) IBOutlet UIView *guiIntroMovieContainer;
@property (strong,nonatomic) MPMoviePlayerController *moviePlayer;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivityIndicator;


@end

@implementation HMLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initObservers];
    [self initGUI];
    //NSLog(@"self.view.frame = origin(%f,%f) , size(%f,%f)" , self.view.frame.origin.x , self.view.frame.origin.y , self.view.frame.size.height , self.view.frame.size.width);
    //NSLog(@"self.guiBGImageView.frame = origin(%f,%f) , size(%f,%f)" , self.guiBGImageView.frame.origin.x , self.guiBGImageView.frame.origin.y , self.guiBGImageView.frame.size.height , self.guiBGImageView.frame.size.width);
}

-(void)viewDidAppear:(BOOL)animated
{
    
}

-(void)viewDidDisappear:(BOOL)animated
{
    
}

-(void)initGUI
{
    self.guiIntroView.alpha = 0;
    self.guiBGImageView.image = [self.guiBGImageView.image applyBlurWithRadius:2.0 tintColor:nil saturationDeltaFactor:0.3 maskImage:nil];
    self.guiActivityIndicator.hidden = YES;
    self.guiSignUpMailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.guiSignUpMailTextField.returnKeyType = UIReturnKeyDone;
    self.guiSignUpMailTextField.delegate = self;
    self.guiSignUpView.contentSize = self.guiSignUpView.frame.size;
    self.guiSignUpView.scrollEnabled = NO;
    UIColor *hcolor = [HMColor.sh main2];
    [self.guiSignupLabel1 setTextColor:hcolor];
    [self.guiSignupLabel2 setTextColor:hcolor];
    [self.guiSignupLabel3 setTextColor:hcolor];
}

-(void)initStoryMoviePlayer
{
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"introVideo" ofType:@"mp4"]]];
    [self.moviePlayer.view setFrame:self.guiIntroMovieContainer.frame];
    [self.moviePlayer play];
    [self.view addSubview:self.moviePlayer.view];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
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
    [nc removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [nc removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
        [self.view endEditing:YES];
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
    } completion:^(BOOL finished){
        [self initStoryMoviePlayer];
    }];
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
    [self.delegate onLoginPressedShootFirstStory];
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary* info = notification.userInfo;
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height + 100, 0.0);
    self.guiSignUpView.contentInset = contentInsets;
    self.guiSignUpView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.guiSignUpMailTextField.frame.origin) ) {
        [self.guiSignUpView scrollRectToVisible:self.guiSignUpMailTextField.frame animated:YES];
    }
}

-(void)keyboardWillBeHidden:(NSNotification *)notification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.guiSignUpView.contentInset = contentInsets;
    self.guiSignUpView.scrollIndicatorInsets = contentInsets;
}




@end
