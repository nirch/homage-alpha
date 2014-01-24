//
//  HMRecorderEditingTextCell.h
//  Homage
//
//  Created by Aviv Wolf on 1/24/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface HMRecorderEditingTextCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *guiTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIButton *guiRetryButton;

@end
