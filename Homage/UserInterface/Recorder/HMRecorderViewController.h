//
//  HMRecorderViewController.h
//  Homage
//
//  Created by Aviv Wolf on 1/12/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@class Remake;

#import "HMRemakerProtocol.h"
#import "HMRecorderDelegate.h"

@interface HMRecorderViewController : UIViewController<
    HMRemakerProtocol
>

///
/**
*  A delegate implementing the HMRecorderDelegate protocol.
*/
@property (nonatomic, weak) id<HMRecorderDelegate> delegate;

/** Creates a new recorder view controller for the related remake.

 Example usage:
 @code
    // Important : Make sure remake object is available first or nil will be returned.
    Remake *remake = [Remake findWithID:@"52e116d2db25451700000003" inContext:DB.sh.context];
    if (remake) {
        HMRecorderViewController *vc = [HMRecorderViewController recorderForRemake:remake];
        vc.delegate = self; // optional
        [self presentViewController:vc animated:YES completion:nil];
    }
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
