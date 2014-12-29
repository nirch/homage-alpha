//
//  HMRenderingViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/26/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWTimeProgressView.h"
#import "AWTimeProgressDelegate.h"
#import "HMRenderingViewControllerDelegate.h"
#import "HMRegularFontLabel.h"

@interface HMRenderingViewController : UIViewController 
@property (strong, nonatomic) IBOutlet UIView *guiTopView;

@property (weak, nonatomic) IBOutlet UIView *guiInProgressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivityWheel;
@property (weak, nonatomic) IBOutlet UIButton *guiCloseButton;

@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiInProgressLabel;
@property (weak, nonatomic) IBOutlet UIView *guiDoneRenderingView;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *guiDoneLabel;

-(void)renderStartedWithRemakeID:(NSString *)remakeID;
-(void)presentMovieStatus:(BOOL)success forStory:(NSString *)storyName;

///
/**
 *  A delegate conforming to the HMTimeProgressDelegate protocol.
 
 *   Will call methods on the delegate on start, finish, stop and when events (if available) fire.
 */
@property id<HMRenderingViewControllerDelegate> delegate;


@end
