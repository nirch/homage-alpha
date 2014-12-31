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


@interface HMStoreProductsViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *guiProductsCV;
@property (weak, nonatomic) IBOutlet UILabel *guiLoadingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *guiActivity;
@property (weak, nonatomic) IBOutlet UIView *guiActivityContainer;



@property (nonatomic, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) HMAppStore *appStore;

@end

@implementation HMStoreProductsViewController

@synthesize fetchedResultsController = _fetchedResultsController;

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initGUI];
    [self initAppStore];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refreshFromLocalStorage];
    [self initObservers];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self removeObservers];
}

#pragma mark - Observers
-(void)initObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // Observe closing animation
    [nc addUniqueObserver:self
                 selector:@selector(onProductsInfoUpdated:)
                     name:HM_NOTIFICATION_APP_STORE_PRODUCTS
                   object:nil];
}

-(void)removeObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_APP_STORE_PRODUCTS object:nil];
}

#pragma mark - Observer handlers
-(void)onProductsInfoUpdated:(NSNotification *)notification
{
    [self showProducts];
}

#pragma mark - GUI initializations
-(void)initGUI
{
    self.guiActivityContainer.hidden = NO;
    self.guiActivityContainer.alpha = 0;
    self.guiActivityContainer.transform = CGAffineTransformMakeTranslation(0, 80);
    [self.guiActivity startAnimating];
    [UIView animateWithDuration:2.0 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.guiActivityContainer.alpha = 1;
        self.guiActivityContainer.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
}

-(void)showProducts
{
    [UIView animateWithDuration:0.2
                          delay:0.3
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.guiActivityContainer.transform = CGAffineTransformMakeTranslation(0, -700);
                     } completion:^(BOOL finished) {
                         self.guiActivityContainer.hidden = YES;
                     }];
    
    self.guiProductsCV.hidden = NO;
    self.guiProductsCV.alpha = 0;
    [UIView animateWithDuration:0.8 animations:^{
        self.guiProductsCV.alpha = 1;
    } completion:^(BOOL finished) {
    }];
    
    [self.guiProductsCV reloadData];
}


#pragma mark - App Store
-(void)initAppStore
{
    self.appStore = [HMAppStore new];
    //[self.appStore requestInfoForProducts];
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
    SKProduct *product = [self.appStore productForIdentifier:[HMServer.sh campaignID]];
    if (product) {
        cell.guiTitle.text = product.localizedTitle;
        [cell.guiBuyButton setTitle:LS(@"STORE_BUY_BUTTON") forState:UIControlStateNormal];
        cell.guiText.text = product.localizedDescription;
        cell.guiPrice.text = product.price.stringValue;
        cell.guiText.alpha = 1.0;
        cell.guiTitle.alpha = 1.0;
        cell.guiImage.alpha = 1.0;
        cell.guiBuyButton.alpha = 1.0;
    } else {
        cell.guiTitle.text = LS(@"STORE_MISSING_PRODUCT_TITLE");
        [cell.guiBuyButton setTitle:LS(@"STORE_UNAVAILABLE_BUTTON") forState:UIControlStateNormal];
        cell.guiText.text = LS(@"STORE_MISSING_PRODUCT_TEXT");
        cell.guiPrice.text = @"";
        cell.guiText.alpha = 0.2;
        cell.guiTitle.alpha = 0.2;
        cell.guiImage.alpha = 0.2;
        cell.guiBuyButton.alpha = 0.2;
    }
}

-(void)configureStoryCell:(HMStoreProductCollectionViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    Story *story = [self.fetchedResultsController objectAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:0]];
    
    SKProduct *product = [self.appStore productForIdentifier:story.sID];
    
    if (product) {
        cell.guiTitle.text = product.localizedTitle;
        [cell.guiBuyButton setTitle:LS(@"STORE_BUY_BUTTON") forState:UIControlStateNormal];
        cell.guiText.text = product.localizedDescription;
        cell.guiText.alpha = 1.0;
        cell.guiPrice.text = product.price.stringValue;
        cell.guiTitle.alpha = 1.0;
        cell.guiImage.alpha = 1.0;
        cell.guiBuyButton.alpha = 1.0;
    } else {
        cell.guiTitle.text = LS(@"STORE_MISSING_PRODUCT_TITLE");
        [cell.guiBuyButton setTitle:LS(@"STORE_UNAVAILABLE_BUTTON") forState:UIControlStateNormal];
        cell.guiText.text = LS(@"STORE_MISSING_PRODUCT_TEXT");
        cell.guiPrice.text = @"";
        cell.guiText.alpha = 0.2;
        cell.guiTitle.alpha = 0.2;
        cell.guiImage.alpha = 0.2;
        cell.guiBuyButton.alpha = 0.2;
    }
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return CGSizeMake(320, 170);
    } else {
        return CGSizeMake(320, 60);
    }
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
          viewForSupplementaryElementOfKind:(NSString *)kind
                                atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter])
        return nil;

    static NSString *identifier = @"section header view";
    HMStoreSectionView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                        withReuseIdentifier:identifier
                                                                               forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        view.guiTitle.text = LS(@"STORE_TITLE");
    } else {
        view.guiTitle.text = LS(@"STORE_STORIES_TITLE");
    }
    
    return view;
}

#pragma mark - UICollectionViewDelegate

@end
