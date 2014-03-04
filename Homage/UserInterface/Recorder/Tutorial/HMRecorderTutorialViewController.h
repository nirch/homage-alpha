//
//  HMRecorderTutorialViewController.h
//  Homage
//
//  Created by Aviv Wolf on 3/2/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderChildInterface.h"

@interface HMRecorderTutorialViewController : UIViewController<
    HMRecorderChildInterface
>

-(void)start;

@end
