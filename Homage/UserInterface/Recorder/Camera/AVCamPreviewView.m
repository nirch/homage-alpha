@import AVFoundation;
#import "AVCamPreviewView.h"

@implementation AVCamPreviewView

+(Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

-(AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

-(void)setSession:(AVCaptureSession *)session
{
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

@end
