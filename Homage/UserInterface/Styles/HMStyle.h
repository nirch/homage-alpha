//
//  HMStyle.h
//  Homage
//
//  Created by Aviv Wolf on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface HMStyle : NSObject

+(HMStyle *)sharedInstance;
+(HMStyle *)sh;

#pragma mark - Colors
/**
 *  A color defined and named in style sheet.
 *
 *  @param name The name of the color.
 *
 *  @return UIColor defined in style sheet.
 */
-(UIColor *)colorNamed:(NSString *)name;

#pragma mark - Fonts

#define K_FONT_REGULAR @"fontRegular"
#define K_FONT_REGULAR_DEFAULT_STROKE_SIZE @"fontRegularDefaultStrokeSize"
#define K_FONT_REGULAR_DEFAULT_STROKE_COLOR @"fontRegularDefaultStrokeColor"

#define K_FONT_BOLD @"fontBold"
#define K_FONT_BOLD_DEFAULT_STROKE_SIZE @"fontBoldDefaultStrokeSize"
#define K_FONT_BOLD_DEFAULT_STROKE_COLOR @"fontBoldDefaultStrokeColor"

// Splash screen
#define C_SPLASH_ACTIVITY_INDICATOR @"colorSplashActivityIndicator"

// Login screen
#define C_LOGIN_BACKGROUND @"colorLoginBackground"
#define C_LOGIN_TEXT @"colorLoginText"
#define C_LOGIN_SUBTLE_BUTTON_TEXT @"colorLoginSubtleButtonText"
#define C_LOGIN_INPUT_PLACE_HOLDER_TEXT @"colorLoginInputPlaceHolderText"
#define C_LOGIN_INPUT_TEXT @"colorLoginInputText"
#define C_LOGIN_ACTIVITY_INDICATOR @"colorLoginActivityIndicator"
#define C_LOGIN_ERROR_MESSAGES @"colorLoginErrorMessages"
#define C_LOGIN_IMPACT_BUTTON_BG @"colorLoginImpactButtonBG"
#define C_LOGIN_IMPACT_BUTTON_TEXT @"colorLoginImpactButtonText"
#define C_LOGIN_FADED_TEXT @"colorLoginFadedText"
#define C_LOGIN_FADED_LINKS @"colorLoginFadedLinks"
#define C_LOGIN_FADED_TEXT @"colorLoginFadedText"
#define C_LOGIN_FADED_LINKS @"colorLoginFadedLinks"

// Navigation
#define C_NAV_BAR_TITLE @"colorNavBarTitle"
#define C_NAV_BAR_BACKGROUND @"colorNavBarBackground"
#define C_NAV_BAR_SEPARATOR @"colorNavBarSeparator"

#define C_SIDE_NAV_BAR_TOP_CONTAINER @"colorSideNavBarTopContainer"
#define C_SIDE_NAV_BAR_USER @"colorSideNavBarUser"
#define C_SIDE_NAV_BAR_LOGIN_BUTTON @"colorSideNavBarLoginButton"
#define C_SIDE_NAV_BAR_BG @"colorSideNavBarBG"
#define C_SIDE_NAV_BAR_OPTION_TEXT @"colorSideNavBarOptionText"
#define C_SIDE_NAV_BAR_SEPARATOR @"colorSideNavBarSeparator"

// Story details
#define C_SD_TEXT @"colorSDText"
#define C_SD_MORE_REMAKES_TITLE @"colorSDMoreRemakesTitle"
#define C_SD_REMAKE_BUTTON_BG @"colorSDRemakeButtonBG"
#define C_SD_REMAKE_BUTTON_TEXT @"colorSDRemakeButtonText"

// Settings screen
#define C_SETTINGS_BG @"colorSettingsBG"
#define C_SETTINGS_TEXT @"colorSettingsText"
#define C_SETTINGS_SEPARATOR @"colorSettingsSeparator"
#define C_SETTINGS_CONTROLS_TINT @"colorSettingsControlsTint"
#define C_SETTINGS_SECTION_TITLE_BG @"colorSettingsSectionTitleBG"
#define C_SETTINGS_SECTION_TITLE_TEXT @"colorSettingsSectionTitleText"

// Recorder
#define C_RECORDER_RECORD_BUTTON @"colorRecorderRecordButton"
#define C_RECORDER_RECORD_BUTTON_OUTLINE @"colorRecorderRecordButtonOutline"
#define C_RECORDER_IMPACT_BUTTON_BG @"colorRecorderImpactButtonBG"
#define C_RECORDER_IMPACT_BUTTON_TEXT @"colorRecorderImpactButtonText"
#define C_RECORDER_TEXT_BUTTON @"colorRecorderTextButton"
#define C_RECORDER_TEXT @"colorRecorderText"
#define C_RECORDER_MESSAGE_TITLE @"colorRecorderMessageTitle"
#define C_RECORDER_MESSAGE_TEXT @"colorRecorderMessageText"
#define C_RECORDER_IMPACT_TEXT @"colorRecorderImpactText"
#define C_RECORDER_RECORDING_PROGRESS_BAR @"colorRecorderRecordingProgressBar"

/**
 *  The regular font name defined in the style.
 *  This font is used on regular text and simple buttons.
 *
 *  @return NSString with the name of the regular font.
 */
-(NSString *)regularFontName;

//
-(CGFloat)regularFontDefaultStrokeSize;

//
-(UIColor *)regularFontDefaultStrokeColor;

/**
 *  The bold font name defined in the style.
 *  This font is used in impact buttons and titles of the app.
 *
 *  @return NSString with the name of the bold font.
 */
-(NSString *)boldFontName;

//
-(CGFloat)boldFontDefaultStrokeSize;

//
-(UIColor *)boldFontDefaultStrokeColor;

@end
