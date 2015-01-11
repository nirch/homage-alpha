//
//  HMStoreProductsViewController.m
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStoreProductsViewController.h"
#import "DB.h"
#import "HMStoreProductCollectionViewCell.h"
#import "HMAppStore.h"
#import "HMNotificationCenter.h"
#import "HMStoreSectionView.h"
#import "HMServer+AppConfig.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HMStyle.h"
#import "UIView+MotionEffect.h"
#import <Mixpanel.h>

@interface HMStoreProductsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *guiBackgroundImage;
@property (weak, nonatomic) IBOutlet UIView *guiLogoContainer;

@property (weak, nonatomic) IBOutlet UICollectionView *guiProductsCV;
@property (weak, nonatomic) IBOutlet UILabel *guiLoadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIView *guiActivityContainer;

@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) HMAppStore *appStore;
@property (nonatomic) BOOL inTransactions;

@end

@implementation HMStoreProductsViewController

@synthesize fetchedResultsController = _fetchedResultsController;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshFromLocalStorage];
    [self initObservers];
    [self initAppStore];
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
    [self showProducts];
}

-(void)onTransactionsUpdate:(NSNotification *)notification
{
    // Finish the transactions update.
    if (self.inTransactions) {
        [self finishedAllTransactionsExitingStore:NO];
    }
}

#pragma mark - GUI initializations
-(void)initGUI
{
    self.inTransactions = NO;
    self.guiProductsCV.hidden = YES;
    self.guiActivityContainer.layer.cornerRadius = 10;
    
    [self.guiBackgroundImage addMotionEffectWithAmount:-30];
    
    [self showActivity];
}

-(void)showProducts
{
    [self hideActivity];
    self.guiProductsCV.hidden = NO;
    self.guiProductsCV.alpha = 0;
    [UIView animateWithDuration:0.8 animations:^{
        self.guiProductsCV.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    
    [self.guiProductsCV reloadData];
}

-(void)showActivity
{
    self.guiActivityContainer.transform = CGAffineTransformIdentity;
    self.guiActivityContainer.alpha = 0;
    self.guiActivityContainer.hidden = NO;
    [self.guiActivity startAnimating];
    [UIView animateWithDuration:0.3 animations:^{
        self.guiActivityContainer.alpha = 1;
    }];
}

-(void)hideActivity
{
    [UIView animateWithDuration:0.2
                          delay:0.3
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.guiActivityContainer.transform = CGAffineTransformMakeTranslation(0, -300);
                         self.guiActivityContainer.alpha = 0;
                     } completion:^(BOOL finished) {
                         self.guiActivityContainer.hidden = YES;
                         [self.guiActivity stopAnimating];
                     }];
}

#pragma mark - App Store
-(void)initAppStore
{
    self.appStore = [HMAppStore new];
    [self.appStore requestInfo];
}

#pragma mark - NSFetchedResultsController
// Lazy instantiation of the fetched results controller.
-(NSFetchedResultsController *)fetchedResultsController
{
    // If already exists, just return it.
    if (_fetchedResultsController) return _fetchedResultsController;
    
    // Define fetch request.
    // Fetches all premium stories with isActive=@(YES) and isPremium=@(YES)
    // Orders them by orderID (ascending order)
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:HM_STORY];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isActive=%@ AND isPremium=%@", @(YES), @(YES)];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"orderID" ascending:YES]];
    fetchRequest.fetchBatchSize = 20;
    
    // Create the fetched results controller and return it.
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:DB.sh.context sectionNameKeyPath:nil cacheName:nil];
    //_fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

-(NSString *)priceLabelForPrice:(NSDecimalNumber *)price locale:(NSLocale *)locale
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setLocale:locale];
    return [numberFormatter stringFromNumber:price];
}

-(void)resetFetchedResultsController
{
    _fetchedResultsController = nil;
}

-(void)refreshFromLocalStorage
{
    NSError *error;
    _fetchedResultsController = nil;
    [self.fetchedResultsController performFetch:&error];
}

