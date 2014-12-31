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

@interface HMAppStore()

@property (nonatomic) SKProductsRequest *productsRequest;
@property (nonatomic) NSArray *products;
@property (nonatomic) NSMutableDictionary *productsByID;

@end

@implementation HMAppStore

-(NSArray *)allProductsIdentifiers
{
    //NSMutableArray *products = [NSMutableArray new];
    
    // Products prefix
   // NSString *prefix = [HMServer.sh pro]
    
    // Bundle
    
    // Add bundle
    return nil;
}

-(NSString *)productsPrefix
{
    return [HMServer.sh productsPrefix];
}

-(void)requestInfo
{
    NSSet *productIdentifiers = [NSSet setWithObjects:@"54919516454c61f4080000e5", @"54902e1014aa8e2015000c41", nil];
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

-(NSString *)bundleProductID
{
    NSString *prefix = [self productsPrefix];
    NSString *campaignID = [HMServer.sh campaignID];
    return [NSString stringWithFormat:@"%@_%@", prefix, campaignID];
}

-(NSArray *)storiesProductID
{
//    NSMutableArray *pids = [NSMutableArray new];
//    NSArray *premiumStories = [Story allPremiumStories];
//    for (Story *story in premiumStories) {
//        [pids addObject:story.productID];
//    }
//    return pids;
    return nil;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_APP_STORE_PRODUCTS
                                                        object:nil];
}

-(SKProduct *)productForIdentifier:(NSString *)productIdentifier
{
    return self.productsByID[productIdentifier];
}

@end
