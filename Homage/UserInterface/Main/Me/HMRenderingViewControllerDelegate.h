//
//  HMRenderingViewControllerDelegate.h
//  Homage
//
//  Created by Tomer Harry on 1/27/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HMRenderingViewControllerDelegate <NSObject>

- (void)renderDoneClickedWithSuccess:(BOOL)success;

@end
