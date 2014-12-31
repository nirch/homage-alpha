//
//  HMAppStore.h
//  Homage
//
//  Created by Aviv Wolf on 12/16/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <StoreKit/StoreKit.h>

@interface HMAppStore : NSObject<
    SKProductsRequestDelegate
>

-(NSString *)productsPrefix;
-(void)requestInfo;
-(SKProduct *)productForIdentifier:(NSString *)productIdentifier;

@end