#pragma mark - UICollectionViewDataSource
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section ==0) return 1;
    NSInteger count = self.fetchedResultsController.fetchedObjects.count;
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *bundleCellIdentifier = @"bundle cell";
    static NSString *productCellIdentifier = @"product cell";
    NSString *cellIdentifier = indexPath.section == 0 ? bundleCellIdentifier : productCellIdentifier;
    
    HMStoreProductCollectionViewCell *cell = (HMStoreProductCollectionViewCell *)[self.guiProductsCV dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (indexPath.section == 0) {
        // Main Bundle
        [self configureBundleCell:cell forIndexPath:indexPath];
    } else {
        [self configureStoryCell:cell forIndexPath:indexPath];
    }
    return cell;
}

-(void)configureBundleCell:(HMStoreProductCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    NSString *productIdentifier = [HMAppStore bundleProductID];
    SKProduct *product = [self.appStore productForIdentifier:productIdentifier];
    if (product == nil) {
        [self unavailableProductInCell:cell];
        return;
    }
    
    cell.guiTitle.text = product.localizedTitle;
    [cell.guiBuyButton setTitle:LS(@"STORE_BUY_BUTTON") forState:UIControlStateNormal];
    cell.guiText.text = product.localizedDescription;
    cell.guiPrice.text = [self priceLabelForPrice:product.price locale:product.priceLocale];
    cell.guiText.alpha = 1.0;
    cell.guiTitle.alpha = 1.0;
    cell.guiImage.alpha = 1.0;
    cell.guiBuyButton.alpha = 1.0;
    cell.guiBuyButton.enabled = YES;

    
    // If already purchased.
    if ([HMAppStore didUnlockBundle]) {
        cell.guiBuyButton.hidden = YES;
        cell.guiPrice.text = LS(@"STORE_ITEM_UNLOCKED");
    }
    
    // ************
    // *  STYLES  *
    // ************
    cell.guiTitle.textColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_TITLE];
    cell.guiText.textColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_DESCRIPTION];
    cell.guiSepLine.backgroundColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_LINE];
    cell.guiImage.layer.cornerRadius = [HMStyle.sh floatValueForKey:V_STORE_THUMBS_CORNER_RADIUS];
}


-(void)configureStoryCell:(HMStoreProductCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    SKProduct *product = [self.appStore productForIdentifier:story.productIdentifier];
    if (product == nil) {
        [self unavailableProductInCell:cell];
        return;
    }
    
    cell.guiTitle.text = product.localizedTitle;
    [cell.guiBuyButton setTitle:LS(@"STORE_BUY_BUTTON") forState:UIControlStateNormal];
    cell.guiBuyButton.tag = indexPath.item;
    cell.guiBuyButton.hidden = NO;
    cell.guiText.text = product.localizedDescription;
    cell.guiText.alpha = 1.0;
    cell.guiPrice.text = [self priceLabelForPrice:product.price locale:product.priceLocale];
    cell.guiTitle.alpha = 1.0;
    cell.guiImage.alpha = 1.0;
    cell.guiBuyButton.alpha = 1.0;
    cell.guiBuyButton.enabled = YES;

    
    NSURL *url = [NSURL URLWithString:story.thumbnailURL];
    [cell.guiImage sd_setImageWithURL:url placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        cell.guiImage.image = image;
    }];
    
    // If already purchased.
    if ([HMAppStore didUnlockStoryWithID:story.sID]) {
        cell.guiBuyButton.hidden = YES;
        cell.guiPrice.text = LS(@"STORE_ITEM_UNLOCKED");
    }
    
    // ************
    // *  STYLES  *
    // ************
    cell.guiTitle.textColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_TITLE];
    cell.guiText.textColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_DESCRIPTION];
    cell.guiSepLine.backgroundColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_LINE];
    cell.guiImage.layer.cornerRadius = [HMStyle.sh floatValueForKey:V_STORE_THUMBS_CORNER_RADIUS];
}

-(void)unavailableProductInCell:(HMStoreProductCollectionViewCell *)cell
{
    // Something is wrong with the app store definitions.
    // Product unavailable :-(
    // Should be fixed in itunes connect.
    cell.guiTitle.text = LS(@"STORE_MISSING_PRODUCT_TITLE");
    [cell.guiBuyButton setTitle:LS(@"STORE_UNAVAILABLE_BUTTON") forState:UIControlStateNormal];
    cell.guiText.text = LS(@"STORE_MISSING_PRODUCT_TEXT");
    cell.guiPrice.text = @"";
    cell.guiText.alpha = 0.2;
    cell.guiTitle.alpha = 0.2;
    cell.guiImage.alpha = 0.2;
    cell.guiBuyButton.alpha = 0.2;
    cell.guiBuyButton.enabled = NO;
    
    // ************
    // *  STYLES  *
    // ************
    cell.guiImage.layer.cornerRadius = [HMStyle.sh floatValueForKey:V_STORE_THUMBS_CORNER_RADIUS];
    cell.guiSepLine.backgroundColor = [HMStyle.sh colorNamed:C_STORE_PRODUCT_LINE];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return CGSizeMake(320, 140);
    } else {
        return CGSizeMake(320, 80);
    }
}

