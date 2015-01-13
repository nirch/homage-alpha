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
-(UIColor *)colorNamed:(NSString *)name atIndex:(NSInteger)index;

#pragma mark - Fonts

#define K_FONT_REGULAR @"fontRegular"
#define K_FONT_REGULAR_DEFAULT_STROKE_SIZE @"fontRegularDefaultStrokeSize"
#define K_FONT_REGULAR_DEFAULT_STROKE_COLOR @"fontRegularDefaultStrokeColor"

#define K_FONT_BOLD @"fontBold"
#define K_FONT_BOLD_DEFAULT_STROKE_SIZE @"fontBoldDefaultStrokeSize"
#define K_FONT_BOLD_DEFAULT_STROKE_COLOR @"fontBoldDefaultStrokeColor"

#pragma mark - Style classes & attributes
#define S_FONT_RESIZE @"fontResize"

#pragma mark - Values
//
// Values
//
-(CGFloat)floatValueForKey:(NSString *)key;
-(NSInteger)integerValueForKey:(NSString *)key;
-(NSDictionary *)styleClassForKey:(NSString *)key;

// Splash screen
#define V_SPLASH_ACTIVITY_POSITION @"valueSplashActivityPosition"
#define V_SPLASH_ACTIVITY_CIRCLES_COUNT @"valueSplashActivityCirclesCount"
#define V_SPLASH_ACTIVITY_CIRCLES_RADIUS @"valueSplashActivityCirclesRadius"
#define V_STORE_THUMBS_CORNER_RADIUS @"valueStoreThumbsCornerRadius"
#define V_RECORDER_RECORD_BUTTON_OUTLINE @"valueRecorderButtonOutline"

#pragma mark - Colors
//
// Colors
//

// Misc
#define C_REFRESH_CONTROL_TINT @"colorRefreshControlTint"
#define C_ACTIVITY_CONTROL_TINT @"colorActivityControlTint"

// Movie rendering bar
#define C_RENDERING_BAR_BG @"colorRenderingBarBG"
#define C_RENDERING_BAR_TEXT @"colorRenderingBarText"


// Splash screen
#define C_SPLASH_ACTIVITY_INDICATOR @"colorSplashActivityIndicator"
#define C_ARRAY_SPLASH_ACTIVITY_INDICATOR @"colorsArraySplashActivityIndicator"

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

// Navigation and status bar
#define C_STATUS_BAR_BG @"colorStatusBarBG"

#define C_NAV_BAR_TITLE @"colorNavBarTitle"
#define C_NAV_BAR_BACKGROUND @"colorNavBarBackground"
#define C_NAV_BAR_SEPARATOR @"colorNavBarSeparator"

#define C_SIDE_NAV_BAR_TOP_CONTAINER @"colorSideNavBarTopContainer"
#define C_SIDE_NAV_BAR_USER @"colorSideNavBarUser"
#define C_SIDE_NAV_BAR_LOGIN_BUTTON @"colorSideNavBarLoginButton"
#define C_SIDE_NAV_BAR_BG @"colorSideNavBarBG"
#define C_SIDE_NAV_BAR_OPTION_TEXT @"colorSideNavBarOptionText"
#define C_SIDE_NAV_BAR_SEPARATOR @"colorSideNavBarSeparator"

// Stories
#define C_STORIES_TEXT @"colorStoriesText"

// Story details
#define C_SD_DESCRIPTION_TEXT @"colorSDDescriptionText"
#define C_SD_DESCRIPTION_BG @"colorSDDescriptionBG"
#define C_SD_MORE_REMAKES_TITLE_TEXT @"colorSDMoreRemakesTitleText"
#define C_SD_MORE_REMAKES_TITLE_BG @"colorSDMoreRemakesTitleBG"
#define C_SD_REMAKE_BUTTON_BG @"colorSDRemakeButtonBG"
#define C_SD_REMAKE_BUTTON_TEXT @"colorSDRemakeButtonText"
#define C_SD_NO_REMAKES_LABEL @"colorSDNoRemakesLabel"
#define C_SD_REMAKE_INFO_TEXT @"colorSDRemakeInfoText"
#define C_ARRAY_SD_MORE_REMAKES_ACTIVITY_INDICATOR @"colorsArraySDMoreRemakesActivityIndicator"


// Me screen
#define C_ME_TEXT @"colorMeText"
#define C_ME_CREATE_FIRST_VIDEO_TEXT @"colorMeCreateFirstVideoText"
#define C_ME_REMAKE_BUTTON_BG @"colorMeRemakeButtonBG"
#define C_ME_REMAKE_BUTTON_TEXT @"colorMeRemakeButtonText"

