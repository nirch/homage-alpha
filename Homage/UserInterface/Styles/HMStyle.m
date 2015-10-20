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

@property (nonatomic) NSMutableDictionary *values;
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
    
    // Load values
    self.values = cfg[@"values"];
    
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
        } else if ([value isKindOfClass:[NSArray class]]) {
            // Add an array of colors with the same name.
            // Can be used with the colorsNamed:colorAtIndex: method.
            // (colorNamed: will return the first color in the array)
            [self addArrayOfColors:value withKey:colorKey];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            // Call it recursively.
            [self addColorsFromDictionary:value];
        }
    }
}

-(void)addColor:(NSString *)colorString withKey:(NSString *)colorKey
{
    UIColor *color = [self color:colorString];
    self.colors[colorKey] = color;
}

-(void)addArrayOfColors:(NSArray *)colorsStrings withKey:(NSString *)colorKey
{
    NSMutableArray *colorsArray = [NSMutableArray new];
    for (NSString *colorString in colorsStrings) {
        [colorsArray addObject:[self color:colorString]];
    }
    self.colors[colorKey] = colorsArray;
}

-(UIColor *)color:(NSString *)colorString
{
    if ([colorString hasPrefix:@"@"]) {
        if (self.colors[colorString] == nil) {
            HMGLogWarning(@"Missing color for color key: %@", colorString);
            return [UIColor whiteColor];
        }
        return self.colors[colorString];
    } else {
        return [colorString colorFromRGBAHexString];
    }
}

//
// Values
//
#pragma mark - style values
-(CGFloat)floatValueForKey:(NSString *)key
{
    id value = self.values[key];
    if (value == nil) return 0;
    CGFloat floatValue = [value floatValue];
    return floatValue;
}

-(NSInteger)integerValueForKey:(NSString *)key
{
    id value = self.values[key];
    if (value == nil) return 0;
    NSInteger integerValue = [value integerValue];
    return integerValue;
}

-(BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue
{
    id value = self.values[key];
    if (value == nil) return defaultValue;
    BOOL boolValue = [value boolValue];
    return boolValue;
}

-(NSDictionary *)styleClassForKey:(NSString *)key
{
    id value = self.values[key];
    return value;
}

#pragma mark - Colors
-(UIColor *)colorNamed:(NSString *)colorName
{
    id color = self.colors[colorName];
    
    // Missing color (will return white)
    if (color == nil) {
        HMGLogError(@"Missing color named: %@", colorName);
        return [UIColor whiteColor];
    }
    
    // Return the color.
    if ([color isKindOfClass:[UIColor class]]) {
        return color;
    }
    
    // Return the first color in a color array.
    if ([color isKindOfClass:[NSArray class]]) {
        return color[0];
    }
    
    // Ha?! This shouldn't have happened.
    HMGLogError(@"Color named:%@ of unsupported type. %@", colorName, [color class]);
    return nil;
}

-(UIColor *)colorNamed:(NSString *)name atIndex:(NSInteger)index
{
    id color = self.colors[name];
    
    // Missing color or not an array of color (will return white)
    if (color == nil || ![color isKindOfClass:[NSArray class]]) {
        HMGLogError(@"Wrong color array named: %@", name);
        return [UIColor whiteColor];
    }
    
    // Color index is cyclical
    index = index % [color count];

    // Return the color by color string.
    color = color[index];
    return color;
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
