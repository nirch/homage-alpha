//
//  HMColor.h
//  Homage
//
//  Created by Aviv Wolf on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface HMColor : NSObject

+(HMColor *)sharedInstance;
+(HMColor *)sh;

#pragma mark - Colors: General
/** The most common color of the app. 1 */
-(UIColor *)main1;

/** The most common color of the app. 2 */
-(UIColor *)main2;

/** The most common/regular color for text. */
-(UIColor *)text;

/** Text color with an impact. Use in titles, on text selection or on important buttons */
-(UIColor *)textImpact;

#pragma mark - Colors: Recorder specific
/** Background color of a cell in a table view in the recorder screens */
-(UIColor *)recorderTableCellBackground;

/** Background color of a highlighted cell in a table view in the recorder screens */
-(UIColor *)recorderTableCellBackgroundHighlighted;

/** The color of placeholder texts when editing remake texts in the recorder */
-(UIColor *)recorderEditTextPlaceHolder;

/** The color of texts when editing remake texts in the recorder */
-(UIColor *)recorderEditText;

/** The color of texts getting error from server when editing remake texts in the recorder */
-(UIColor *)recorderEditTextError;

@end
