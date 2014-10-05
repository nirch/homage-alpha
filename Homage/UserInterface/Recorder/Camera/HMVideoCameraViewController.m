//
//  HMVideoCameraViewController.m
//  Homage
//
//  Modification of the AVCam example by apple.
//

@import AVFoundation;
@import AssetsLibrary;

#import "HMVideoCameraViewController.h"
#import "AVCamPreviewView.h"
#import "HMNotificationCenter.h"
#import "InfoKeys.h"
#import "HMExtractController.h"
#import "Mixpanel.h"
#import "DB.h"


// Contexts
static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface HMVideoCameraViewController () <
    AVCaptureFileOutputRecordingDelegate
>

// For use in the storyboards.
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;
@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (nonatomic) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic) AVCaptureVideoDataOutput *movieDataOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;
@property (nonatomic) CGPoint focusPoint;

// Extraction
@property (nonatomic, readonly) HMExtractController *extractController;

// Some info about beginning and end of a recording
@property (nonatomic) NSDictionary *lastRecordingStartInfo;
@property (nonatomic) NSDictionary *lastRecordingStopInfo;

// Camera settings
@property (nonatomic, readonly) BOOL camFGExtraction;
@property (nonatomic, readonly) NSString *camSettingsSessionPreset;
@property (nonatomic, readonly) NSString *camSettingsSessionPresetFrontCameraFallback;
@property (nonatomic, readonly) NSInteger camSettingsPrefferedDevicePosition;
@property (nonatomic, readonly) NSString *camSettingsPreviewLayerVideoGravity;
@property (nonatomic, readonly) NSInteger camSettingsMinFramesPerSecond;
@property (nonatomic, readonly) NSInteger camSettingsMaxFramesPerSecond;


@end

@implementation HMVideoCameraViewController

#pragma mark - Camera settings
-(void)initCameraSettings
{
    // Extraction
    _camFGExtraction                                = YES;
    
    // Camera
    _camSettingsSessionPreset                       = AVCaptureSessionPreset1280x720;     // Video capture resolution
    _camSettingsSessionPresetFrontCameraFallback    = AVCaptureSessionPreset640x480;            // If front camera can't show 720p, will try 480p.
    _camSettingsPrefferedDevicePosition             = AVCaptureDevicePositionBack;              // Preffered camera position
    _camSettingsMinFramesPerSecond                  = 25;                                       // Min fps. Set to 0, if you want to use device defaults instead.
    _camSettingsMaxFramesPerSecond                  = 25;                                       // Max fps. Set to 0, if you want to use device defaults instead.
    
    // Preview layer
    _camSettingsPreviewLayerVideoGravity            = AVLayerVideoGravityResizeAspectFill;      // Video gravity on the preview layer
}

#pragma mark - View controller life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    //
    // initialize the camera
    //
    [self initCameraSettings];
    [self initCamera];

    //
    // Reveal the preview slowly for a nicer effect.
    //
    [self slowReveal];
}


//
// When the view will appear, add observers for recording states and set a runtime error handler (restarts on errors).
//
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initAVObservers];
    [self initAppObservers];
    [self refreshCameraFeedWithFlip:NO];
}

//
// Fix orientation on view did appear
//
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateOrientation:(UIInterfaceOrientation)[UIDevice currentDevice].orientation];
}

//
// When view did disappear, stop the session and remove the observers.
//
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self removeAVObservers];
    [self removeAppObservers];
}

#pragma mark - Silly effects
-(void)slowReveal
{
    self.view.alpha = 0;
    double delayInSeconds = 0.7;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self revealCameraPreviewAnimated:YES];
    });
}

