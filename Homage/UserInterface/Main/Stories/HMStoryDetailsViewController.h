//
//  HMStoryDetailsViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryPresenterProtocol.h"
#import "DB.h"
#import "HMAvenirBookFontLabel.h"
#import "HMSimpleVideoViewController.h"
#import "HMAvenirBookFontButton.h"
#import "HMBoldFontButton.h"
#import "HMRemakePresenterDelegate.h"
#import "HMStoreDelegate.h"

@interface HMStoryDetailsViewController : UIViewController<
    HMStoryPresenterProtocol,
    NSFetchedResultsControllerDelegate,
    HMRemakePresenterDelegate,
    HMStoreDelegate
>

@property (weak, nonatomic) IBOutlet UIButton *guiRemakeButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiRemakeActivity;
@property (weak, nonatomic) IBOutlet HMAvenirBookFontLabel *noRemakesLabel;
@property (weak, nonatomic) IBOutlet UIView *guiStoryMovieContainer;


@end
