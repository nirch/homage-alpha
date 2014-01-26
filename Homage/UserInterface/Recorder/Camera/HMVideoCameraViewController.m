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

// Contexts
static void *RecordingContext = &RecordingContext;
static void *SessionRunningAndDeviceAuthorizedContext = &SessionRunningAndDeviceAuthorizedContext;

@interface HMVideoCameraViewController () <
    AVCaptureFileOutputRecordingDelegate
>

// For use in the storyboards.
@property (nonatomic, weak) IBOutlet AVCamPreviewView *previewView;
@property (nonatomic, weak) AVCaptureVideoPreviewLayer *previewLayer;

// Session management.
@property (nonatomic) dispatch_queue_t sessionQueue; // Communicate with the session and other session objects on this queue.
@property (nonatomic) AVCaptureSession *session;

@property (nonatomic) AVCaptureDevice *videoDevice;
@property (nonatomic) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

// Utilities.
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, getter = isDeviceAuthorized) BOOL deviceAuthorized;
@property (nonatomic, readonly, getter = isSessionRunningAndDeviceAuthorized) BOOL sessionRunningAndDeviceAuthorized;
@property (nonatomic) BOOL lockInterfaceRotation;
@property (nonatomic) id runtimeErrorHandlingObserver;

// Some info about beginning and end of a recording
@property (nonatomic) NSDictionary *lastRecordingStartInfo;
@property (nonatomic) NSDictionary *lastRecordingStopInfo;

// Camera settings
@property (nonatomic, readonly) NSString *camSettingsSessionPreset;
@property (nonatomic, readonly) NSInteger camSettingsPrefferedDevicePosition;
@property (nonatomic, readonly) NSString *camSettingsPreviewLayerVideoGravity;


@end

@implementation HMVideoCameraViewController

#pragma mark - Camera settings
-(void)initCameraSettings
{
    // Camera
    _camSettingsSessionPreset               = AVCaptureSessionPreset1280x720;         // Video capture resolution
    _camSettingsPrefferedDevicePosition     = AVCaptureDevicePositionBack;            // Preffered camera position
    
    // Preview layer
    _camSettingsPreviewLayerVideoGravity    = AVLayerVideoGravityResizeAspectFill;    // Video gravity on the preview layer
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
    [self initAVObservers];
    [self initAppObservers];
}

//
// Fix orientation on view did appear
//
-(void)viewDidAppear:(BOOL)animated
{
    [self updateOrientation:(UIInterfaceOrientation)[UIDevice currentDevice].orientation]; //[UIApplication sharedApplication].statusBarOrientation
    
}

//
// When view did disappear, stop the session and remove the observers.
//
- (void)viewDidDisappear:(BOOL)animated
{
    [self removeAppObservers];
    [self removeAVObservers];
}

#pragma mark - Silly effects
-(void)slowReveal
{
    self.view.alpha = 0;
    double delayInSeconds = 1.0;
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


}

-(void)removeAppObservers
{
    __weak NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_START_RECORDING object:nil];
    [nc removeObserver:self name:HM_NOTIFICATION_RECORDER_STOP_RECORDING object:nil];
}

#pragma mark - Reveal
// Reveal slowly to prevent "flasing effect" of the preview
-(void)revealCameraPreviewAnimated:(BOOL)animated
{
    if (!animated) {
        self.view.alpha = 1;
        return;
    }
    
    [UIView animateWithDuration:2.0 animations:^{
        self.view.alpha = 1;
    }];
}

#pragma mark - Status bar

#pragma mark - status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Orientation changes
//translate the orientation
-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    /**
     Translation needed because LandscapeRight and LandscapeLeft are swapped in the enumeration.
     Simple casting of UIDeviceOrientation to AVCaptureVideoOrientation may cause videos to be "upside down".
     On portrait, return AVCaptureVideoOrientationLandscapeLeft by default.
     */
    AVCaptureVideoOrientation result;
    
    // Never regard portrait as interesting, and map the flipped enums to each other (a silly apple inconsistency).
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
    result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
    result = AVCaptureVideoOrientationLandscapeLeft;
    else if( deviceOrientation == UIDeviceOrientationPortrait)
    result = AVCaptureVideoOrientationLandscapeLeft;
    else result = AVCaptureVideoOrientationLandscapeLeft;
    
    return result;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self updateOrientation:toInterfaceOrientation]; // [UIApplication sharedApplication].statusBarOrientation
}

-(void)updateOrientation:(UIInterfaceOrientation)orientation
{
    self.previewLayer.connection.videoOrientation = [self avOrientationForDeviceOrientation:orientation];
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
    [self toggleMovieRecording:info];
}

-(void)onShouldStopRecording:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self toggleMovieRecording:info];
}

