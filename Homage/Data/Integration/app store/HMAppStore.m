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

+(NSString *)saveUserRemakesTokenProductID
{
    NSString *saveTokenProductName = HMServer.sh.configurationInfo[@"user_save_remakes_token"];
    return [HMAppStore productIdentifierForID:saveTokenProductName];
}

+(NSInteger)saveUserRemakesTokensCount
{
    NSString *productIdentifier = [HMAppStore saveUserRemakesTokenProductID];
    NSNumber *tokens = [[NSUserDefaults standardUserDefaults] objectForKey:productIdentifier];
    if (tokens == nil) return 0;
    return tokens.integerValue;
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

    // Save remake video consumubles
    [pids addObject:[HMAppStore saveUserRemakesTokenProductID]];
    
    return pids;
}

-(NSString *)productTypeByPID:(NSString *)pid
{
    if ([pid isEqualToString:[HMAppStore bundleProductID]]) {
        return @"bundle";
    } else if ([pid isEqualToString:[HMAppStore saveUserRemakesTokenProductID]]) {
        return @"save_token";
    }
    return @"story";
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

+(BOOL)maySaveAnotherRemakeToDevice
{
    // If bundle was purchased, user can save her remakes videos without limitations.
    if ([HMAppStore didUnlockBundle]) return YES;
    
    // Check if any download/save tokens are still available.
    NSInteger tokensLeft = [HMAppStore saveUserRemakesTokensCount];
    if (tokensLeft > 0) return YES;
    
    // No tokens left.
    // User will have to buy more before
    // being allowed to download more remakes.
    return NO;
}

+(void)userUsedOneSaveRemakeToken
{
    // Check if this is relevant to the save to device policy in settings.
    // If settings not configured to premium save to device, do nothing.
    HMUserSaveToDevicePolicy savePolicy = [HMServer.sh.configurationInfo[@"user_save_remakes_policy"] integerValue];
    if (savePolicy != HMUserSaveToDevicePolicyPremium) return;
    
    // If bundle was purchased, nothing to do.
    // User can download unlimited number of remakes.
    if ([HMAppStore didUnlockBundle]) return;

    // Use up one save token.
    NSInteger tokensLeft = [HMAppStore saveUserRemakesTokensCount];
    tokensLeft = MAX(0, tokensLeft-1);
    NSString *productIdentifier = [HMAppStore saveUserRemakesTokenProductID];
    [[NSUserDefaults standardUserDefaults] setObject:@(tokensLeft) forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void)saveUserRemakesTokensIncreaseBy:(NSInteger)increaseAmount
{
    // Add tokens by amount.
    NSInteger tokensLeft = [HMAppStore saveUserRemakesTokensCount];
    tokensLeft += increaseAmount;
    
    // Save.
    NSString *productIdentifier = [HMAppStore saveUserRemakesTokenProductID];
    [[NSUserDefaults standardUserDefaults] setObject:@(tokensLeft) forKey:productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
        NSString *productType = [self productTypeByPID:productIdentifier];
        
        tInfo = @{
                  @"product_id":productIdentifier,
                  @"product_type":productType
                  };
        
        // Handle transaction states.
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                
                //
                // Purchase
                //
                HMGLogDebug(@"TSTATE purchased: %@", transaction.transactionIdentifier);
                
                if ([productType isEqualToString:@"bundle"] ||
                    [productType isEqualToString:@"story"]) {
                    // Non consumable product
                    [HMAppStore markProductAsPurchasedWithIdentifier:productIdentifier];
                } else {
                    // Consumable save to device token.
                    [HMAppStore saveUserRemakesTokensIncreaseBy:1];
                }

                // Gather info.
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

-(void)cleanup
{
    self.productsRequest.delegate = nil;
    self.productsRequest = nil;
}

@end