#pragma mark - UICollectionViewDelegate

#pragma mark - Scroll View Delegate
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSInteger y =  scrollView.contentInset.top + scrollView.contentOffset.y;
    if (y <= 1) {
        [self showStoreLogoIfNotShown];
    } else {
        [self hideStoreLogoIfShown];
    }
}

-(void)showStoreLogoIfNotShown
{
    if (self.guiLogoContainer.alpha==1) return;
    
    [UIView animateWithDuration:0.7
                          delay:0
         usingSpringWithDamping:0.3
          initialSpringVelocity:0.1
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.guiLogoContainer.alpha = 1;
                         self.guiLogoContainer.transform = CGAffineTransformIdentity;;
                     } completion:nil];
}

-(void)hideStoreLogoIfShown
{
    if (self.guiLogoContainer.alpha==0) return;
    [UIView animateWithDuration:0.2 animations:^{
        CGAffineTransform t = CGAffineTransformMakeScale(1.2,1.2);
        t = CGAffineTransformTranslate(t, 0, -30);
        self.guiLogoContainer.transform = t;
        self.guiLogoContainer.alpha = 0;
    }];
}

#pragma mark - In transaction flow
-(void)startTransactions
{
    [self showActivity];
    self.inTransactions = YES;
    self.guiProductsCV.userInteractionEnabled = NO;
    [UIView animateWithDuration:1.0 animations:^{
        self.guiProductsCV.alpha = 0.3;
    }];
}

-(void)finishedAllTransactionsExitingStore:(BOOL)shouldExitStore
{
    if (!self.inTransactions) return;
    
    if (shouldExitStore) {
        // Dismiss the store.
        return;
    }
    
    // Stay in the store and allow user to buy more stuff.
    self.inTransactions = NO;
    self.guiProductsCV.userInteractionEnabled = YES;
    [self hideActivity];
    [UIView animateWithDuration:1.0 animations:^{
        self.guiProductsCV.alpha = 1.0;
    }];
    [self.guiProductsCV reloadData];
}

#pragma mark - Restore purchases
-(void)restorePurchases
{
    // Disable collection view while handling purchase.
    [self startTransactions];
    
    // Restore purchases.
    [self.appStore restorePurchases];
}

#pragma mark - IB Actions
// ===========
// IB Actions.
// ===========
- (IBAction)onPressedBuyBundleButton:(id)sender
{
    [sender setTitle:LS(@"STORE_PROCESSING_BUTTON") forState:UIControlStateNormal];
    
    // Disable collection view while handling purchase.
    [self startTransactions];

    // Report to mixpanel
    NSDictionary *info = @{
                           @"product_id":[HMAppStore bundleProductID],
                           @"product_type":@"bundle",
                           @"object_id":[HMServer.sh campaignID]
                           };
    [[Mixpanel sharedInstance] track:@"StoreProductClicked" properties:info];

    
    // Make the purchase.
    [self.appStore buyProductWithIdentifier:[HMAppStore bundleProductID]];
}

- (IBAction)onPressedBuyStoryButton:(UIButton *)sender
{
    Story *story = self.fetchedResultsController.fetchedObjects[sender.tag];
    if (!story) return;
    
    [sender setTitle:LS(@"STORE_PROCESSING_BUTTON") forState:UIControlStateNormal];
    
    // Disable collection view while handling purchase.
    [self startTransactions];
    
    // Report to mixpanel
    NSDictionary *info = @{
                           @"product_id":story.productIdentifier,
                           @"product_type":@"story",
                           @"object_id":story.sID
                           };
    [[Mixpanel sharedInstance] track:@"StoreProductClicked" properties:info];
    
    // Make the purchase.
    [self.appStore buyProductWithIdentifier:story.productIdentifier];
}


@end
