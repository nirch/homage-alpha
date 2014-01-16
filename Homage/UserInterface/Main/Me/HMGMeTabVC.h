//
//  HMGMeTabVC.h
//  HomageApp
//
//  Created by Yoav Caspin on 1/5/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "DB.h"
#import <InAppSettingsKit/IASKAppSettingsViewController.h>

@interface HMGMeTabVC : UIViewController <IASKSettingsDelegate, UITextViewDelegate,NSFetchedResultsControllerDelegate> {
    IASKAppSettingsViewController *appSettingsViewController;
}

@end
