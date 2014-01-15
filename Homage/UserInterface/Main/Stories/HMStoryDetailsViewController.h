//
//  HMStoryDetailsViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryPresenterProtocol.h"

@interface HMStoryDetailsViewController : UIViewController<
    HMStoryPresenterProtocol
>

@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;
@property (weak, nonatomic) IBOutlet UIImageView *guiThumbnailImage;
@property (weak, nonatomic) IBOutlet UIButton *guiRemakeButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiRemakeActivity;

@end