#pragma mark - Observers
-(void)initAVObservers
{
    // "Thank you for hiding the Beacon. I can't touch it myself. I know you have questions. Soon you will have answers."
    // - The observer. Fringe.
    
    dispatch_async([self sessionQueue], ^{
        
        //
        // Add 1: Session running and device authorized observer
        //
        [self addObserver:self forKeyPath:@"sessionRunningAndDeviceAuthorized"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:SessionRunningAndDeviceAuthorizedContext
         ];

        //
        // Add 2: Movie file output recording observer
        //
        [self addObserver:self forKeyPath:@"movieFileOutput.recording"
                  options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                  context:RecordingContext];
        
        //
        // Add 3: subject are change observer
        //
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(subjectAreaDidChange:)
                                                     name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                   object:self.videoDeviceInput.device
         ];
        
        //
        // Add 4: Runtime error handling observer
        //
        __weak HMVideoCameraViewController *weakSelf = self;
        id observer = [[NSNotificationCenter defaultCenter] addObserverForName:AVCaptureSessionRuntimeErrorNotification
                                                                        object:self.session
                                                                         queue:nil
                                                                    usingBlock:^(NSNotification *note) {
                                                                        
                                                                        HMVideoCameraViewController *strongSelf = weakSelf;
                                                                        dispatch_async(strongSelf.sessionQueue, ^{
                                                                            // Manually restarting the session since it must have been stopped due to an error.
                                                                            [strongSelf.session startRunning];
                                                                        });
                                                                    }];
        self.runtimeErrorHandlingObserver = observer;
        
        //
        // Starting the session
        //
        [self.session startRunning];
    });
}

-(void)removeAVObservers
{
    dispatch_async([self sessionQueue], ^{
        // Stop the session
        [self.session stopRunning];
        
        //
        // Remove 1 : Session running and device authorized observer
        //
        [self removeObserver:self
                  forKeyPath:@"sessionRunningAndDeviceAuthorized"
                     context:SessionRunningAndDeviceAuthorizedContext
         ];
        
        //
        // Remove 2: Movie file output recording observer
        //
        [self removeObserver:self
                  forKeyPath:@"movieFileOutput.recording"
                     context:RecordingContext
         ];
        
        //
        // Add 3: subject are change observer
        //
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVCaptureDeviceSubjectAreaDidChangeNotification
                                                      object:self.videoDeviceInput.device
         ];
        
        //
        // Add 4: Runtime error handling observer
        //
        [[NSNotificationCenter defaultCenter] removeObserver:self.runtimeErrorHandlingObserver];
    });
}

-(void)initAppObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    //
    // Request to start recording notification
    //
    [nc addUniqueObserver:self
                 selector:@selector(onShouldStartRecording:)
                     name:HM_NOTIFICATION_RECORDER_START_RECORDING
                   object:nil];
    
    //
    // Request to stop recording notification
    //
    [nc addUniqueObserver:self
                 selector:@selector(onShouldStopRecording:)
                     name:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                   object:nil];

    //
    // Request to flip camera
    //
    [nc addUniqueObserver:self
                 selector:@selector(onFlipCamera:)
                     name:HM_NOTIFICATION_RECORDER_FLIP_CAMERA
                   object:nil];

    //
    // Countdown started. Will focus camera on a specific point.
    //
    [nc addUniqueObserver:self
                 selector:@selector(onStartedCountdownNeedToFocusOnPoint:)
                     name:HM_NOTIFICATION_RECORDER_START_COUNTDOWN_BEFORE_RECORDING
                   object:nil];

    //
    // Countdown started. Will focus camera on a specific point.
    //
    [nc addUniqueObserver:self
                 selector:@selector(onCanceledCountdownNeedToResetCameraSettings:)
                     name:HM_NOTIFICATION_RECORDER_CANCEL_COUNTDOWN_BEFORE_RECORDING
                   object:nil];
    
    [nc addUniqueObserver:self
                 selector:@selector(onAppDidEnterForeground:)
                     name:HM_APP_WILL_ENTER_FOREGROUND
                   object:nil];

}

-(void)removeAppObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_FLIP_CAMERA object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_COUNTDOWN_BEFORE_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_CANCEL_COUNTDOWN_BEFORE_RECORDING object:nil];
    [nc removeObserver:self name:HM_APP_WILL_ENTER_FOREGROUND object:nil];
}

-(void)removeStopObserver
{
     __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
}

-(void)addStopOserver
{
    
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addUniqueObserver:self
                 selector:@selector(onShouldStopRecording:)
                     name:HM_NOTIFICATION_RECORDER_STOP_RECORDING
                   object:nil];
}

