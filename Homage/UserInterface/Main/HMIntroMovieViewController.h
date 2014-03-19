//
//  HMLoginViewController.h
//  Homage
//
//  Created by Yoav Caspin on 1/29/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HMIntroMovieDelagate.h"

@interface HMIntroMovieViewController : UIViewController

@property (nonatomic) id<HMIntroMovieDelegate> delegate;

-(void)initStoryMoviePlayer;

@end