// Settings screen
#define C_SETTINGS_BG @"colorSettingsBG"
#define C_SETTINGS_TEXT @"colorSettingsText"
#define C_SETTINGS_SEPARATOR @"colorSettingsSeparator"
#define C_SETTINGS_CONTROLS_TINT @"colorSettingsControlsTint"
#define C_SETTINGS_SECTION_TITLE_BG @"colorSettingsSectionTitleBG"
#define C_SETTINGS_SECTION_TITLE_TEXT @"colorSettingsSectionTitleText"

// Recorder
#define C_RECORDER_TUTORIAL_TEXT @"colorRecorderTutorialText"
#define C_RECORDER_TUTORIAL_BUTTON @"colorRecorderTutorialButton"

#define C_RECORDER_RECORD_BUTTON @"colorRecorderRecordButton"
#define C_RECORDER_RECORD_BUTTON_OUTLINE @"colorRecorderRecordButtonOutline"
#define C_RECORDER_DRAWER_SEP_LINE @"colorRecorderDrawerSepLine"

#define C_RECORDER_IMPACT_BUTTON_BG @"colorRecorderImpactButtonBG"
#define C_RECORDER_IMPACT_BUTTON_TEXT @"colorRecorderImpactButtonText"

#define C_RECORDER_MESSAGE_TITLE @"colorRecorderMessageTitle"
#define C_RECORDER_MESSAGE_TEXT @"colorRecorderMessageText"
#define C_RECORDER_MESSAGE_ACTION_BUTTON @"colorRecorderMessageActionButton"
#define C_RECORDER_MESSAGE_TEXT_BUTTON @"colorRecorderMessageTextButton"

#define C_RECORDER_RECORDING_PROGRESS_BAR @"colorRecorderRecordingProgressBar"

#define C_RECORDER_SCENE_INFO_TITLE @"colorRecorderSceneInfoTitle"
#define C_RECORDER_SCENE_INFO_DATA @"colorRecorderSceneInfoData"

#define C_VIDEO_TITLES @"colorVideoTitles"

// Store
#define C_STORE_PRODUCT_TITLE @"colorStoreProductTitle"
#define C_STORE_PRODUCT_DESCRIPTION @"colorStoreProductDescription"
#define C_STORE_PRODUCT_PRICE @"colorStoreProductPrice"
#define C_STORE_PRODUCT_LINE @"colorStoreProductLine"
#define C_STORE_PRODUCT_BUY_BUTTON_TEXT @"colorStoreProductBuyButtonText"
#define C_STORE_PRODUCT_BUY_BUTTON_BG @"colorStoreProductBuyButtonBG"
#define C_STORE_PRODUCT_BUY_BUTTON_STROKE @"colorStoreProductBuyButtonStroke"

#define C_STORE_PC_NUM_KEY_BG @"colorPCNumKeyBG"
#define C_STORE_PC_NUM_KEY_STROKE @"colorPCNumKeyStroke"
#define C_STORE_PC_NUM_KEY_TEXT @"colorPCNumKeyText"

#define C_STORE_PC_TITLE @"colorPCTitle"
#define C_STORE_PC_TEXT @"colorPCText"
#define C_STORE_PC_INPUT_TEXT @"colorPCInputText"
#define C_STORE_PC_INPUT_BORDER @"colorPCInputBorder"


/**
 *  The regular font name defined in the style.
 *  This font is used on regular text and simple buttons.
 *
 *  @return NSString with the name of the regular font.
 */
-(NSString *)regularFontName;

/**
 *  The default stroke size for the regular font.
 *
 *  @return CGFloat size of the stoke
 */
-(CGFloat)regularFontDefaultStrokeSize;

/**
 *  The default stroke color for the regular font.
 *
 *  @return UIColor color of the regular font.
 */
-(UIColor *)regularFontDefaultStrokeColor;

/**
 *  The bold font name defined in the style.
 *  This font is used in impact buttons and titles of the app.
 *
 *  @return NSString with the name of the bold font.
 */
-(NSString *)boldFontName;

/**
 *  The default stroke size for the bold font.
 *
 *  @return CGFloat size of the stoke
 */
-(CGFloat)boldFontDefaultStrokeSize;

/**
 *  The default stroke color for the bold font.
 *
 *  @return UIColor color of the bold font.
 */
-(UIColor *)boldFontDefaultStrokeColor;

@end
