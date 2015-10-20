//
//  HMABTester.m
//  Homage
//
//  Created by Aviv Wolf on 12/9/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMABTester.h"
#import <AmazonInsightsSDK/AmazonInsightsSDK.h>
#import "HMNotificationCenter.h"
#import "NSString+Utilities.h"

// Amazon insights
#define K_CFG_PRIVATE_KEY @"private_key"
#define K_CFG_PUBLIC_KEY @"public_key"
#define K_CFG_PROJECTS @"projects"

@interface HMABTester()

@property (nonatomic) NSDictionary *cfg;
@property (nonatomic) NSString *amazonInsightsPublicKey;
@property (nonatomic) NSString *amazonInsightsPrivateKey;

@property (nonatomic) AIAmazonInsights *insights;
@property (nonatomic) id<AIABTestClient> abClient;
@property id<AIEventClient>eventClient;
@property (nonatomic) NSMutableDictionary *variationsByProjectName;

@end

@implementation HMABTester

-(id)init
{
    self = [super init];
    if (self) {
        [self initializeABTestingClient];
    }
    return self;
}

-(void)initializeABTestingClient
{
    self.variationsByProjectName = [NSMutableDictionary new];
    
    // Read AB testing configuration.
    NSString * plistPath = [[NSBundle mainBundle] pathForResource:@"ABTestsCFG" ofType:@"plist"];
    if (plistPath == nil) return;
    self.cfg = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    self.amazonInsightsPrivateKey = self.cfg[K_CFG_PRIVATE_KEY];
    self.amazonInsightsPublicKey = self.cfg[K_CFG_PUBLIC_KEY];
    
    // Initialize AB testing
    // Create a credentials object using the key values
    // you generated in the A/B Testing console.
    id<AIInsightsCredentials> credentials = [AIAmazonInsights credentialsWithApplicationKey:self.amazonInsightsPublicKey
                                                                             withPrivateKey:self.amazonInsightsPrivateKey];
    
    
    // Create an options object to enable event collection and WAN delivery.
    id<AIInsightsOptions>options = [AIAmazonInsights optionsWithAllowEventCollection:YES withAllowWANDelivery:YES];
    
    // Initialize a new instance of AmazonInsights specifically for your application.
    self.insights = [AIAmazonInsights insightsWithCredentials:credentials withOptions:options];
    [AIAmazonInsights insightsWithCredentials:credentials
                                  withOptions:options];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.abClient = self.insights.abTestClient;
        self.eventClient = self.insights.eventClient;
        [self initializeVariants];
    });
}



-(void)initializeVariants
{
    // Iterate all projects defined in cfg, and store variants info.
    NSDictionary *projects = self.cfg[K_CFG_PROJECTS];
    NSArray *projectsNames = projects.allKeys;
    HMGLogDebug(@"AB Testing projects:%@", projectsNames);
    [self.abClient variationsByProjectNames:projectsNames
                          withCompletionHandler:^(id<AIVariationSet>variationSet, NSError* error) {
                              if (error) {
                                  // Error. AB Testing will be skipped for this variation set. Defaults will be used.
                                  HMGLogError(@"ABTesting initialization failed. %@", [error localizedDescription]);
                                  return;
                              }

                              for (NSString *projectName in projectsNames) {
                                  id<AIVariation>vars = [variationSet variationForProjectName:projectName];
                                  self.variationsByProjectName[projectName] = vars;
                                  HMGLogDebug(@"AB Testing Project:%@" , projectName);
                                  HMGLogDebug(@"Variations:%@" , vars);
                              }
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  [self postGotVariations];
                              });
                          }];
    
// Just for debuggin
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [self postGotVariations];
//    });
}

-(void)postGotVariations
{
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_AB_TESTING_VARIATIONS_UPDATED object:self userInfo:nil];
}

// Returns a variant
-(NSString *)stringValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(id)hardCodedDefaultValue;
{
    id defaultValue = [self defaultValueForProject:projectName varName:varName hardCodedDefaultValue:hardCodedDefaultValue];
    id<AIVariation>vars = self.variationsByProjectName[projectName];
    if (!vars) return defaultValue;

    // Get the value.
    NSString *stringValue = [vars variableAsString:varName withDefault:defaultValue];
    return stringValue;
}

-(BOOL)boolValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(BOOL)hardCodedDefaultValue
{
    NSString *sVal = [self stringValueForProject:projectName
                                         varName:varName
                           hardCodedDefaultValue:hardCodedDefaultValue ? @"1" : @"0"];
    
    sVal = [sVal stringWithATrim];
    
    // Return YES if equals to "1" or "true" string.
    if ([sVal isEqualToString:@"1"] || [sVal isEqualToString:@"true"]) {
        return YES;
    }
    
    // In all other cases, return no.
    return NO;
}

-(NSInteger)integerValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(NSInteger)hardCodedDefaultValue
{
    NSString *sVal = [self stringValueForProject:projectName
                                         varName:varName
                           hardCodedDefaultValue:[NSString stringWithFormat:@"%ld", (long)hardCodedDefaultValue]];
    sVal = [sVal stringWithATrim];
    return [sVal integerValue];
}


-(BOOL)isABTestingProject:(NSString *)projectName
{
    id<AIVariation>vars = self.variationsByProjectName[projectName];
    if (!vars) return NO;
    if ([vars.name isEqualToString:@"DEFAULT"]) return NO;
    return YES;
}

-(id)defaultValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(id)hardCodedDefaultValue
{
    // Will take default value from CFG, if set in cfg.
    // If no default provided in cfg, will return the
    
    // Get project info that contains defaults
    NSDictionary *projectInfo = self.cfg[K_CFG_PROJECTS][projectName];
    if (!projectInfo) return hardCodedDefaultValue;
    
    // Get the defaults
    NSDictionary *defaults = projectInfo[@"defaults"];
    if (!defaults) return hardCodedDefaultValue;
    
    // Get the default value
    id defaultValue = defaults[varName];
    if (defaultValue) return defaultValue;
    
    // If not set in cfg, use the hard coded default value (if provided).
    return hardCodedDefaultValue;
}

-(void)reportEventType:(NSString *)eventType
{
    // Create an event.
    id<AIEvent>event = [self.eventClient createEventWithEventType:eventType];
    [self.eventClient recordEvent:event];
    [self.eventClient submitEvents];
}

@end
