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
#import "HMColor.h"

@interface HMRenderingViewController ()

@property (strong, nonatomic) NSTimer* timer;

@end

#define TIMER_INTERVAL 10
#define TIMER_TOLERANCE 5
#define PROGRESS_BAR_DURATION 180
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
    HMGLogDebug(@"%s", __PRETTY_FUNCTION__);
    
    
    [self initGUI];
    [self initObservers];

    self.guiProgressBarView.delegate = self;
    self.guiProgressBarView.duration = PROGRESS_BAR_DURATION;
    
    self.timer = nil;
}

-(void)initGUI
{
    
    UIColor *homageColor = [HMColor.sh main2];
    [self.view sendSubviewToBack:self.guiDoneRenderingView];
    [self.view addSubview:self.guiInProgressView];
    self.guiInProgressLabel.textColor = homageColor;
    self.guiDoneLabel.textColor = homageColor;
    self.guiProgressBar.backgroundColor = homageColor;
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

#pragma mark - Observers handlers
-(void)onRemakeStatusNotification:(NSNotification *)notification
{
    // Checking the status of the remake
    
    // TODO: Get the String of the remakeID key as a constant from the notification center
    NSString *remakeID = [notification.userInfo valueForKey:@"remakeID"];
    Remake *remake = [Remake findWithID:remakeID inContext:[[DB sh] context]];
    
    BOOL renderingEnded = NO;
    
    switch (remake.status.integerValue) {
        case HMGRemakeStatusNew:
            HMGLogWarning(@"Remake <%@> has status <New> while sent for rendering", remakeID);
            break;
        case HMGRemakeStatusInProgress:
            HMGLogDebug(@"Remake <%@> has status <InProgress> while sent for rendering", remakeID);
            break;
        case HMGRemakeStatusRendering:
            HMGLogDebug(@"Remake <%@> has status <Rendering> while sent for rendering", remakeID);
            break;
        case HMGRemakeStatusDone:
            HMGLogInfo(@"Remake <%@> video is ready", remakeID);
            self.guiDoneLabel.text = NSLocalizedString(@"REMAKE_READY_CLICK", nil);
            renderingEnded = YES;
            break;
        case HMGRemakeStatusTimeout:
            HMGLogError(@"Remake <%@> has status <Timeout> while sent for rendering", remakeID);
            self.guiDoneLabel.text = NSLocalizedString(@"REMAKE_FAILED_CLICK", nil);
            renderingEnded = YES;
            break;
        case HMGRemakeStatusDeleted:
            HMGLogError(@"Remake <%@> has status <Deleted> while sent for rendering", remakeID);
            self.guiDoneLabel.text = NSLocalizedString(@"REMAKE_FAILED_CLICK", nil);
            renderingEnded = YES;
            break;
        default:
            HMGLogWarning(@"Remake <%@> has unknown status <%d>", remakeID, remake.status.integerValue);
            break;
    }
    
    // Stoping the timer and the progress bar if the rendering is done
    if (renderingEnded)
    {
        [self.timer invalidate];
        self.timer = nil;
        [self.guiProgressBarView stop];
        
        // Since the progress bar has an animtation for finishing the progress bar, we are delaying the the switch to the label view in order for the animation to finish
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [UIView transitionFromView:self.guiInProgressView
                                toView:self.guiDoneRenderingView
                              duration:0.5
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            completion:^(BOOL finished){
                                [self.view sendSubviewToBack:self.guiInProgressView];
                            }];
        });

    }
}


#pragma mark - AWTimeProgressDelegate methods

-(void)timeProgressDidStartAtTime:(NSDate *)time forDuration:(NSTimeInterval)duration
{
    
}

-(void)timeProgressWasCancelledAfterDuration:(NSTimeInterval)duration
{
    
}

-(void)timeProgressDidFinishAfterDuration:(NSTimeInterval)duration
{
    HMGLogWarning(@"Progress Bar finished, but the remake isn't ready yet");
    
    [self.timer invalidate];
    self.timer = nil;

    self.guiDoneLabel.text = NSLocalizedString(@"REMAKE_FAILED_CLICK", nil);
    
    [UIView transitionFromView:self.guiInProgressView
                        toView:self.guiDoneRenderingView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished){
                        [self.view sendSubviewToBack:self.guiInProgressView];
                    }];
    

}

- (IBAction)movieDoneTapped:(UITapGestureRecognizer *)sender {
    HMGLogDebug(@"%s", __PRETTY_FUNCTION__);
    [self.delegate renderDoneClicked];
}

- (void)renderStartedWithRemakeID:(NSString *)remakeID {
    
    HMGLogDebug(@"%s", __PRETTY_FUNCTION__);

    if (self.guiProgressBarView.isRunning)
    {
        // Stop the run of the progress bar
        //[self.guiProgressBarView stop];
        
    }
    
    // if we have a running timer, then we need to invalidate it
    if ([self.timer isValid])
    {
        [self.timer invalidate];
    }
    
    // Scheduling a timer
    NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:remakeID, REMAKE_ID_KEY, nil];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(checkRemakeStatus:) userInfo:userInfo repeats:YES];
    self.timer.tolerance = TIMER_TOLERANCE;
    Remake *remake = [Remake findWithID:remakeID inContext:[[DB sh] context]];
    self.guiInProgressLabel.text = [NSString stringWithFormat:@"%@:%@" , NSLocalizedString(@"RENDERING_MOVIE_MESSAGE", nil) ,remake.story.name];
    
    [self.view sendSubviewToBack:self.guiDoneRenderingView];
    [self.guiProgressBarView start];
}

- (void)checkRemakeStatus:(NSTimer *)timer
{
    // When the timer is fired, calling the server to get the status of the remake
    
    NSString *remakeID = [timer.userInfo valueForKey:REMAKE_ID_KEY];
    [[HMServer sh] refetchRemakeWithID:remakeID];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    HMGLogWarning(@"%s received memory warning", __PRETTY_FUNCTION__);
    
    // Dispose of any resources that can be recreated.
}

@end