#pragma mark - Reveal
// Reveal slowly to prevent "flasing effect" of the preview
-(void)revealCameraPreviewAnimated:(BOOL)animated
{
    if (!animated) {
        self.view.alpha = 1;
        return;
    }
    
    [UIView animateWithDuration:1.5 animations:^{
        self.view.alpha = 1;
    }];
}

#pragma mark - status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Orientation changes
// translate the orientation
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    /**
     Translation needed because LandscapeRight and LandscapeLeft are swapped in the enumeration.
     Simple casting of UIDeviceOrientation to AVCaptureVideoOrientation may cause videos to be "upside down".
     Return AVCaptureVideoOrientationLandscapeRight by default (also when device is face up / face down).
     */
    
    /*UIDeviceOrientationLandscapeLeft: The device is in landscape mode, with the device held upright and the home button on the right side.
    
      UIDeviceOrientationLandscapeRight: The device is in landscape mode, with the device held upright and the home button on the left side.*/
    
     
    AVCaptureVideoOrientation result;
    
    // Never regard portrait as interesting, and map the flipped enums to each other (a silly apple inconsistency).
    
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
    result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
    result = AVCaptureVideoOrientationLandscapeLeft;
    else result = AVCaptureVideoOrientationLandscapeRight;
    
    return result;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{

    [UIView animateWithDuration:duration animations:^{
        self.previewView.alpha = 0;
    } completion:^(BOOL finished) {
        [self updateOrientation:toInterfaceOrientation];
        [UIView animateWithDuration:duration animations:^{
            self.previewView.alpha = 1;
        }];
    }];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (self.extractController)
    {
        UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;
        BOOL frontCamera = [self isFrontCamera];
        [self.extractController updateForegroundExtractorForOrientation:interfaceOrientation andCameraDirection:frontCamera];
    }
}


-(void)updateOrientation:(UIInterfaceOrientation)orientation
{
    
    UIDeviceOrientation deviceOrientation = (UIDeviceOrientation)orientation;
    self.previewLayer.connection.videoOrientation = [self avOrientationForDeviceOrientation:deviceOrientation];
    
}

-(BOOL)shouldAutorotate
{
    return !self.lockInterfaceRotation;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

#pragma mark - Authorization
-(BOOL)isSessionRunningAndDeviceAuthorized
{
    return [[self session] isRunning] && [self isDeviceAuthorized];
}

+ (NSSet *)keyPathsForValuesAffectingSessionRunningAndDeviceAuthorized
{
    return [NSSet setWithObjects:@"session.running", @"deviceAuthorized", nil];
}


#pragma mark - observers handlers
-(void)onShouldStartRecording:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSTimeInterval recordingDurationMS = [info[HM_INFO_DURATION_IN_SECONDS] doubleValue] * 1000;
    
    //stop observer should be called only once and can be triggered from multiple sources
    [self addStopOserver];
    [self startVideoRecording:info recordingDuration:recordingDurationMS];
}

-(void)onShouldStopRecording:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self removeStopObserver];
    [self stopVideoRecording:info];
}

-(void)onFlipCamera:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if ([info[@"forceCameraSelection"] isEqualToString:@"front"]) {
        // Forces to front camera (no selfie allowed)
        AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        if (currentPosition == AVCaptureDevicePositionFront) {
            [self refreshCameraFeedWithFlip:YES];
        }
        return;
    }
    
    //
    // Front and back allowed. Flip it.
    //
    [self refreshCameraFeedWithFlip:YES];
}

-(void)onStartedCountdownNeedToFocusOnPoint:(NSNotification *)notification
{
    NSArray *pointArray = notification.userInfo[HM_INFO_FOCUS_POINT];
    CGPoint point = CGPointMake([pointArray[0] doubleValue], [pointArray[1] doubleValue]);
    [self tryToFocusCameraOnPoint:point];
}

-(void)onCanceledCountdownNeedToResetCameraSettings:(NSNotification *)notification
{
    [self resetCameraToInitialFocusSettings];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == RecordingContext) {
        
        //
        // Recording context
        //
        // BOOL isRecording = [change[NSKeyValueChangeNewKey] boolValue];
        
    } else if (context == SessionRunningAndDeviceAuthorizedContext) {
        
        //
        // Session running and device authorized context.
        //
        // BOOL isRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
    } else {
        
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        
    }
}

