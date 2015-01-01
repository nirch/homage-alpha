//
//  HMInAppStoreViewController.m
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMInAppStoreViewController.h"
#import "DB.h"
#import "HMStoreProductsViewController.h"
#import "HMNotificationCenter.h"
#import "HMAppStore.h"

@interface HMInAppStoreViewController ()

@property (weak, nonatomic) IBOutlet UIButton *guiRestoreButton;
@property (weak) HMStoreProductsViewController *productsVC;

@end

@implementation HMInAppStoreViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.guiRestoreButton.hidden = YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initObservers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    // Observe products info updates
    [nc addUniqueObserver:self
                 selector:@selector(onProductsInfoUpdated:)
                     name:HM_NOTIFICATION_APP_STORE_PRODUCTS
                   object:nil];
    
    // Observe transactions
    [nc addUniqueObserver:self
                 selector:@selector(onTransactionsUpdate:)
                     name:HM_NOTIFICATION_APP_STORE_TRANSACTIONS_UPDATE
                   object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_APP_STORE_PRODUCTS object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_APP_STORE_TRANSACTIONS_UPDATE object:nil];
}

#pragma mark - Observer handlers
-(void)onProductsInfoUpdated:(NSNotification *)notification
{
    [self updateRestoreButton];
}

-(void)onTransactionsUpdate:(NSNotification *)notification
{
    [self updateRestoreButton];
}

#pragma mark - Restore button
-(void)updateRestoreButton
{
    self.guiRestoreButton.hidden = [HMAppStore didUnlockBundle];
}

#pragma mark - Store
+(HMInAppStoreViewController *)storeVCForStory:(Story *)story
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InAppStore" bundle:nil];
    HMInAppStoreViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"InAppStore"];
    return vc;
}

+(HMInAppStoreViewController *)storeVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InAppStore" bundle:nil];
    HMInAppStoreViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"InAppStore"];
    return vc;
}


#pragma mark - segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"products segue"]) {
        self.productsVC = segue.destinationViewController;
    }
}

#pragma mark - Orientation
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void)done
{
    [self.delegate storeDidFinishWithInfo:nil];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissButton:(id)sender
{
    [self done];
}

- (IBAction)onPressedRestorePurchases:(UIButton *)sender
{
    sender.hidden = YES;
    [self.productsVC restorePurchases];
}


@end
