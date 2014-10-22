//
//  UIView+Hierarchy.m
//  batuta
//
//  Created by Aviv Wolf on 2/25/14.
//  Copyright (c) 2014 iWolf. All rights reserved.
//

#import "UIView+Hierarchy.h"

@implementation UIView (Hierarchy)

// Go up the heirarchy until reaching a view that is
// a member of the given class. Returns nil if not found.
-(UIView *)findAncestorViewThatIsMemberOf:(Class)thisClass
{
    UIView *v = self.superview;
    while (v) {
        if ([v isKindOfClass:thisClass]) break;
        v = v.superview;
    }
    return v;
}

// Check all the children of this view. Returns the first child that is a member
// of the given class. Returns nil if not found.
-(UIView *)findChildViewThatIsMemberOf:(Class)thisClass
{
    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:thisClass]) return v;
    }
    return nil;
}

@end
