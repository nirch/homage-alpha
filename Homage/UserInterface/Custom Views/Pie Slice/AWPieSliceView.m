//
//  AWPieSliceView.m
//  Aviv Wolf
//
//  Created by Aviv Wolf on 1/10/12.
//  Copyright (c) 2012 Aviv Wolf. All rights reserved.
//

#import "AWPieSliceView.h"
#import "AWPieSliceLayer.h"

@interface AWPieSliceView()

@property (nonatomic, readonly) CALayer *containerLayer;

@end

@implementation AWPieSliceView

@synthesize value = _value;

#pragma mark - Initializations
-(void)doInitialSetup
{
    _containerLayer = [CALayer layer];
    _value = 1.0;
    self.layer.mask = self.containerLayer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self doInitialSetup];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self doInitialSetup];
    }
    return self;
}

//-(id)initWithSliceValue:(float)value
//{
//    if (self) {
//        [self doInitialSetup];
//        self.value = value;
//    }
//    return self;
//}

#pragma mark - Value change
-(void)setValue:(float)value
{
    _value = value;
    [self updateSlice];
}

-(float)value
{
    return _value;
}

#pragma mark - Slice Value
-(void)updateSlice
{
    self.containerLayer.frame = self.bounds;
    
    // Init sublayers if needed
    if (self.containerLayer.sublayers==0) {
        AWPieSliceLayer *slice = [AWPieSliceLayer layer];
        slice.frame = self.bounds;
        [self.containerLayer addSublayer:slice];
    }
    
    // Set the angles on the slice
    AWPieSliceLayer *slice = self.containerLayer.sublayers[0];
    slice.startAngle = 0;
    slice.endAngle = self.value * 2 * M_PI;
}

@end
