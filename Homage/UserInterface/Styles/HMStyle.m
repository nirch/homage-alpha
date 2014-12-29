//
//  HMColor.m
//  Homage
//
//  Created by Aviv Wolf on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMStyle.h"
#import "NSString+Utilities.h"

@interface HMStyle()

@property (nonatomic) NSMutableDictionary *colors;
@property (nonatomic) NSMutableDictionary *fonts;

@end

@implementation HMStyle

// A singleton
+(HMStyle *)sharedInstance
{
    static HMStyle *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMStyle alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMStyle *)sh
{
    return [HMStyle sharedInstance];
}

-(id)init
{
    self = [super init];
    if (self) {
        [self loadCFG];
    }
    return self;
}

-(void)loadCFG
{
    //
    // Loads colors info from the Style.plist file.
    //
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"Style" ofType:@"plist"];
    NSDictionary *cfg = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    
    // Load the palette colors
    self.colors = [NSMutableDictionary new];
    NSDictionary *palette = cfg[@"palette"];
    for (NSString *colorKey in palette) {
        NSString *value = palette[colorKey];
        self.colors[colorKey] = [value colorFromRGBAHexString];
    }

    // Load all other colors.
    // Color values with the @ prefix, use the palette.
    // Colors may reside in category dictionaries. We will flat it out.
    NSDictionary *colorsDictionary = cfg[@"colors"];
    [self addColorsFromDictionary:colorsDictionary];
    
    // Load fonts names
    self.fonts = cfg[@"fonts"];
}

-(void)addColorsFromDictionary:(NSDictionary *)colorsDictionary
{
    for (NSString *colorKey in colorsDictionary) {
        id value = colorsDictionary[colorKey];
        if (value == nil) {
            HMGLogWarning(@"Missing color value for color key: %@", colorKey);
            continue;
        }
        HMGLogDebug(@"Adding colors: %@ %@", colorKey, value);
        if ([value isKindOfClass:[NSString class]]) {
            // Add a single color.
            [self addColor:value withKey:colorKey];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            // Call it recursively.
            [self addColorsFromDictionary:value];
        }
    }
}

-(void)addColor:(NSString *)colorString withKey:(NSString *)colorKey
{
    if ([colorString hasPrefix:@"@"]) {
        if (self.colors[colorString] == nil) {
            HMGLogWarning(@"Missing color for color key: %@", colorString);
            return;
        }
        self.colors[colorKey] = self.colors[colorString];
    } else {
        self.colors[colorKey] = [colorString colorFromRGBAHexString];
    }
}

//#pragma mark - Colors: General
//-(UIColor *)main1                  {return [self colorNamed:@"main1"];}
//-(UIColor *)main2                  {return [self colorNamed:@"main2"];}
//-(UIColor *)text                   {return [self colorNamed:@"text"];}
//-(UIColor *)textPlaceholder        {return [self colorNamed:@"textPlaceholder"];}
//-(UIColor *)textImpact             {return [self colorNamed:@"textImpact"];}
//-(UIColor *)greyLine               {return [self colorNamed:@"greyLine"];}
//
//#pragma mark - Colors: Recorder specific
//-(UIColor *)recorderTableCellBackground                         {return [self colorNamed:@"recorderTableCellBackground"];}
//-(UIColor *)recorderTableCellBackgroundHighlighted              {return [self colorNamed:@"recorderTableCellBackgroundHighlighted"];}
//-(UIColor *)recorderEditTextPlaceHolder                         {return [self colorNamed:@"recorderEditTextPlaceHolder"];}
//-(UIColor *)recorderEditText                                    {return [self colorNamed:@"recorderEditText"];}
//-(UIColor *)recorderEditTextError                               {return [self colorNamed:@"recorderEditTextError"];}

#pragma mark - Colors
-(UIColor *)colorNamed:(NSString *)colorName
{
    UIColor *color = self.colors[colorName];
    if (color) return color;
    HMGLogError(@"Missing color named: %@", colorName);
    return [UIColor whiteColor];
}

#pragma mark - Fonts
-(NSString *)regularFontName
{
    return self.fonts[K_FONT_REGULAR];
}

-(CGFloat)regularFontDefaultStrokeSize
{
    NSNumber *strokeSize = self.fonts[K_FONT_REGULAR_DEFAULT_STROKE_SIZE];
    if (!strokeSize) return 0;
    return strokeSize.floatValue;
}

-(UIColor *)regularFontDefaultStrokeColor
{
    NSString *strokeColorName = self.fonts[K_FONT_REGULAR_DEFAULT_STROKE_COLOR];
    if (!strokeColorName) return [UIColor clearColor];
    UIColor *color = [self colorNamed:strokeColorName];
    if (!color) return [UIColor clearColor];
    return color;
}

-(NSString *)boldFontName
{
    return self.fonts[K_FONT_BOLD];
}

-(CGFloat)boldFontDefaultStrokeSize
{
    NSNumber *strokeSize = self.fonts[K_FONT_BOLD_DEFAULT_STROKE_SIZE];
    if (!strokeSize) return 0;
    return strokeSize.floatValue;
}

-(UIColor *)boldFontDefaultStrokeColor
{
    NSString *strokeColorName = self.fonts[K_FONT_BOLD_DEFAULT_STROKE_COLOR];
    if (!strokeColorName) return [UIColor clearColor];
    UIColor *color = [self colorNamed:strokeColorName];
    if (!color) return [UIColor clearColor];
    return color;
}

@end
