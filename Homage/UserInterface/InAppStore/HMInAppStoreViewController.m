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
#import "AMBlurView.h"
#import "HMParentalControlViewController.h"
#import <Mixpanel.h>

@interface HMInAppStoreViewController ()

@property (weak, nonatomic) IBOutlet UIView *guiParentalControlContainer;

@property (weak, nonatomic) IBOutlet UIView *guiActionsBar;
@property (weak, nonatomic) IBOutlet UIView *guiActionsBarBlurredView;
@property (weak, nonatomic) IBOutlet UIButton *guiRestoreButton;

@property (weak) HMStoreProductsViewController *productsVC;
@property (nonatomic) NSInteger purchasesMadeInSession;
@property (nonatomic) Story *prioritizedStory;

@end

@implementation HMInAppStoreViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
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

-(void)initGUI
{
    self.guiRestoreButton.hidden = YES;
    self.guiRestoreButton.userInteractionEnabled = NO;
    self.guiRestoreButton.alpha = 0.3;
    [[AMBlurView new] insertIntoView:self.guiActionsBarBlurredView];
}

#pragma mark - Status bar
-(BOOL)prefersStatusBarHidden
{
    return YES;
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

    // Observe purchases made
    [nc addUniqueObserver:self
                 selector:@selector(onPurchaseMade:)
                     name:HM_NOTIFICATION_APP_STORE_PURCHASED_ITEM
                   object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_APP_STORE_PRODUCTS object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_APP_STORE_TRANSACTIONS_UPDATE object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_APP_STORE_PURCHASED_ITEM object:nil];
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

-(void)onPurchaseMade:(NSNotification *)notification
{
    self.purchasesMadeInSession += 1;
}

#pragma mark - Restore button
-(void)updateRestoreButton
{
    self.guiRestoreButton.hidden = [HMAppStore didUnlockBundle];
}

#pragma mark - Store
+(HMInAppStoreViewController *)storeVC
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InAppStore" bundle:nil];
    HMInAppStoreViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"InAppStore"];
    return vc;
}

+(HMInAppStoreViewController *)storeVCForStory:(Story *)story
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"InAppStore" bundle:nil];
    HMInAppStoreViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"InAppStore"];
    vc.prioritizedStory = story;
    return vc;
}

#pragma mark - segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"products segue"]) {
        
        // A weak reference to the product VC
        self.productsVC = segue.destinationViewController;
        self.productsVC.prioritizedStory = self.prioritizedStory;
        
    } else if ([segue.identifier isEqualToString:@"parent control segue"]) {
        
        HMParentalControlViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        
    }
}

#pragma mark - Orientation
-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void)done
{
    NSDictionary *info = @{
                           K_STORE_PURCHASES_COUNT:@(self.purchasesMadeInSession),
                           K_STORE_OPENED_FOR:@(self.openedFor)
                           };
    [self.delegate storeDidFinishWithInfo:info];
}

#pragma mark - HMStoreManagerDelegate
-(void)parentalControlValidatedSuccessfully
{    
    [UIView animateWithDuration:0.2 animations:^{
        self.guiParentalControlContainer.alpha = 0;
        self.guiRestoreButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        self.guiParentalControlContainer.hidden = YES;
        self.guiRestoreButton.userInteractionEnabled = YES;
    }];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedDismissButton:(id)sender
{
    // Report to mixpanel
    [[Mixpanel sharedInstance] track:@"StoreDismissButtonClicked"];

    // Done
    [self done];
}

- (IBAction)onPressedRestorePurchases:(UIButton *)sender
{
    // Rstore puschases
    sender.hidden = YES;
    [self.productsVC restorePurchases];
}


@end
