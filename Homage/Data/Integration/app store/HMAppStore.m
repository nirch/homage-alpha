//
//  HMAppStore.m
//  Homage
//
//  Created by Aviv Wolf on 12/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMAppStore.h"
#import <StoreKit/StoreKit.h>
#import "HMNotificationCenter.h"
#import "HMServer+AppConfig.h"
#import "DB.h"
#import "HMAppDelegate.h"
#import <Mixpanel.h>

@interface HMAppStore()

@property (nonatomic) SKProductsRequest *productsRequest;
@property (nonatomic) NSArray *products;
@property (nonatomic) NSMutableDictionary *productsByID;
@property (nonatomic) BOOL isAlreadyListeningToTransactions;

@end

@implementation HMAppStore

-(id)init
{
    self = [super init];
    if (self) {
        self.isAlreadyListeningToTransactions = NO;
    }
    return self;
}

-(void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark - Products identifiers
+(NSString *)productsPrefix
{
    return [HMServer.sh productsPrefix];
}

+(NSString *)productIdentifierForID:(NSString *)sID
{
    return [NSString stringWithFormat:@"%@_%@", [HMAppStore productsPrefix], sID];
}

+(NSString *)bundleProductID
{
    NSString *campaignID = [HMServer.sh campaignID];
    return [HMAppStore productIdentifierForID:campaignID];
}

+(NSSet *)allProductsIdentifiers
{
    NSMutableSet *pids = [NSMutableSet new];
    
    // Add the identifier of the full bundle.
    NSString *bundlePID = [HMAppStore bundleProductID];
    [pids addObject:bundlePID];
    
    // Add identifiers for all the stories.
    for (Story *story in [Story allActivePremiumStoriesInContext:DB.sh.context]) {
        [pids addObject:story.productIdentifier];
    }
    return pids;
}

-(NSString *)productTypeByPID:(NSString *)pid
{
    if ([pid isEqualToString:[HMAppStore bundleProductID]]) {
        return @"bundle";
    }
    return @"story";
    
    // TODO: save to camera roll token implementation.
}

#pragma mark - Purchases
+(void)markProductAsPurchasedWithIdentifier:(NSString *)identifier
{
    [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:identifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(BOOL)didBuyProductWithIdentifier:(NSString *)identifier
{
    NSNumber *purchased = [[NSUserDefaults standardUserDefaults] objectForKey:identifier];
    if (purchased) return YES;
    return NO;
}

+(BOOL)didUnlockBundle
{
    NSString *productIdentifier = [HMAppStore bundleProductID];
    return [HMAppStore didBuyProductWithIdentifier:productIdentifier];
}

+(BOOL)didUnlockStoryWithID:(NSString *)storyID
{
    // If bundle was purchased, all stories are considered payed for.
    if ([HMAppStore didUnlockBundle]) return YES;
    
    // Check if the specific story was payed for.
    NSString *productIdentifier = [HMAppStore productIdentifierForID:storyID];
    return [HMAppStore didBuyProductWithIdentifier:productIdentifier];
}


#pragma mark - StoreKit
-(void)requestInfo
{
    NSSet *productIdentifiers = [HMAppStore allProductsIdentifiers];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

-(void)restorePurchases
{
    // Listen to transactions if not already listening
    if (!self.isAlreadyListeningToTransactions) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.isAlreadyListeningToTransactions = YES;
    }

    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

-(void)buyProductWithIdentifier:(NSString *)productIdentifier
{
    // Ensure product is relevant.
    SKProduct *product = self.productsByID[productIdentifier];
    if (product == nil) return;

    // Listen to transactions if not already listening
    if (!self.isAlreadyListeningToTransactions) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.isAlreadyListeningToTransactions = YES;
    }

    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}


#pragma mark - SKProductsRequestDelegate
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.products = response.products;
    self.productsByID = [NSMutableDictionary new];
    
    // Products
    for (SKProduct *product in self.products) {
        // Product
        self.productsByID[product.productIdentifier] = product;
        HMGLogDebug(@"Product:%@ id:%@", product.localizedTitle, product.productIdentifier);
    }
    
    // Invalid products
    NSArray *invalidProducts = response.invalidProductIdentifiers;
    for (NSString *invalidProductId in invalidProducts)
    {
        NSLog(@"Invalid product id: %@" , invalidProductId);
    }
    
    // Notify about updated info of products
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APP_STORE_PRODUCTS object:nil];
}

-(SKProduct *)productForIdentifier:(NSString *)productIdentifier
{
    return self.productsByID[productIdentifier];
}

-(BOOL)isRelevantProductIdentifier:(NSString *)productIdentifier
{
    if (self.productsByID[productIdentifier]) {
        return YES;
    }
    return NO;
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    BOOL transactionsUpdate = NO;
    NSMutableDictionary *transactionsInfo = [NSMutableDictionary new];
    
    //
    // Iterate all the transactions
    //
    for (SKPaymentTransaction * transaction in transactions) {
        // Ignore irrelevant products.
        if (![self isRelevantProductIdentifier:transaction.payment.productIdentifier]) {
            continue;
        }

        // Gather some info about this transaction.
        NSString *productIdentifier = transaction.payment.productIdentifier;
        NSDictionary *info = @{
                               @"transaction":transaction,
                               @"productIdentifier": productIdentifier,
                               @"transactionState": @(transaction.transactionState)
                               };
        
        // Log info.
        HMGLogDebug(@"%@", info);

        NSDictionary *tInfo;
        tInfo = @{
                  @"product_id":productIdentifier,
                  @"product_type":[self productTypeByPID:productIdentifier],
                  @"transaction_id":transaction.transactionIdentifier
                  };
        
        // Handle transaction states.
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                
                //
                // Purchase
                //
                HMGLogDebug(@"TSTATE purchased: %@", transaction.transactionIdentifier);
                [HMAppStore markProductAsPurchasedWithIdentifier:productIdentifier];
                transactionsInfo[productIdentifier] = info;
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                transactionsUpdate = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APP_STORE_PURCHASED_ITEM object:self userInfo:nil];
                
                // Notify mixpanel about purchase event.
                [[Mixpanel sharedInstance] track:@"StoreProductPurchased" properties:tInfo];
                
                break;
            case SKPaymentTransactionStateFailed:
                
                //
                // Transaction failed
                //
                HMGLogDebug(@"TSTATE failed: %@", transaction.transactionIdentifier);
                transactionsInfo[productIdentifier] = info;
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                transactionsUpdate = YES;

                // Notify mixpanel about purchase event.
                [[Mixpanel sharedInstance] track:@"StoreProductTransactionFailed" properties:tInfo];
                
                break;
            case SKPaymentTransactionStateRestored:
                //
                //  Product Restored
                //
                HMGLogDebug(@"TSTATE restored: %@", transaction.transactionIdentifier);
                [HMAppStore markProductAsPurchasedWithIdentifier:productIdentifier];
                transactionsInfo[productIdentifier] = info;
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                transactionsUpdate = YES;

                // Notify mixpanel about purchase event.
                [[Mixpanel sharedInstance] track:@"StoreProductRestored" properties:tInfo];

                break;
            default:
                break;
        }
    };

    // If any of the transactions failed, purchased or restored, notify about it.
    if (transactionsUpdate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APP_STORE_TRANSACTIONS_UPDATE
                                                            object:nil
                                                          userInfo:transactionsInfo];
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    if (error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APP_STORE_TRANSACTIONS_UPDATE
                                                            object:nil
                                                          userInfo:@{@"error":error}];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed"
                                   message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:LS(@"OK")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APP_STORE_TRANSACTIONS_UPDATE
                                                        object:nil
                                                      userInfo:nil];
}

@end
