//
//  HMRenderingViewController.m
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRenderingViewController.h"
#import "HMNotificationCenter.h"
#import "HMServer+Remakes.h"
#import "DB.h"
#import "Remake+Logic.h"
#import "HMStyle.h"
#import "Mixpanel.h"

@interface HMRenderingViewController ()

@property (strong, nonatomic) NSTimer* timer;
@property (nonatomic) NSTimeInterval timePassedSinceTimerBegan;
@property (nonatomic) BOOL renderingEnded;
@property (weak, nonatomic) IBOutlet UIProgressView *guiProgressBar;
@property (nonatomic) NSDate *renderingStartedTime;

@end

#define TIMER_INTERVAL 10
#define TIMER_TOLERANCE 5
#define PROGRESS_BAR_DURATION 900
#define REMAKE_ID_KEY @"remakeID"

@implementation HMRenderingViewController

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
    [self initObservers];

    self.timer = nil;
}

-(void)initGUI
{
    self.guiDoneRenderingView.alpha = 0;
    self.guiDoneRenderingView.hidden = YES;
    self.guiInProgressView.alpha = 1;
    self.guiInProgressView.hidden = NO;
    
    // ************
    // *  STYLES  *
    // ************
    self.guiTopView.backgroundColor = [HMStyle.sh colorNamed:C_RENDERING_BAR_BG];
    self.guiInProgressLabel.textColor = [HMStyle.sh colorNamed:C_RENDERING_BAR_TEXT];
    self.guiDoneLabel.textColor = [HMStyle.sh colorNamed:C_RENDERING_BAR_TEXT];
}

#pragma mark - Observers
-(void)initObservers
{
    // Observe remake status
    [[NSNotificationCenter defaultCenter] addUniqueObserver:self
                                                   selector:@selector(onRemakeStatusNotification:)
                                                       name:HM_NOTIFICATION_SERVER_REMAKE
                                                     object:nil];
}

-(void)updateProgressLabelForRemake:(Remake *)remake
{
    NSString *label = nil;
    NSInteger footagesCount = remake.footages.count;
    NSInteger alreadyUploadedFootages = [remake footagesUploadedCount];
    NSInteger readyFootagesCount = [remake footagesReadyCount];
    NSTimeInterval rendereingExpectedTime = [remake.story expectedRenderingTime];
    
    if (remake.status.integerValue == HMGRemakeStatusRendering || readyFootagesCount == footagesCount) {
        label = LS(@"RENDERING_MOVIE_MESSAGE");
        if (self.renderingStartedTime == nil) {
            self.renderingStartedTime = [NSDate date];
        }
        NSTimeInterval timePassedSinceStartedRendering = [[NSDate date] timeIntervalSinceDate:self.renderingStartedTime];
        CGFloat t = timePassedSinceStartedRendering / rendereingExpectedTime;
        t = MIN(1, t);
        CGFloat progress = 0.30f + 0.70f * t;
        [self.guiProgressBar setProgress:progress animated:YES];
        
    } else if (alreadyUploadedFootages < footagesCount) {
        // Uploading
        self.guiProgressBar.progress = 0.15f * (float)alreadyUploadedFootages / (float)footagesCount;
        label = LS(@"UPLOADING_MESSAGE");
    } else if (readyFootagesCount < footagesCount) {
        CGFloat progress = 0.15f + 0.15f * (float)alreadyUploadedFootages / (float)footagesCount;
        [self.guiProgressBar setProgress:progress animated:YES];
        label = LS(@"PROCESSING_MESSAGE");
    }
    if (label != nil) self.guiInProgressLabel.text = label;
}


#pragma mark - Observers handlers
-(void)onRemakeStatusNotification:(NSNotification *)notification
{
    // Checking the status of the remake
    
    // TODO: Get the String of the remakeID key as a constant from the notification center
    NSString *remakeID = [notification.userInfo valueForKey:@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:[[DB sh] context]];
    
    self.renderingEnded = NO;
    
    switch (remake.status.integerValue) {
        case HMGRemakeStatusNew:
            HMGLogWarning(@"Remake <%@> has status <New> while sent for rendering", remakeID);
            [self updateProgressLabelForRemake:remake];
            break;
        case HMGRemakeStatusInProgress:
            HMGLogDebug(@"Remake <%@> has status <InProgress> while sent for rendering", remakeID);
            [self updateProgressLabelForRemake:remake];
            break;
        case HMGRemakeStatusRendering:
            HMGLogDebug(@"Remake <%@> has status <Rendering> while sent for rendering", remakeID);
            [self updateProgressLabelForRemake:remake];
            break;
        case HMGRemakeStatusDone:
            HMGLogInfo(@"Remake <%@> video is ready", remakeID);
            self.guiDoneLabel.text = [NSString stringWithFormat:LS(@"REMAKE_READY_CLICK") , remake.story.name];
            self.renderingEnded = YES;
            break;
        case HMGRemakeStatusTimeout:
            HMGLogError(@"Remake <%@> has status <Timeout> while sent for rendering", remakeID);
            self.guiDoneLabel.text = [NSString stringWithFormat:LS(@"REMAKE_FAILED_CLICK"), remake.story.name];
            self.renderingEnded = YES;
            break;
        case HMGRemakeStatusDeleted:
            HMGLogError(@"Remake <%@> has status <Deleted> while sent for rendering", remakeID);
            self.guiDoneLabel.text = [NSString stringWithFormat:LS(@"REMAKE_FAILED_CLICK"), remake.story.name];
            self.renderingEnded = YES;
            break;
        case HMGRemakeStatusFailed:
            HMGLogError(@"Remake <%@> has status <Deleted> while sent for rendering", remakeID);
            self.guiDoneLabel.text = [NSString stringWithFormat:LS(@"REMAKE_FAILED_CLICK"), remake.story.name];
            self.renderingEnded = YES;
            break;
        default:
            HMGLogWarning(@"Remake <%@> has unknown status <%d>", remakeID, remake.status.integerValue);
            [self updateProgressLabelForRemake:remake];
            break;
    }
    
    // Stoping the timer and the progress bar if the rendering is done
    if (self.renderingEnded)
    {
        [self stopTimer];
        [self.guiActivityWheel stopAnimating];
        //[self.guiProgressBarView stopAnimated:YES];
        
        // Since the progress bar has an animtation for finishing the progress bar, we are delaying the the switch to the label view in order for the animation to finish
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self showDoneViewAnimated:YES];
            
        });

    }
    
}

