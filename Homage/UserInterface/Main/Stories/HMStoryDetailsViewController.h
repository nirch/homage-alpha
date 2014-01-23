//
//  HMStoryDetailsViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryPresenterProtocol.h"
#import "DB.h"
#import "HMFontLabel.h"
#import "HMSimpleVideoViewController.h"

@interface HMStoryDetailsViewController : UIViewController<
    HMStoryPresenterProtocol,NSFetchedResultsControllerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *guiBGImageView;
@property (weak, nonatomic) IBOutlet UIButton *guiRemakeButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiRemakeActivity;
@property (weak, nonatomic) IBOutlet HMFontLabel *noRemakesLabel;

@property (weak, nonatomic) IBOutlet UITextView *guiDescriptionField;
@property (weak, nonatomic) IBOutlet UIView *guisStoryMovieContainer;


@end