#pragma mark - Camera initializations
// Camera initializations
-(void)initCamera
{
    // Create the AVCaptureSession
    self.session = [[AVCaptureSession alloc] init];;
    self.session.sessionPreset = self.camSettingsSessionPreset;
    
    // Setup the preview view
    [self initPreviewLayer];
    
    // Check for device authorization
    [self checkDeviceAuthorizationStatus];
    
    // Dispatch the rest of session setup to the sessionQueue so that the main queue isn't blocked.
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    self.sessionQueue = sessionQueue;
    
    dispatch_async(sessionQueue, ^{
        self.backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        //
        // Video Device
        //
        
        // Initializing the video device and device input (back camera preffered)
        self.videoDevice = [HMVideoCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:&error];
        
        if (error)
        {
            HMGLogError(@"%@", error);
        }
        
        // Add the video device input to the session.
        if ([self.session canAddInput:self.videoDeviceInput]) [self.session addInput:self.videoDeviceInput];
        
        
        //
        // Audio Device
        //
        AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (error)
        {
            HMGLogError(@"%@", error);
        }
        
        if ([self.session canAddInput:self.audioDeviceInput])
        {
            [self.session addInput:self.audioDeviceInput];
        }
        
        //
        // Output!
        //
        
        if (self.camFGExtraction) {
            //
            //  Output video with FG extraction
            //
            _movieDataOutput = [AVCaptureVideoDataOutput new];
            _movieDataOutput.alwaysDiscardsLateVideoFrames = NO;
            _movieDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
            
            _audioDataOutput = [AVCaptureAudioDataOutput new];

            if ([self.session canAddOutput:_movieDataOutput] && [self.session canAddOutput:_audioDataOutput]) {
                _extractController = [[HMExtractController alloc] initWithSession:self.session movieDataOutput:_movieDataOutput audioDataOutput:_audioDataOutput];
            }
        } else {
            //
            //  Output raw video
            //
            AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
            if ([self.session canAddOutput:movieFileOutput])
            {
                [self.session addOutput:movieFileOutput];
                AVCaptureConnection *connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                
                // Video stabilization
                if (connection.isVideoStabilizationSupported) connection.enablesVideoStabilizationWhenAvailable = YES;
                
                // Set the output
                self.movieFileOutput = movieFileOutput;
            }
        }
        
        //
        //  Framerate
        //
        if (self.videoDeviceInput.device) [self updateFPS];
    });
}

-(void)initPreviewLayer
{
    self.previewView.session = self.session;
    self.previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;

    // Preview layer settings
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

#pragma mark - Camera actions
-(void)tryToFocusCameraOnPoint:(CGPoint)point
{
    self.focusPoint = point;
    // Focus on a point
    [self focusWithMode:AVCaptureFocusModeAutoFocus
         exposeWithMode:AVCaptureExposureModeAutoExpose
        whiteBalanceWithMode:AVCaptureWhiteBalanceModeAutoWhiteBalance
          atDevicePoint:self.focusPoint monitorSubjectAreaChange:NO
     ];
}

-(void)resetCameraToInitialFocusSettings
{
    // Return to continues auto focus
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus
         exposeWithMode:AVCaptureExposureModeContinuousAutoExposure
        whiteBalanceWithMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance
          atDevicePoint:self.focusPoint monitorSubjectAreaChange:NO
     ];
}

#pragma mark - Start / Stop recording
-(void)startVideoRecording:(NSDictionary *)info recordingDuration:(NSTimeInterval)recordingDuration
{
    dispatch_async([self sessionQueue], ^{
        [self _startVideoRecording:info recordingDuration:recordingDuration];
    });
}

