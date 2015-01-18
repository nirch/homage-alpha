//
//  HMStoreProductsViewController.h
//  Homage
//
//  Created by Aviv Wolf on 12/15/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Story;
@class Remake;

@interface HMStoreProductsViewController : UIViewController<
    UICollectionViewDataSource,
    UICollectionViewDelegate
>

@property (nonatomic) Story *prioritizedStory;
@property (nonatomic) Remake *remake;

-(void)restorePurchases;
-(void)cleanUp;

@end
