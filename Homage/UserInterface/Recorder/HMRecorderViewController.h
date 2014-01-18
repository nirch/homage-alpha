//
//  HMRecorderViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Remake;

#import "HMRemakerProtocol.h"

@interface HMRecorderViewController : UIViewController<
    HMRemakerProtocol
>
/** Creates a new recorder view controller for the related remake.

 Example usage:
 @code
    // Important : Make sure remake object is available first!
    UIViewController *vc = [HMRecorderViewController recorderForRemake:remake];
    if (vc) [self presentViewController:vc animated:YES completion:nil];
 @endcode
 
 @param remake
    The remake we want to make/edit using the recorder. 
    This remake must already exist on the server side and info about it must exist in local storage.
 
 @return 
    If remake info found, will return HMRecorderViewController.
    Returns nil otherwise.
 
 */
+(HMRecorderViewController *)recorderForRemake:(Remake *)remake;


@end