-(void)_startVideoRecording:(NSDictionary *)info recordingDuration:(NSTimeInterval)recordingDuration
{
    id outputController = self.extractController ? self.extractController : self.movieFileOutput;
    //if (![outputController isRecording])
    
    self.lastRecordingStartInfo = info;
    self.lockInterfaceRotation = YES;
    
    if ([[UIDevice currentDevice] isMultitaskingSupported])
    {
        // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
    }
    
    // Update the orientation on the movie file output video connection before starting recording.
    AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = self.previewLayer.connection.videoOrientation;
    
    // Turning OFF flash for video recording
    [HMVideoCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
    
    // Lock focus on a point (currently hard coded point, should be received from the server later.
    [self focusWithMode:AVCaptureFocusModeLocked
         exposeWithMode:AVCaptureExposureModeLocked
   whiteBalanceWithMode:AVCaptureWhiteBalanceModeLocked
          atDevicePoint:self.focusPoint monitorSubjectAreaChange:NO
     ];
    
    // Start recording to a temp file.
    NSString *fileName = info[@"fileName"];
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    HMGLogDebug(@"Output to:%@", tmpPath);
    
    if (outputController == self.extractController)
    {
        UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;
        BOOL frontCamera = [self isFrontCamera];
        [self.extractController setupExtractorientationWithDeviceOrientation:interfaceOrientation frontCamera:frontCamera];
        self.extractController.recordingDuration = recordingDuration;
    }
    
    [outputController startRecordingToOutputFileURL:[NSURL fileURLWithPath:tmpPath]
                                  recordingDelegate:self];
}

-(void)stopVideoRecording:(NSDictionary *)info
{
    dispatch_async([self sessionQueue], ^{
        [self _stopVideoRecording:info];
    });
}

-(void)_stopVideoRecording:(NSDictionary *)info
{
    id outputController = self.extractController ? self.extractController : self.movieFileOutput;
    self.lastRecordingStopInfo = info;
    [outputController stopRecording];
    [self resetCameraToInitialFocusSettings];
}


-(BOOL)isFrontCamera
{
    AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
    AVCaptureDevicePosition position = currentVideoDevice.position;
    if (position == AVCaptureDevicePositionFront) return YES;
    return NO;
}

-(BOOL)isBackCamera
{
    AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
    AVCaptureDevicePosition position = currentVideoDevice.position;
    if (position == AVCaptureDevicePositionBack) return YES;
    return NO;
}

+(BOOL)canFlipToFrontCamera
{
    AVCaptureDevice *videoDevice = [HMVideoCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
    return [videoDevice supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480];//AVCaptureSessionPreset1280x720];
}

-(void)refreshCameraFeedWithFlip:(BOOL)flip
{
    UIView *tempView = [[UIView alloc] init];
    tempView.frame = self.previewView.superview.frame;
    tempView.backgroundColor = [UIColor darkGrayColor];
    
    AVCamPreviewView *previewViewStrongRef = self.previewView;
    [UIView transitionFromView:self.previewView.superview toView:tempView duration:0.7 options:UIViewAnimationOptionTransitionFlipFromBottom completion:^(BOOL finished) {
        previewViewStrongRef.alpha = 0;
        [UIView transitionFromView:tempView toView:self.previewView.superview duration:0.0 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
            [UIView animateWithDuration:0.7 delay:0.7 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.previewView = previewViewStrongRef;
                self.previewView.alpha = 1;
            } completion:nil];
        }];
    }];
    
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        //1605
        
        if (flip)
        {
            switch (currentPosition)
            {
                case AVCaptureDevicePositionUnspecified:
                    preferredPosition = AVCaptureDevicePositionBack;
                    break;
                case AVCaptureDevicePositionBack:
                    preferredPosition = AVCaptureDevicePositionFront;
                    break;
                case AVCaptureDevicePositionFront:
                    preferredPosition = AVCaptureDevicePositionBack;
                    break;
            }
        } else {
            switch (currentPosition)
            {
                case AVCaptureDevicePositionUnspecified:
                    preferredPosition = AVCaptureDevicePositionBack;
                    break;
                case AVCaptureDevicePositionBack:
                    preferredPosition = AVCaptureDevicePositionBack;
                    break;
                case AVCaptureDevicePositionFront:
                    preferredPosition = AVCaptureDevicePositionFront;
                    break;
            }
            
        }
        
        NSError *error;
        AVCaptureDevice *videoDevice = [HMVideoCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (error) HMGLogError(@"Camera videoDeviceInput error:%@", error);
        
        [[self session] beginConfiguration];
        [[self session] removeInput:[self videoDeviceInput]];
        
        self.session.sessionPreset = self.camSettingsSessionPreset;
        if (videoDevice.position == AVCaptureDevicePositionFront && ![self.session canAddInput:videoDeviceInput]) {
            // If can't add front camera, it is probably because
            // it is an old device that doesn't support 720p front camera
            // change to the fallback preset.
            
            self.session.sessionPreset = self.camSettingsSessionPresetFrontCameraFallback;
        }
        
        if ([[self session] canAddInput:videoDeviceInput])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [HMVideoCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [[self session] addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
            [self updateFPS];
        }
        else
        {
            if ([[self session] canAddInput:[self videoDeviceInput]])
            {
                [[self session] addInput:[self videoDeviceInput]];
                [self updateFPS];
            }
        }
        
        [[self session] commitConfiguration];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Let the main thread know what camera was selected.
            if (preferredPosition == AVCaptureDevicePositionFront) {
                [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_USING_FRONT_CAMERA object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_USING_BACK_CAMERA object:nil];
            }
            
            //update the foreground extractor that we changed orientaion or camera feed
            if (self.extractController)
            {
                UIInterfaceOrientation interfaceOrientation = self.interfaceOrientation;
                BOOL frontCamera = [self isFrontCamera];
                [self.extractController updateForegroundExtractorForOrientation:interfaceOrientation andCameraDirection:frontCamera];
            }
        });
    });
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose         whiteBalanceWithMode:AVCaptureWhiteBalanceModeAutoWhiteBalance
          atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

