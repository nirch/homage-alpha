//
//  HMColor.m
//  Homage
//
//  Created by Aviv Wolf on 1/22/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMColor.h"
#import "NSString+Utilities.h"

@interface HMColor()

@property (nonatomic, readonly) NSMutableDictionary *cfgColors;

@end

@implementation HMColor

// A singleton
+(HMColor *)sharedInstance
{
    static HMColor *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMColor alloc] init];
    });
    
    return sharedInstance;
}

// Just an alias for sharedInstance for shorter writing.
+(HMColor *)sh
{
    return [HMColor sharedInstance];
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
    // Loads colors info from the Colors.plist file.
    //
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"Colors" ofType:@"plist"];
    _cfgColors = [NSMutableDictionary new];
    NSDictionary *colorsInFile = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    for (NSString *colorKey in colorsInFile) {
        NSString *colorHexRepresentation = colorsInFile[colorKey];
        if (!colorHexRepresentation) continue;
        self.cfgColors[colorKey] = [colorHexRepresentation colorFromRGBAHexString];
    }
}

#pragma mark - Colors: General
-(UIColor *)main1                  {return [self colorNamed:@"main1"];}
-(UIColor *)main2                  {return [self colorNamed:@"main2"];}
-(UIColor *)text                   {return [self colorNamed:@"text"];}
-(UIColor *)textImpact             {return [self colorNamed:@"textImpact"];}
-(UIColor *)greyLine               {return [self colorNamed:@"greyLine"];}

#pragma mark - Colors: Recorder specific
-(UIColor *)recorderTableCellBackground                         {return [self colorNamed:@"recorderTableCellBackground"];}
-(UIColor *)recorderTableCellBackgroundHighlighted              {return [self colorNamed:@"recorderTableCellBackgroundHighlighted"];}
-(UIColor *)recorderEditTextPlaceHolder                         {return [self colorNamed:@"recorderEditTextPlaceHolder"];}
-(UIColor *)recorderEditText                                    {return [self colorNamed:@"recorderEditText"];}
-(UIColor *)recorderEditTextError                               {return [self colorNamed:@"recorderEditTextError"];}

#pragma mark - utilities
-(UIColor *)colorNamed:(NSString *)colorName
{
    UIColor *color = self.cfgColors[colorName];
    if (color) return color;
    HMGLogWarning(@"Missing color named in Colors.plist file: %@", colorName);
    return [UIColor whiteColor];
}


@end
