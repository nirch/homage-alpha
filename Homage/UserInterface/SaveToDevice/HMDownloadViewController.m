//
//  HMDownloadViewController.m
//  Homage
//
//  Created by Aviv Wolf on 1/17/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMDownloadViewController.h"
#import "HMBoldFontLabel.h"
#import "HMStyle.h"
#import "AMBlurView.h"
#import "HMCacheManager.h"
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFNetworking/UIProgressView+AFNetworking.h>

@interface HMDownloadViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiDownloadContainer;
@property (weak, nonatomic) IBOutlet HMBoldFontLabel *guiDownloadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiDownloadingActivity;
@property (weak, nonatomic) IBOutlet UIProgressView *guiProgressView;

@property (nonatomic) NSDate *startTime;

@end


@implementation HMDownloadViewController

+(HMDownloadViewController *)downloadVCInParentVC:(UIViewController *)parentVC
{
    HMDownloadViewController *vc = [[HMDownloadViewController alloc] initWithDefaultNibInParentVC:parentVC];
    return vc;
}

-(id)initWithDefaultNibInParentVC:(UIViewController *)parentVC
{
    self = [self initWithNibName:@"HMDownloadViewController" bundle:nil];
    if (self) {
        [parentVC addChildViewController:self];
        [parentVC.view addSubview:self.view];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGUI];
}

-(void)initGUI
{
    [[AMBlurView new] insertIntoView:self.view];
    
    self.view.alpha = 0;
    [self.guiDownloadingActivity stopAnimating];
    self.guiDownloadingLabel.text = LS(@"DOWNLOADING");
    self.guiProgressView.progress = 0;

    CALayer *layer = self.guiDownloadContainer.layer;
    layer.cornerRadius = 5;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(10,10);
    layer.shadowRadius = 10;
    layer.shadowOpacity = 1;
    
    // Start time
    self.startTime = [NSDate date];
   
    // ************
    // *  STYLES  *
    // ************
    self.guiDownloadContainer.backgroundColor = [HMStyle.sh colorNamed:C_DOWNLOAD_CONTAINER];
    self.guiDownloadingLabel.textColor = [HMStyle.sh colorNamed:C_DOWNLOAD_TITLE];
    self.guiDownloadingActivity.color = [HMStyle.sh colorNamed:C_DOWNLOAD_ACTIVITY];
    self.guiProgressView.progressTintColor = [HMStyle.sh colorNamed:C_DOWNLOAD_TITLE];
}


#pragma mark - Downloading.
-(void)startDownloadResourceFromURL:(NSURL *)url toLocalFolder:(NSURL *)localFolder
{
    self.guiDownloadingLabel.text = LS(@"DOWNLOADING");
    [self.guiDownloadingActivity startAnimating];
    [UIView animateWithDuration:0.2 animations:^{
        self.view.alpha = 1;
    }];
    
    NSURL *remakesCachePath = HMCacheManager.sh.remakesCachePath;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        
        // The local url to download to.
        NSURL *path = [remakesCachePath URLByAppendingPathComponent:[response suggestedFilename]];
        return path;
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        
        // When finished.
        if (error) {
            HMGLogError(@"Error while downloading remake video resource. %@", [error localizedDescription]);
            [self.delegate downloadFinishedWithError:error info:self.info];
            return;
        }
        
        // Notify about finished upload.
        dispatch_async(dispatch_get_main_queue(), ^{
            HMGLogDebug(@"File downloaded and cached: %@", filePath);
            NSDate *now = [NSDate date];
            NSMutableDictionary *moreInfo = [NSMutableDictionary dictionaryWithDictionary:self.info];
            moreInfo[@"file_path"] = [filePath path];
            moreInfo[@"download_time"] = @([now timeIntervalSinceDate:self.startTime]);
            [self.delegate downloadFinishedSuccessfullyWithInfo:moreInfo];
        });
        
    }];
    self.guiProgressView.hidden = NO;
    [self.guiProgressView setProgressWithDownloadProgressOfTask:downloadTask animated:YES];
    [downloadTask resume];
}

-(void)startSavingToCameraRoll
{
    self.guiDownloadingLabel.text = LS(@"DOWNLOAD_SAVING_REMAKE");
    self.guiProgressView.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.view.alpha = 1;
    }];
    [self.guiDownloadingActivity startAnimating];
}

-(void)cancel
{
    self.guiDownloadingLabel.text = LS(@"DOWNLOAD_CANCELED");
    self.guiProgressView.hidden = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.view.alpha = 1;
    }];
    [self.guiDownloadingActivity startAnimating];
}

-(void)dismiss
{
    NSDate *now = [NSDate date];
    CGFloat delay = 0;
    
    // Easy, not too fast!
    // If download too quick, wait a bit before dimissing UI
    // We don't want an ungraceful flashing of the UI.
    // Sometime, slower is better. What's the rush?
    NSTimeInterval timePassed = [now timeIntervalSinceDate:self.startTime];
    if ( timePassed < 500) {
        delay = (500 - timePassed) / 1000.0f;
    }
    
    [UIView animateWithDuration:0.3
                          delay:delay
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.view.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self.view removeFromSuperview];
                         [self removeFromParentViewController];
                     }];
}

@end
