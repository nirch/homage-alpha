//
//  HMMotionDetector.m
//  Homage
//
//  Created by Yoav Caspin on 2/20/14.
//  Copyright (c) 2014 Homage. All rights reserved.
//

#import "HMMotionDetector.h"
#import "HMMotionDetectorDelegate.h"
@import CoreMotion;


@interface HMMotionDetector () <HMMotionDetectorDelegate>

@property double prevAttitudeRoll;
@property double prevAttitudePitch;
@property double prevAttitudeYaw;
@property double prevRotationRateX;
@property double prevRotationRateY;
@property double prevRotationRateZ;
@property double prevAccelerationX;
@property double prevAccelerationY;
@property double prevAccelerationZ;
@property BOOL calculateStability;

@end

@implementation HMMotionDetector

#define MOTION_TH 0.05
#define ROTATION_TH 0.05
#define ACCELRATION_TH 0.05


+(HMMotionDetector *)sharedInstance
{
    static HMMotionDetector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HMMotionDetector alloc] init];
    });
    
    return sharedInstance;
}

+(CMMotionManager *)motionManager
{
    static CMMotionManager *motionManager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        motionManager = [[CMMotionManager alloc] init];
    });
    
    return motionManager;
}

+(HMMotionDetector *)sh
{
    return [HMMotionDetector sharedInstance];
}


-(void)start
{
    NSTimeInterval updateInterval = 0.1;
    self.calculateStability = NO;
    
    CMMotionManager *mManager = [HMMotionDetector motionManager];
    if ([mManager isDeviceMotionAvailable] == YES)
    {
        [mManager setDeviceMotionUpdateInterval:updateInterval];
        [mManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMDeviceMotion *deviceMotion , NSError *error) {
            
            if (!self.calculateStability)
            {
                self.prevAttitudeRoll  = deviceMotion.attitude.roll;
                self.prevAttitudePitch = deviceMotion.attitude.pitch;
                self.prevAttitudeYaw   = deviceMotion.attitude.yaw;
                self.prevRotationRateX = deviceMotion.rotationRate.x;
                self.prevRotationRateY = deviceMotion.rotationRate.y;
                self.prevRotationRateZ = deviceMotion.rotationRate.z;
                self.prevAccelerationX = deviceMotion.userAcceleration.x;
                self.prevAccelerationY = deviceMotion.userAcceleration.y;
                self.prevAccelerationZ = deviceMotion.userAcceleration.z;
                self.calculateStability = YES;
            } else if (![self isCameraStable:deviceMotion withAttitude:YES withRotationRate:NO withAcceleration:NO])
            {
                [self.delegate onCameraNotStable];
                self.calculateStability = NO;
                
            }
         }];
    }
}

-(BOOL)isCameraStable:(CMDeviceMotion *)deviceMotion withAttitude:(BOOL)attitude withRotationRate:(BOOL)rotation withAcceleration:(BOOL)accleration
{
    BOOL cameraStable = YES;

        if (attitude && ![self isAttitudeStableForRoll:deviceMotion.attitude.roll pitch:deviceMotion.attitude.pitch yaw:deviceMotion.attitude.yaw]) cameraStable=NO;
        if (rotation && ![self isCameraStableInRotationForX:deviceMotion.rotationRate.x Y:deviceMotion.rotationRate.y Z:deviceMotion.rotationRate.z]) cameraStable = NO;
        if (accleration && ![self isCameraStableInAccelerationForX:deviceMotion.userAcceleration.x Y:deviceMotion.userAcceleration.y Z:deviceMotion.userAcceleration.z]) cameraStable = NO;
    return cameraStable;
}

-(BOOL)isAttitudeStableForRoll:(double)roll pitch:(double)pitch yaw:(double)yaw
{
        double rollDelta = abs(roll - self.prevAttitudeRoll);
        double pitchDelta = abs(pitch - self.prevAttitudePitch);
        double yawDelta = abs(yaw - self.prevAttitudeYaw);
        if ((rollDelta > MOTION_TH) || (pitchDelta > MOTION_TH) || (yawDelta > MOTION_TH)) return NO;
    return YES;
}

-(BOOL)isCameraStableInRotationForX:(double)x Y:(double)y Z:(double)z
{
        double deltaX = abs(x - self.prevRotationRateX);
        double deltaY = abs(y - self.prevRotationRateY);
        double deltaZ = abs(z - self.prevRotationRateZ);
        if ((deltaX > ROTATION_TH) || (deltaY > ROTATION_TH) || (deltaZ > ROTATION_TH)) return NO;
    return YES;
}

-(BOOL)isCameraStableInAccelerationForX:(double)x Y:(double)y Z:(double)z
{
        double deltaX = abs(x - self.prevAccelerationX);
        double deltaY = abs(y - self.prevAccelerationY);
        double deltaZ = abs(z - self.prevAccelerationZ);
        if ((deltaX > ACCELRATION_TH) || (deltaY > ACCELRATION_TH) || (deltaZ > ACCELRATION_TH)) return NO;
    return YES;
}

-(void)stop
{
    CMMotionManager *mManager = [HMMotionDetector motionManager];
    if ([mManager isDeviceMotionActive] == YES) [mManager stopDeviceMotionUpdates];
}

@end
