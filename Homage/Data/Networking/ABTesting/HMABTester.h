//
//  HMABTester.h
//  Homage
//
//  Created by Aviv Wolf on 12/9/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

@interface HMABTester : NSObject

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

@end