-(void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure         whiteBalanceWithMode:AVCaptureWhiteBalanceModeAutoWhiteBalance
          atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

#pragma mark File Output Delegate
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    self.lockInterfaceRotation = NO;
    
    //
    // End background task.
    //
    UIBackgroundTaskIdentifier backgroundRecordingID = [self backgroundRecordingID];
    [self setBackgroundRecordingID:UIBackgroundTaskInvalid];
    if (backgroundRecordingID != UIBackgroundTaskInvalid) [[UIApplication sharedApplication] endBackgroundTask:backgroundRecordingID];

    //
    // Find related objects in local storage
    //
    NSString *remakeID = self.lastRecordingStartInfo[@"remakeID"];
    NSNumber *sceneID = self.lastRecordingStartInfo[@"sceneID"];
    Remake *remake = [Remake findWithID:remakeID inContext:DB.sh.context];
    Footage *footage = [remake footageWithSceneID:sceneID];
    Scene *scene = [remake.story findSceneWithID:sceneID];
    if (remake == nil || footage == nil || scene == nil) {
        [[Mixpanel sharedInstance] track:@"RECaptureOutputValidated" properties:@{@"remake_id":remakeID, @"scene_id":sceneID}];
        [self epicFailWithOutputFileURL:outputFileURL];
        return;
    }
    
    //
    // If camera error, just cleanup and show error message to the user.
    //
    if (error) {
        HMGLogDebug(@"Recording failed with an error:%@", [error description]);
        [[Mixpanel sharedInstance] track:@"RECaptureOutputError" properties:@{@"remake_id":remakeID, @"scene_id":sceneID, @"error_description":[error description]}];
        [self epicFailWithOutputFileURL:outputFileURL];
        return;
    }
    
    //
    // No camera errors. Check the reason for why the recording was stopped.
    // Was it cancelled by the user or the recorder for some reason?
    //
    NSInteger recordStopReason = [self.lastRecordingStopInfo[HM_INFO_KEY_RECORDING_STOP_REASON]integerValue];
    if (recordStopReason == HMRecordingStopReasonUserCanceled ||
        recordStopReason == HMRecordingStopReasonCameraNotStable ||
        recordStopReason == HMRecordingStopReasonAppWentToBackground) {
        
        HMGLogDebug(@"Recording was canceled with reason:%d", recordStopReason);
        [[Mixpanel sharedInstance] track:@"RECaptureOutputCanceledWithReason" properties:@{@"remake_id":remakeID, @"scene_id":sceneID, @"reason_code":@(recordStopReason)}];

        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        return;
    }
    
    
    //
    // Validate output video file.
    //
    NSString *fileName = [outputFileURL lastPathComponent];
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];

    NSString *rawMoviePath = [documentsPath stringByAppendingPathComponent:fileName];
    
    AVURLAsset *outputAsset = [AVURLAsset URLAssetWithURL:outputFileURL options:nil];
    CMTime cmTimeDuration = outputAsset.duration;
    NSTimeInterval outputDuration = CMTimeGetSeconds(cmTimeDuration); // In seconds
    NSTimeInterval targetDuration = scene.duration.doubleValue;
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:outputFileURL.path error:&error];
    
    // Check for existance of output file.
    if (fileInfo == nil ||
        outputAsset == nil ||
        isnan(outputDuration) ||
        outputDuration == 0) {

        // Asset doesn't exist, is empty or duration is corrupted.
        [[Mixpanel sharedInstance] track:@"RECaptureOutputMissing" properties:@{@"remake_id":remakeID, @"scene_id":sceneID}];
        [self epicFailWithOutputFileURL:outputFileURL];
        return;
    }
    
    // Validate duration of the output file.
    outputDuration = round(outputDuration * 1000.0f); // Converted to mseconds
    NSTimeInterval diffDuration = outputDuration - targetDuration;
    HMGLogDebug(@"Output duration:%f  target:%f  diff:%f", outputDuration, targetDuration, diffDuration);
    if (fabs(diffDuration) > 300) {
        // Duration difference is very large.
        // Something went wrong with the recording timer.
        // FIX THIS! This is a critical bug. This shouldn't ever happen.
        [[Mixpanel sharedInstance] track:@"RECaptureOutputWrongDuration" properties:@{
                                                                                  @"remake_id":remakeID,
                                                                                  @"scene_id":sceneID,
                                                                                  @"target_duration":@(targetDuration),
                                                                                  @"output_duration":@(outputDuration),
                                                                                  @"duration_diff":@(diffDuration),
                                                                                  }];
        [self epicFailWithOutputFileURL:outputFileURL];
        return;
    }
    
    // Check if file is suspiciously small compared to video duration.
    // If it is, this is probably because of the bug that causes videos to be
    // saved with audio only. Fail footage in such cases and report the event to mixpanel with info.
    unsigned long long fileSize = [fileInfo fileSize];
    unsigned long long threshold = outputDuration * 20;
    if (fileSize < threshold) {
        HMGLogError(@"Output file size suspiciously short :%d", fileSize);
        [[Mixpanel sharedInstance] track:@"RECaptureOutputFileSuspiciouslyShort" properties:@{
                                                                                      @"remake_id":remakeID,
                                                                                      @"scene_id":sceneID,
                                                                                      @"output_duration":@(outputDuration),
                                                                                      @"file_size":@(fileSize),
                                                                                      }];
        [self epicFailWithOutputFileURL:outputFileURL];
        return;
    }
    
    //
    // Move the file to its finale destination
    //
    NSError *moveError;
    [[NSFileManager defaultManager] moveItemAtURL:outputFileURL toURL:[NSURL fileURLWithPath:rawMoviePath] error:&moveError];
    if (moveError) {
        //
        // Something went wrong with copying the file from the tmp dir to the local videos directory.
        //
        HMGLogError(@"Error while moving movie to :%@", rawMoviePath);
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        return;
    }
    
    //
    // Notify the recorder that a new valid raw footage file is available.
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE
                                                        object:self
                                                      userInfo:@{@"rawMoviePath":rawMoviePath,
                                                                 @"remakeID":remakeID,
                                                                 @"sceneID":sceneID
                                                                 }];
    
    //
    // Report validated output to mixpanel with details.
    //
    [[Mixpanel sharedInstance] track:@"RECaptureOutputValidated" properties:@{
                                                                              @"remake_id":remakeID,
                                                                              @"scene_id":sceneID,
                                                                              @"target_duration":@(targetDuration),
                                                                              @"output_duration":@(outputDuration),
                                                                              @"duration_diff":@(diffDuration),
                                                                              @"file_size":@(fileSize)
                                                                              }];
}
         
