//
//  HMInAppStoreViewController.m
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMInAppStoreViewController.h"
#import "DB.h"

@interface HMInAppStoreViewController ()

@end

@implementation HMInAppStoreViewController

+(HMInAppStoreViewController *)storeVCForStory:(Story *)story
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InAppStore" bundle:nil];
    HMInAppStoreViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"InAppStore"];
    return vc;
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissButton:(id)sender
{
    [self.delegate storeDidFinishWithInfo:nil];
}



@end