-(void)showDoneViewAnimated:(BOOL)animated
{
    [self.guiProgressBar setProgress:0 animated:NO];
    if (!self.guiDoneRenderingView.hidden) return;
    self.guiDoneRenderingView.hidden = NO;
    if (animated)
    {
    [UIView animateWithDuration:0.5 animations:^{
        self.guiInProgressView.alpha = 0;
        self.guiDoneRenderingView.alpha = 1;
    } completion:^(BOOL finished)
     {
         self.guiInProgressView.hidden = YES;
         if ([self.guiActivityWheel isAnimating]) [self.guiActivityWheel stopAnimating];
     }];
    } else {
        self.guiInProgressView.alpha = 0;
        self.guiDoneRenderingView.alpha = 1;
        self.guiInProgressView.hidden = YES;
        if ([self.guiActivityWheel isAnimating]) [self.guiActivityWheel stopAnimating];
    }
}

-(void)showInProgressViewAnimated:(BOOL)animated
{
    if (!self.guiInProgressView.hidden) return;
    
    self.guiInProgressView.hidden = NO;
    [self.guiProgressBar setProgress:0 animated:NO];
    self.renderingStartedTime = nil;
    
    if (animated)
    {
    [UIView animateWithDuration:0.5 animations:^{
        self.guiInProgressView.alpha = 1;
        self.guiDoneRenderingView.alpha = 0;
    } completion:^(BOOL finished)
     {
         self.guiDoneRenderingView.hidden = YES;
     }];
    } else
    {
        self.guiInProgressView.alpha = 1;
        self.guiDoneRenderingView.alpha = 0;
        self.guiDoneRenderingView.hidden = YES;
    }
}

- (IBAction)movieDoneTapped:(UITapGestureRecognizer *)sender {
    NSString *success = self.renderingEnded ? @"YES" : @"NO";
    [[Mixpanel sharedInstance] track:@"hit_movie_done_rendering_button" properties:@{@"remake_successful" : success}];
    [self.delegate renderDoneClickedWithSuccess:self.renderingEnded];
}

- (void)renderStartedWithRemakeID:(NSString *)remakeID {
    
    // if we have a running timer, then we need to invalidate it
    if ([self.timer isValid])
    {
        [self.timer invalidate];
    }
    
    // Scheduling a timer
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:remakeID, REMAKE_ID_KEY, nil];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(checkRemakeStatus:) userInfo:userInfo repeats:YES];
    self.timer.tolerance = TIMER_TOLERANCE;
    self.timePassedSinceTimerBegan = 0;
    Remake *remake = [Remake findWithID:remakeID inContext:[[DB sh] context]];
    [self updateProgressLabelForRemake:remake];
    [self showInProgressViewAnimated:YES];
    [self.guiActivityWheel startAnimating];
}

- (void)checkRemakeStatus:(NSTimer *)timer
{
    // When the timer is fired, calling the server to get the status of the remake
    
    if (self.timePassedSinceTimerBegan > PROGRESS_BAR_DURATION)
    {
        HMGLogWarning(@"timer finished before movie is ready!!!! why oh why?!?!");
        [self renderingTimeout];
        return;
    }
    

    self.timePassedSinceTimerBegan = self.timePassedSinceTimerBegan + self.timer.timeInterval;
    HMGLogDebug(@"time passed since firing: %d" , self.timePassedSinceTimerBegan);
    NSString *remakeID = [timer.userInfo valueForKey:REMAKE_ID_KEY];
    [[HMServer sh] refetchRemakeWithID:remakeID];
}

-(void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

-(void)presentMovieStatus:(BOOL)success forStory:(NSString *)storyName
{
    
    if (success)
    {
        self.renderingEnded = YES;
        self.guiDoneLabel.text = [NSString stringWithFormat:LS(@"REMAKE_READY_CLICK") , storyName];
    } else
    {
        self.renderingEnded = NO;
        self.guiDoneLabel.text = [NSString stringWithFormat:LS(@"REMAKE_FAILED_CLICK") , storyName];
    }
    
    [self stopTimer];
    [self showDoneViewAnimated:NO];
    
}

-(void)renderingTimeout
{
    HMGLogWarning(@"Progress Bar finished, but the remake isn't ready yet");
    
    [self stopTimer];
    
    self.guiDoneLabel.text = LS(@"REMAKE_FAILED_CLICK");
    
    [self showDoneViewAnimated:YES];
}

- (IBAction)closeButtonPushed:(id)sender
{
    [self.delegate dismissRenderingView];
}

-(void)setRenderingSuccess:(BOOL)sucess
{
    if (sucess) self.renderingEnded = YES;
    else self.renderingEnded = NO;
}


@end