-(void)epicFailWithOutputFileURL:(NSURL *)outputFileURL
{
    [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];

    //
    // Notify the recorder that the recording failed.
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_EPIC_FAIL
                                                        object:self
                                                      userInfo:nil];
}

#pragma mark Device Configuration
- (void)updateFPS
{
    AVCaptureDevice *device = self.videoDeviceInput.device;
    NSInteger minFPS = self.camSettingsMinFramesPerSecond;
    NSInteger maxFPS = self.camSettingsMaxFramesPerSecond;
    dispatch_async([self sessionQueue], ^{
        NSError *error;
        
        if ([device lockForConfiguration:&error])
        {
            NSArray *supportedFPSRanges = device.activeFormat.videoSupportedFrameRateRanges;
            BOOL frameRateSupported = NO;
            for (AVFrameRateRange *range in supportedFPSRanges) {
                if (range.minFrameRate <= minFPS && range.maxFrameRate >= maxFPS) {
                    frameRateSupported = YES;
                }
            }
            if (frameRateSupported) {
                device.activeVideoMinFrameDuration = CMTimeMake(1, (int)minFPS);
                device.activeVideoMaxFrameDuration = CMTimeMake(1, (int)maxFPS);
                HMGLogDebug(@"Changed to frame rate range: %d - %d", minFPS, maxFPS);
            } else {
                HMGLogDebug(@"Frame rate range unsupported: %d - %d. Using camera defaults instead.", minFPS, maxFPS);
            }
            
            [device unlockForConfiguration];
        } else {
            HMGLogError(@"%@", error);
        }
    });
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode whiteBalanceWithMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *device = [[self videoDeviceInput] device];
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
            {
                [device setFocusMode:focusMode];
                [device setFocusPointOfInterest:point];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
            {
                [device setExposureMode:exposureMode];
                [device setExposurePointOfInterest:point];
            }
            if ([device isWhiteBalanceModeSupported:whiteBalanceMode])
            {
                [device setWhiteBalanceMode:whiteBalanceMode];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
        else
        {
            HMGLogError(@"%@", error);
        }
    });
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            HMGLogError(@"%@", error);
        }
    }
}

