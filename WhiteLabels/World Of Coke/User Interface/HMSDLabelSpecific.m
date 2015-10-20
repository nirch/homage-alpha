//
//  HMSDLabelSpecific.m
//  Homage
//
//  Created by Aviv Wolf on 10/20/15.
//  Copyright (c) 2015 Homage. All rights reserved.
//

#import "HMSDLabelSpecific.h"

@interface HMSDLabelSpecific()

@property (nonatomic) NSArray *bPositions;

@end

@implementation HMSDLabelSpecific

-(void)prepare
{
    self.bPositions = @[
                        @[@(13),@(549)],
                        @[@(-5),@(534)],
                        @[@(25),@(530)],
                        @[@(2),@(520)],
                        @[@(11),@(505)],
                        @[@(17),@(493)]
                        ];
    
    for (NSInteger i=0;i<self.bPositions.count;i++) {
        [self addBubbleWithIndex:i];
    }
}

-(void)addBubbleWithIndex:(NSInteger)i
{
    NSString *imageName = [NSString stringWithFormat:@"bubble%@", @(i+1)];
    UIImage *image = [UIImage imageNamed:imageName];
    
    CGSize size = image.size;
    size = CGSizeMake(size.width / 2.0f, size.height / 2.0f);
    CGPoint position = CGPointMake([self.bPositions[i][0] doubleValue], [self.bPositions[i][1] doubleValue]);
    CGRect frame = CGRectMake(position.x, position.y, size.width, size.height);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.image = image;
    [self.superView addSubview:imageView];
    
    imageView.transform = CGAffineTransformMakeTranslation(0, 40);
    [UIView animateWithDuration:(arc4random()%4000/2000.0f)+3.0f
                          delay:arc4random()%1000/1000.0f
                        options:UIViewAnimationOptionRepeat
                     animations:^{
                         imageView.transform = CGAffineTransformMakeTranslation(0, -40);
                         imageView.alpha = 0;
                     } completion:nil];
}

-(void)tearDown
{
    
}

@end
