//
//  HMGMeTabVC.h
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "DB.h"


@interface HMGMeTabVC : UIViewController <UITextViewDelegate>

// For now, removed the faulty NSFetchedResultsController implementation <-- NSFetchedResultsControllerDelegate

-(void)refetchRemakesFromServer;
-(void)refreshFromLocalStorage;

@end
