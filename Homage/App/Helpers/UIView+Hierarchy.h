//
//  UIView+Hierarchy.h
//  batuta
//
//  Created by Aviv Wolf on 2/25/14.
//  Copyright (c) 2014 iWolf. All rights reserved.
//

@import UIKit;

@interface UIView (Hierarchy)

// Search views of type in heirarchy
-(UIView *)findAncestorViewThatIsMemberOf:(Class)thisClass;
-(UIView *)findChildViewThatIsMemberOf:(Class)thisClass;

@end
