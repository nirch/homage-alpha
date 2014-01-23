//
//  HMSimpleVideoViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMSimpleVideoView.h"
#import "HMSimpleVideoPlayerProtocol.h"

@interface HMSimpleVideoViewController : UIViewController

///
/**
*  The url of the video that will be loaded when pressing play.
*/
@property (nonatomic) NSString *videoURL;

///
/**
*  A text caption appearing on the video image/thumbnail (before playing the video).
*/
@property (nonatomic) NSString *videoLabelText;

///
/**
*  The thumbnail that is placeholder for the video (until playing the video).
*/
@property (nonatomic) UIImage *videoImage;

///
/**
*  The HMSimpleVideoView containing the custom UI for the video player.
*/
@property (nonatomic, weak, readonly) HMSimpleVideoView *videoView;

///
/**
 *  delegate of HMSimpleVideoViewController
 */
@property id<HMSimpleVideoPlayerProtocol> delegate;

///
/**
*  Initializes a HMSimpleVideoViewController with a given nib name (a nib of a HMSimpleVideoView).
*
*  @param nibName       The name of the nib the HMSimpleVideoView layout is loaded from.
*  @param parentVC      The parent view controller for this view controller.
*  @param containerView The superview that will contain the HMSimpleVideoView (the video is embedded in that view).
*
*  @return a new instance HMSimpleVideoViewController.
*/
-(id)initWithNibNamed:(NSString *)nibName inParentVC:(UIViewController *)parentVC containerView:(UIView *)containerView;

///
/**
 *  Initializes a HMSimpleVideoViewController with the default nib (HMSimpleVideoViewController.xib).
 *
 *  @param parentVC      The parent view controller for this view controller.
 *  @param containerView The superview that will contain the HMSimpleVideoView (the video is embedded in that view).
 *
 *  @return a new instance HMSimpleVideoViewController.
 */
-(id)initWithDefaultNibInParentVC:(UIViewController *)parentVC containerView:(UIView *)containerView;

///
/**
*  Stop playing video. Exit full screen. Reset UI to first state.
*/
-(void)done;

///
/**
* start playing video, including prepareToPlay
 */
-(void)play;


@end
