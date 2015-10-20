//
//  HMStoryDetailsViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoryPresenterProtocol.h"
#import "DB.h"
#import "HMSimpleVideoViewController.h"
#import "HMRegularFontButton.h"
#import "HMRegularFontLabel.h"
#import "HMBoldFontButton.h"
#import "HMRemakePresenterDelegate.h"
#import "HMStoreDelegate.h"
#import <MONActivityIndicatorView/MONActivityIndicatorView.h>

@interface HMStoryDetailsViewController : UIViewController<
    HMStoryPresenterProtocol,
    NSFetchedResultsControllerDelegate,
    HMRemakePresenterDelegate,
    HMStoreDelegate,
    UICollectionViewDelegateFlowLayout,
    MONActivityIndicatorViewDelegate
>

@property (weak, nonatomic) IBOutlet UIButton *guiRemakeButton;
@property (weak, nonatomic) IBOutlet UIButton *guiRemakeButton2;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiRemakeActivity;
@property (weak, nonatomic) IBOutlet HMRegularFontLabel *noRemakesLabel;
@property (weak, nonatomic) IBOutlet UIView *guiStoryMovieContainer;


@end
