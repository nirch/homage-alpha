//
//  HMABTester.h
//  Homage
//
//  Created by Aviv Wolf on 12/9/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface HMABTester : NSObject

#define AB_PROJECT_STORE_ICONS @"sidebar store icons"
#define AB_PROJECT_RECORDER_ICONS @"recorder icons"
#define AB_PROJECT_RECORDER_BAD_BACKGROUNDS @"recorder bad background"

/**
 *  Get an ab test variable value by a project name and variable name.
 *
 *  @param projectName              The name of the AB Test project.
 *  @param varName                  The name of the variable.
 *  @param hardCodedDefaultValue    A hard coded value set in code that is returned if AB Test doesn't define the value and the cfg also doesn't provide one.
 *
 *  @return The value string if provided by the AB Test or a default value if defined in AB tests CFG (hard coded value returned otherwise).
 */
-(NSString *)stringValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(id)hardCodedDefaultValue;

/**
 *  Get an ab test variable boolean value by a project name and variable name.
 *  "1" or "true" string value translated to obj-c YES boolean value
 *  "0" or "false" string value translated to obj-c NO boolean value
 *
 *  @param projectName              The name of the AB Test project.
 *  @param varName                  The name of the variable.
 *  @param hardCodedDefaultValue    A hard coded boolean value set in code that is returned if AB Test doesn't define the value and the cfg also doesn't provide one.
 *
 *  @return The bool value if provided by the AB Test or a default value if defined in AB tests CFG (hard coded value returned otherwise).
 */
-(BOOL)boolValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(BOOL)hardCodedDefaultValue;

/**
 *  Get an ab test variable integer value by a project name and variable name.
 *
 *  @param projectName              The name of the AB Test project.
 *  @param varName                  The name of the variable.
 *  @param hardCodedDefaultValue    A hard coded integer value set in code that is returned if AB Test doesn't define the value and the cfg also doesn't provide one.
 *
 *  @return The integer value if provided by the AB Test or a default value if defined in AB tests CFG (hard coded value returned otherwise).
 */
-(NSInteger)integerValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(NSInteger)hardCodedDefaultValue;

/**
 *  Returns a default value related to var name and project.
 *
 *
 *  @param projectName           The name of the project
 *  @param varName               The name of the variable
 *  @param hardCodedDefaultValue A hardcoded default value that is returned in case default value not set in cfg.
 *
 *  @return The default value for this ab test variable.
 */
-(id)defaultValueForProject:(NSString *)projectName varName:(NSString *)varName hardCodedDefaultValue:(id)hardCodedDefaultValue;

/**
 *  Reports an event of given type to the AB Test service.
 *
 *  @param eventType The name/type of the event (NSString)
 */
-(void)reportEventType:(NSString *)eventType;

/**
 *  Returns YES if the AB Testing project returned a variant (which is also not DEFAULT)
 *
 *  @param projectName The name of the project
 *
 *  @return YES or NO, depending if this project is currently with an active AB Test that returned a variant.
 */
-(BOOL)isABTestingProject:(NSString *)projectName;


///**
// *  Posts the view event for the given project name
// *
// *  @param project name
// */
//-(void)trackViewEventForProject:(NSString *)project;

@end
