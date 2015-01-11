//
//  HMAppStore.h
//  Homage
//
//  Created by Aviv Wolf on 12/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <StoreKit/StoreKit.h>

@interface HMAppStore : NSObject<
    SKProductsRequestDelegate,
    SKPaymentTransactionObserver
>

#pragma mark - Products identifiers
+(NSString *)productsPrefix;
+(NSString *)productIdentifierForID:(NSString *)sID;
+(NSString *)bundleProductID;
+(NSSet *)allProductsIdentifiers;

#pragma mark - Purchases
+(void)markProductAsPurchasedWithIdentifier:(NSString *)identifier;
+(BOOL)didBuyProductWithIdentifier:(NSString *)identifier;
+(BOOL)didUnlockBundle;
+(BOOL)didUnlockStoryWithID:(NSString *)storyID;

#pragma mark - StoreKit
-(void)restorePurchases;
-(void)buyProductWithIdentifier:(NSString *)productIdentifier;
-(void)requestInfo;
-(SKProduct *)productForIdentifier:(NSString *)productIdentifier;

@end
