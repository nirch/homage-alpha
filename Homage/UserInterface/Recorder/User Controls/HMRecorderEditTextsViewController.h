//
//  HMRecorderEditTextsViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMRecorderChildInterface.h"

@interface HMRecorderEditTextsViewController : UITableViewController<
    HMRecorderChildInterface,
    UITableViewDataSource,
    UITableViewDelegate,
    UITextFieldDelegate
>

-(void)updateValues;

@end
