//
//  HMRecorderOptionsBarViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderChildInterface.h"

@interface HMRecorderOptionsBarViewController : UIViewController<
    HMRecorderChildInterface
>

@property (weak, nonatomic) IBOutlet UIView *guiOptionsBarContainer;

@end