#pragma mark - CAMERA CONFIGURATIONS
+(AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType
                     preferringPosition:(AVCaptureDevicePosition)position
{
    // Get a list of devices of the given media type (usually [Back Camera] + [Front Camera])
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices lastObject];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            
            break;
        }
    }
    return captureDevice;
}

#pragma mark - Device Authorization status
- (void)checkDeviceAuthorizationStatus
{
    NSString *mediaType = AVMediaTypeVideo;
    [AVCaptureDevice requestAccessForMediaType:mediaType
                             completionHandler:^(BOOL granted) {
        if (granted) {

            //Granted access to mediaType
            self.deviceAuthorized = YES;
            
        } else {

            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:LS(@"Homage CAM!")
                                            message:LS(@"Homage doesn't have permission to use Camera, please change privacy settings")
                                           delegate:self
                                  cancelButtonTitle:LS(@"OK")
                                  otherButtonTitles:nil
                  ] show];
                self.deviceAuthorized = NO;
            });
        }
    }];
}

-(void)onAppDidEnterForeground:(NSNotification *)notification
{
    [self refreshCameraFeedWithFlip:NO];
}

-(void)attachCameraIO
{
    if (_camFGExtraction && self.extractController && self.session.inputs.count == 0) {
        [self.session addInput:self.videoDeviceInput];
        [self.session addInput:self.audioDeviceInput];
        [self.session addOutput:self.movieDataOutput];
        [self.session addOutput:self.audioDataOutput];
    }
}


-(void)releaseCameraIO
{
    if (_camFGExtraction && self.extractController) {
        [self.session removeInput:self.videoDeviceInput];
        [self.session removeInput:self.audioDeviceInput];
        [self.session removeOutput:self.movieDataOutput];
        [self.session removeOutput:self.audioDataOutput];
    }
}

-(void)updateContour:(NSString *)contourlocalURL
{
    if (_camFGExtraction)
    {
        [self.extractController updateContour:contourlocalURL];
    }
}

@end