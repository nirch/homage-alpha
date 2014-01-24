//
//  HMRecorderDelegate.h
//  Homage
//
//  Created by Aviv Wolf on 1/23/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

typedef NS_ENUM(NSInteger, HMRecorderDismissReason) {
    HMRecorderDismissReasonUserAbortedPressingX,
    HMRecorderDismissReasonFinishedRemake
};

@class HMRecorderViewController;

@protocol HMRecorderDelegate <NSObject>

///
/**
*  Tells the recorder delegate that the recorder want to be dismissed.
*
*  @code

*  @endcode
*  @param reason The reason why the recorder is about to be closed.
*  @param remakeID The id of the remake the recorder edited.
*/
-(void)recorderAsksDismissalWithReaon:(HMRecorderDismissReason)reason
                             remakeID:(NSString *)remakeID
                               sender:(HMRecorderViewController *)sender;

@end