-(void)onFlipCamera:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if ([info[@"forceCameraSelection"] isEqualToString:@"front"]) {
        // Forces to front camera (no selfie allowed)
        AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        if (currentPosition == AVCaptureDevicePositionFront) {
            [self changeCamera];
        }
        return;
    }
    
    //
    // Front and back allowed. Flip it.
    //
    [self changeCamera];
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
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        if (error)
        {
            HMGLogError(@"%@", error);
        }
        
        if ([self.session canAddInput:audioDeviceInput])
        {
            [self.session addInput:audioDeviceInput];
        }
        
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
-(void)toggleMovieRecording:(NSDictionary *)info
{
    dispatch_async([self sessionQueue], ^{
        if (![[self movieFileOutput] isRecording])
        {
            self.lastRecordingStartInfo = info;
            self.lockInterfaceRotation = YES;
            
            if ([[UIDevice currentDevice] isMultitaskingSupported])
            {
                // Setup background task. This is needed because the captureOutput:didFinishRecordingToOutputFileAtURL: callback is not received until AVCam returns to the foreground unless you request background execution time. This also ensures that there will be time to write the file to the assets library when AVCam is backgrounded. To conclude this background execution, -endBackgroundTask is called in -recorder:recordingDidFinishToOutputFileURL:error: after the recorded file has been saved.
                [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil]];
            }
            
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            connection.videoOrientation = [self avOrientationForDeviceOrientation:[UIApplication sharedApplication].statusBarOrientation];
            
            // Turning OFF flash for video recording
            [HMVideoCameraViewController setFlashMode:AVCaptureFlashModeOff forDevice:[[self videoDeviceInput] device]];
            
            // Lock focus on a point (currently hard coded point, should be received from the server later.
            [self focusWithMode:AVCaptureFocusModeLocked
                 exposeWithMode:AVCaptureExposureModeLocked
                  atDevicePoint:CGPointMake(0.5,0.5) monitorSubjectAreaChange:NO
             ];
            
            // Start recording to a temp file.
            NSString *fileName = info[@"fileName"];
            NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
            HMGLogDebug(@"Output to:%@", tmpPath);
            [[self movieFileOutput] startRecordingToOutputFileURL:[NSURL fileURLWithPath:tmpPath] recordingDelegate:self];
        }
        else
        {
            self.lastRecordingStopInfo = info;
            [[self movieFileOutput] stopRecording];
        }
    });
}

-(void)changeCamera
{
    UIView *tempView = [[UIView alloc] init];
    tempView.frame = self.previewView.frame;
    
    AVCamPreviewView *previewViewStrongRef = self.previewView;
    [UIView beginAnimations:nil context:NULL];
    [UIView transitionFromView:self.previewView toView:tempView duration:0.5 options:UIViewAnimationOptionTransitionFlipFromBottom completion:^(BOOL finished) {
        previewViewStrongRef.alpha = 0;
        [UIView transitionFromView:tempView toView:previewViewStrongRef duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5 animations:^{
                self.previewView = previewViewStrongRef;
                self.previewView.alpha = 1;
            }];
        }];
    }];
    [UIView commitAnimations];
    
    dispatch_async([self sessionQueue], ^{
        AVCaptureDevice *currentVideoDevice = [[self videoDeviceInput] device];
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
        
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
        
        AVCaptureDevice *videoDevice = [HMVideoCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
        
        [[self session] beginConfiguration];

        [[self session] removeInput:[self videoDeviceInput]];
        if ([[self session] canAddInput:videoDeviceInput])
        {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentVideoDevice];
            
            [HMVideoCameraViewController setFlashMode:AVCaptureFlashModeAuto forDevice:videoDevice];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:videoDevice];
            
            [[self session] addInput:videoDeviceInput];
            [self setVideoDeviceInput:videoDeviceInput];
        }
        else
        {
            [[self session] addInput:[self videoDeviceInput]];
        }
        
        [[self session] commitConfiguration];
        [self updateOrientation:(UIInterfaceOrientation)[UIApplication sharedApplication].statusBarOrientation];
    });
}

- (IBAction)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)[[self previewView] layer] captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:[gestureRecognizer view]]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

-(void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
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
    // If camera error (user exited app for example), just cleanup the temp file and exit.
    //
    if (error) {
        HMGLogError(@"captureOutput error: %@", error);
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        return;
    }
    
    //
    // No camera errors. Check the reason for why the recording was stopped.
    // Was it cancelled by the user or a legal footage is available?
    //
    if ([self.lastRecordingStopInfo[HM_INFO_KEY_RECORDING_STOP_REASON] integerValue] == HMRecordingStopReasonUserCanceled) {
        HMGLogDebug(@"User canceled recording.");
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        return;
    }
    
    //
    // Move the file to its finale destination
    //
    NSError *moveError;
    NSString *fileName = [outputFileURL lastPathComponent];
    NSString *documentsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSString *rawMoviePath = [documentsPath stringByAppendingPathComponent:fileName];
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
    // Notify the recorder that a new raw footage file is available.
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:HM_NOTIFICATION_RECORDER_RAW_FOOTAGE_FILE_AVAILABLE
                                                        object:self
                                                      userInfo:@{@"rawMoviePath":rawMoviePath,
                                                                 @"remakeID":self.lastRecordingStartInfo[@"remakeID"],
                                                                 @"sceneID":self.lastRecordingStartInfo[@"sceneID"]
                                                                 }
     ];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
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



//- (void)configureCameraForFrameRate:(AVCaptureDevice *)device
//{
//    if ( [device lockForConfiguration:NULL] == YES ) {
//        // device.activeFormat = bestFormat;
//        device.activeVideoMinFrameDuration = CMTimeMake(1, 1);
//        device.activeVideoMaxFrameDuration = CMTimeMake(1, 1);
//        //id x = device.activeFormat.videoSupportedFrameRateRanges;
//        [device unlockForConfiguration];
//    }
//}

#pragma mark - CAMERA CONFIGURATIONS
+(AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType
                     preferringPosition:(AVCaptureDevicePosition)position
{
    // Get a list of devices of the given media type (usually [Back Camera] + [Front Camera])
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
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


@end