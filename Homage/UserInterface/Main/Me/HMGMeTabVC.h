//
//  HMGMeTabVC.h
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "DB.h"
#import "HMStoreDelegate.h"
#import "HMDownloadDelegate.h"

@interface HMGMeTabVC : UIViewController <
    UITextViewDelegate,
    HMStoreDelegate,
    HMDownloadDelegate
>

// For now, removed the faulty NSFetchedResultsController implementation <-- NSFetchedResultsControllerDelegate

@property (weak, nonatomic) IBOutlet UIScrollView *guiScrollView;

-(void)refetchRemakesFromServer;
-(void)refreshFromLocalStorage;

@end
