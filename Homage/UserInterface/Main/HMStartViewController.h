//
//  HMStartViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderDelegate.h"
#import "HMMainGUIProtocol.h"

@interface HMStartViewController : UIViewController<
    HMMainGUIProtocol
>

@property (weak, nonatomic) IBOutlet UIView *guiSplashView;
@property (weak, nonatomic) IBOutlet UIImageView *guiBGImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;

@end
