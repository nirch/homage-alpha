//
//  HMConfigurationParser.m
//  Homage
//
//  Created by Yoav Caspin on 10/14/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMConfigurationParser.h"

@implementation HMConfigurationParser

-(void)parse
{
    NSDictionary *info = self.objectToParse;
    self.parseInfo[@"share_link_prefix"] = info[@"share_link_prefix"];
}
  

@end
