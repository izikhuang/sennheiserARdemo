//
//  CameraViewController.m
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <QuartzCore/QuartzCore.h>
#import <sys/utsname.h>

#import "ARScanController.h"

#import "TextureUtilities.h"
#import "MBProgressHUD.h"

// --- Defines --- ;
struct utsname systemInfo ;

const char* machineName()
{
    uname( &systemInfo ) ;
    return systemInfo.machine ;
}

static char* getRGBA( UIImage* image )
{
	size_t width    = CGImageGetWidth( image.CGImage ) ;
	size_t height   = CGImageGetHeight( image.CGImage ) ;
	size_t bitsPerComponent = 8 ;
	size_t bytesPerRow = width * 4 ;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB() ;
    assert( colorSpace ) ;
	
	void* data = malloc( bytesPerRow * height ) ;
    assert( data ) ;
	memset( data,0,bytesPerRow * height ) ;
	
	CGContextRef context = CGBitmapContextCreate(data,
												 width,
												 height,
												 bitsPerComponent,
												 bytesPerRow,
												 colorSpace,
												 kCGImageAlphaPremultipliedLast ) ;
	
	assert( context ) ;
    
	CGColorSpaceRelease( colorSpace ) ;
	
	// Draw image on bitmap
	CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage ) ;
	CGContextRelease( context ) ;
	return ( char* )data ;
}

bool read_png_image( const char* filename, char** data, int* width, int* height )
{
	NSString*   fileNameNS  = [ NSString stringWithUTF8String : filename ] ;
	UIImage*    image       = [ UIImage imageWithData : [ NSData dataWithContentsOfFile : fileNameNS ] ] ;
    
	if( image )
    {
		*width  = ( int )image.size.width ;
		*height = ( int )image.size.height ;
		*data   = getRGBA( image ) ;
		return true ;
	}
	else
    {
		NSLog( @"No such image %@", fileNameNS ) ;
	}
    
	return false ;
}

// ARScanController Class ;
@interface ARScanController ( Private ) 

- ( void ) initCapture ;
- ( void ) realCaptureOutput : ( id ) _pixData ;
- ( void ) eventHandler : ( id ) _data ;
- ( void ) startCamera ;
- ( void ) restartCamera ;
- ( void ) stopCamera ;
- ( void ) setupGraphics ;
- ( void ) setupVideoTexture ;
- ( void ) switchToOrtho ;
- ( void ) switchToCamera ;
- ( void ) initLighting ;
- ( void ) enableLighting ;
- ( void ) disableLighting ;
- ( void ) loadCameraTexture : ( char* ) _data ;
- ( void ) processCameraFrame : ( char* ) _data ;
- ( void ) renderCameraFrame ;
- ( void ) renderPointCloud ;
- ( void ) renderContent ;
- ( void ) renderFrame : ( char* ) _data length : ( int ) _length ;

- ( void ) drawView : ( EAGLView* ) _view ;
- ( void ) setupView : ( EAGLView* ) _view ;

// Load ;
- ( void ) loadModelWithProgress : ( NSString* ) _pathForModel ;
- ( void ) loadModel : ( NSString* ) _pathForModel ;
- ( void ) loadTrackPoints ;

@end

@implementation ARScanController

// Properties ;
@synthesize model ;

// Functions ;
#pragma mark - Shared Functions
+ ( ARScanController* ) sharedController
{
	__strong static ARScanController* sharedController = nil ;
	static dispatch_once_t onceToken ;
    
	dispatch_once( &onceToken, ^{
        sharedController = [ [ ARScanController alloc ] initWithNibName : @"ARScanController" bundle : nil ]  ;
	} ) ;
    
    return sharedController ;
}

#pragma mark - View Controller
- ( id ) initWithNibName : ( NSString* ) _nibNameOrNil bundle : ( NSBundle* ) _nibBundleOrNil
{
    self = [ super initWithNibName : _nibNameOrNil bundle : _nibBundleOrNil ] ;
    
    if( self )
    {
        model       = nil ;
    }
    
    return self ;
}

- ( void ) dealloc
{
    [ model release ] ;
    [ captureSession release ] ;
    pointcloud_destroy() ;
    
    [ super dealloc ] ;
}

- ( void ) viewDidLoad
{
    [ super viewDidLoad ] ;
    
    // Camera ;
    restartCamera           = NO ;
    accelerometerAvailable  = NO ;
    deviceMotionAvailable   = NO ;
    
    // Point Cloud ;
    loading                 = NO ;
    
    // Double the resolution on iPhone 4 and 4s etc.
    if( [ [ UIScreen mainScreen ] respondsToSelector : @selector( scale ) ] )
    {
        scaleFactor = [ UIScreen mainScreen ].scale ;
    }
    else
    {
        scaleFactor = 1.0f ;
    }
    
    if( [ cameraView respondsToSelector : @selector( setContentScaleFactor: ) ] )
    {
        [ cameraView setContentScaleFactor : scaleFactor ] ;
    }
    
    [ cameraView setDelegate : self ] ;
    
    [ self initCapture ] ;
	
	motionManager = [ [ CMMotionManager alloc ] init ] ;
	
	if( motionManager.accelerometerAvailable )
    {
		accelerometerAvailable = YES ;
		[ motionManager startAccelerometerUpdates ] ;
	}
	
	if( motionManager.deviceMotionAvailable )
    {
		deviceMotionAvailable = YES ;
		[ motionManager startDeviceMotionUpdates ] ;
	}
}

- ( void ) viewDidUnload
{
    [ super viewDidUnload ] ;
}

- ( void ) viewDidAppear : ( BOOL ) _animated
{
    [ super viewDidAppear : _animated ] ;
    
    // Camera ;
    [ self startCamera ] ;
    
    // Load ;
    [ self loadModelWithProgress : nil ] ;
}

- ( void ) viewDidDisappear : ( BOOL ) _animated
{
    [ super viewDidDisappear : _animated ] ;
    
    // Camera ;
    [ self stopCamera ] ;
}

- ( BOOL ) shouldAutorotateToInterfaceOrientation : ( UIInterfaceOrientation ) _interfaceOrientation
{
    return ( _interfaceOrientation == UIInterfaceOrientationPortrait ) ;
}

#pragma mark - EAGLView
- ( void ) setupView : ( EAGLView* ) _View
{
    
}

- ( void ) drawView : ( UIView* ) _view
{  
    CVReturn nLockResult = CVPixelBufferLockBaseAddress ( pixelBuffer, 0 ) ;
    
	if( nLockResult == kCVReturnSuccess )
    {
		if( accelerometerAvailable )
        {
			if( !motionManager.accelerometerActive )
			{
                [ motionManager startAccelerometerUpdates ] ;
            }
			
			CMAccelerometerData* pstAccelerometerData = motionManager.accelerometerData ;
            
			if( pstAccelerometerData )
            {
   				CMAcceleration stAcceleration   = pstAccelerometerData.acceleration ;
				pointcloud_on_accelerometer_update( stAcceleration.y, stAcceleration.x, stAcceleration.z ) ;
			}
		}
        
		if( deviceMotionAvailable )
        {
			if( !motionManager.deviceMotionActive )
            {
				[ motionManager startDeviceMotionUpdates ] ;
            }
            
			CMDeviceMotion* pstDeviceMotion = motionManager.deviceMotion ;
            
			if( pstDeviceMotion )
            {
				CMAcceleration stAcceleration   = pstDeviceMotion.userAcceleration ;
				CMRotationRate stRotateRate     = pstDeviceMotion.rotationRate ;
                pointcloud_on_device_motion_update( stAcceleration.y, stAcceleration.x, stAcceleration.z,
                                                    stRotateRate.y, stRotateRate.x, stRotateRate.z ) ;
            }
		}
        
		char* pszBaseAddress = ( char* )CVPixelBufferGetBaseAddress( pixelBuffer ) ;
        
        [ self renderFrame : pszBaseAddress length : CVPixelBufferGetDataSize( pixelBuffer ) ] ;
		CVPixelBufferUnlockBaseAddress ( pixelBuffer, 0 ) ;
	}
}

#pragma mark - AVCaptureOutput
- ( void ) captureOutput : ( AVCaptureOutput* ) _captureOutput didOutputSampleBuffer : ( CMSampleBufferRef ) _sampleBuffer fromConnection : ( AVCaptureConnection* ) _connection
{
    NSData* data = nil ;
    
    if( _sampleBuffer == nil )
    {
        return ;
    }
	
    CFRetain( _sampleBuffer ) ;
    
    data = [ [ NSData alloc ] initWithBytesNoCopy : _sampleBuffer length : 4 freeWhenDone : NO ] ;
    
	if( ![ NSThread isMainThread ] )
    {
        [ self performSelectorOnMainThread : @selector( realCaptureOutput: ) withObject : data waitUntilDone : true ] ;
    }
    else
    {
        [ self realCaptureOutput : data ] ;
    }
    
    [ data release ] ;
    CFRelease( _sampleBuffer ) ;
}

#pragma mark - Camera
- ( void ) initCapture
{
    int                         nInx            = 0 ;
    int                         nCnt            = 0 ;
    double                      dMax_FPS        = 30 ;

    NSError*                    error           = nil ;
    NSArray*                    array           = nil ;
    id                          event           = nil ;
    NSArray*                    events          = nil ;
    NSMutableDictionary*        dict            = nil ;
    NSNumber*                   number          = nil ;
    
	AVCaptureDevice*            device          = nil ;
	AVCaptureDevice*            tempDevice      = nil ;
    AVCaptureFocusMode          focusMode       = AVCaptureFocusModeContinuousAutoFocus ;
    AVCaptureDeviceInput*       input           = nil ;
    AVCaptureVideoDataOutput*   output          = nil ;
    AVCaptureConnection*        connection      = nil ;

	captureSession  = [ [ AVCaptureSession alloc ] init ] ;
	array           = [ AVCaptureDevice devices ] ;
	
    for( nInx = 0, nCnt = [ array count ] ; nInx < nCnt && device == nil ; nInx ++ )
    {
        tempDevice = [ array objectAtIndex : nInx ] ;

		if( tempDevice.position == AVCaptureDevicePositionBack && [ tempDevice hasMediaType : AVMediaTypeVideo ] )
        {
			device = tempDevice ;
		}
    }
	
	if( device == nil )
    {
		return ;
	}
    
	if( [ device isFocusModeSupported : focusMode ] )
    {
		if( [ device lockForConfiguration: &error ] )
        {
			[ device setFocusMode : focusMode ] ;
			[ device unlockForConfiguration ] ;
		}
        else
        {
			NSLog( @"lockForConfiguration ERROR: %@", error ) ;
		}
	}
	
    // Device Input ;
    input       = [ [ AVCaptureDeviceInput alloc ] initWithDevice : device error : &error ] ;
    
    if( !input )
    {
        return ;
    }
    
	if( device == nil )
    {
		NSLog( @"Device is nil" ) ;
	}
	
    // Data Output ;
	output      = [ [ AVCaptureVideoDataOutput alloc ] init ] ;
    output.alwaysDiscardsLateVideoFrames = YES ;
    
    dict        = [ [ NSMutableDictionary alloc ] init ] ;
    number      = [ [ NSNumber alloc ] initWithUnsignedInt : kCVPixelFormatType_32BGRA ] ;
    
    [ dict setValue : number forKey : ( NSString* ) kCVPixelBufferPixelFormatTypeKey ] ;
    [ number release ] ;
    
	[ output setVideoSettings : dict ] ;
    [ output setSampleBufferDelegate : self queue : dispatch_get_current_queue() ] ;
    [ dict release ] ;

    [ captureSession addInput : input ] ;
    [ captureSession addOutput : output ] ;
    
    [ input release ] ;
    [ output release ] ;
    
    NSString* deviceName = [ NSString stringWithUTF8String : machineName() ] ;
    
    if( [ deviceName isEqualToString : @"iPhone2,1" ] || [ deviceName isEqualToString : @"iPhone3,1" ] )
    {
        dMax_FPS = 15 ;
    }
    
    // Connection ;
    for( nInx = 0, nCnt = [ [ output connections ] count ] ; nInx < nCnt ; nInx ++ )
    {
        connection  = [ [ output connections ] objectAtIndex : nInx ] ;
        
        if( connection.supportsVideoMinFrameDuration )
        {
            connection.videoMinFrameDuration = CMTimeMake( 1, dMax_FPS ) ;
        }
        
        if( connection.supportsVideoMaxFrameDuration )
        {
            connection.videoMaxFrameDuration = CMTimeMake( 1, dMax_FPS ) ;
        }
    }
    
    [ captureSession setSessionPreset : AVCaptureSessionPresetMedium ] ;
    
    events  = [ NSArray arrayWithObjects :
                        AVCaptureSessionRuntimeErrorNotification,
                        AVCaptureSessionErrorKey,
                        AVCaptureSessionDidStartRunningNotification,
                        AVCaptureSessionDidStopRunningNotification,
                        AVCaptureSessionWasInterruptedNotification,
                        AVCaptureSessionInterruptionEndedNotification,
                        nil ] ;
    
    for( event in events )
    {
        [ [ NSNotificationCenter defaultCenter ] addObserver : self selector : @selector( eventHandler : ) name : event object : nil ] ;
    }
    
    [ NSTimer scheduledTimerWithTimeInterval : 0.05 target:self selector : @selector( startCamera ) userInfo : nil repeats : NO ] ;
}

- ( void ) realCaptureOutput : ( id ) _pixData
{
    NSData*             data            = ( NSData* )_pixData ;
    
    CMSampleBufferRef   sampleBuffer    = ( CMSampleBufferRef )[ data bytes ] ;
    CVImageBufferRef    imgBuffer       = CMSampleBufferGetImageBuffer( sampleBuffer ) ;
    CFRetain( imgBuffer ) ;
    CVPixelBufferRef    pixBuffer       = imgBuffer ;
    
    int nWidth  = CVPixelBufferGetWidth( pixBuffer ) ;
    int nHeight = CVPixelBufferGetHeight( pixBuffer ) ;
	
    if( nWidth == 0 && !restartCamera )
    {
        restartCamera = true ;
        [ captureSession stopRunning ] ;
        [ NSTimer scheduledTimerWithTimeInterval : 1.0 target : self selector : @selector( startCamera ) userInfo : nil repeats : NO ] ;
        return ;
    }
    
    if( loading == NO )
    {
        // PointCloud Create ;
        pointcloud_create( cameraView.bounds.size.width,
                           cameraView.bounds.size.height,
                           nWidth,
                           nHeight,
                           POINTCLOUD_BGRA_8888,
                           machineName(),
                           "5aa95e2c-aaed-41da-b0e5-88307aae0270" ) ;
        
        // Init ;
        loading = YES ;
        running = YES ;
        context = pointcloud_get_context() ;
	    
        pointcloud_reset() ;
        pointcloud_disable_map_expansion() ;
        
        pointcloud_add_image_target( "image_1", [ [ [ NSBundle mainBundle ] pathForResource : @"image_target_1" ofType : @"model" ] UTF8String ], 0.3, -1 ) ;
        pointcloud_add_image_target( "image_2", [ [ [ NSBundle mainBundle ] pathForResource : @"image_target_2" ofType : @"model" ] UTF8String ], 0.3, -1 ) ;
        pointcloud_add_image_target( "8ninths_businesscard_back", [ [ [ NSBundle mainBundle ] pathForResource : @"8ninths_businesscard_back" ofType : @"model" ] UTF8String ], 0.3, -1 ) ;        
        
        pointcloud_activate_image_target( "image_1" ) ;
        pointcloud_activate_image_target( "image_2" ) ;
        pointcloud_activate_image_target( "8ninths_businesscard_back" ) ;        

        [ self setupGraphics ] ;
        [ self initLighting ] ;
    }
    
	pixelBuffer = pixBuffer ;
	
    [ cameraView drawView ] ;
	
    pixelBuffer = nil ;
	
    CFRelease( imgBuffer ) ;
}

- ( void ) eventHandler : ( id ) _data
{
    if( [ [ _data name ] isEqualToString : @"AVCaptureSessionRuntimeErrorNotification" ] )
    {
		[ NSTimer scheduledTimerWithTimeInterval : 0.1 target : self selector : @selector( restartCamera ) userInfo : nil repeats : NO ] ;
        return ;
    }
    
    if( [ [ _data name ] isEqualToString : @"AVCaptureSessionInterruptionEndedNotification" ] )
    {
        [ captureSession startRunning ] ;
        return ;
    }
}

- ( void ) startCamera
{
	restartCamera = NO ;
    
    if( [ captureSession isRunning ] == NO )
    {
        [ captureSession startRunning ] ;
    }
}

- ( void ) restartCamera
{
	if( restartCamera )
    {
        return ;
    }
 
    restartCamera = YES ;        
    
    if( [ captureSession isRunning ] )
    {
        [ captureSession stopRunning ] ;
    }
    
    [ self startCamera ] ;
}

- ( void ) stopCamera
{
    restartCamera = NO ;
    
    if( [ captureSession isRunning ] )
    {
        [ captureSession stopRunning ] ;
    }
}

#pragma mark - OpenGL
- ( void ) setupGraphics
{
	glViewport( 0, 0, context.viewport_width * scaleFactor, context.viewport_height * scaleFactor ) ;
    
//  [ self loadTrackPoints ] ;

	[ self setupVideoTexture ] ;
	[ self switchToOrtho ] ;
}

- ( void ) setupVideoTexture
{
    int nInx = 0 ;
    
	assert( context.video_format == POINTCLOUD_BGRA_8888 ) ;
	
	videoTexture = create_texture( NULL, context.video_width, context.video_height, true, GL_BGRA ) ;
    
	// Setup geometry for the video overlay
	vertices[ 0 ] = 0 ;
	vertices[ 1 ] = context.viewport_height ;
	vertices[ 2 ] = context.viewport_width ;
	vertices[ 3 ] = context.viewport_height ;
	vertices[ 4 ] = context.viewport_width ;
	vertices[ 5 ] = 0 ;
	vertices[ 6 ] = 0 ;
	vertices[ 7 ] = 0 ;
	
	texcoords[ 0 ] = context.video_width  - context.video_crop_x ;
	texcoords[ 1 ] = context.video_height - context.video_crop_y ;
	texcoords[ 2 ] = context.video_width  - context.video_crop_x ;
	texcoords[ 3 ] = context.video_crop_y ;
	texcoords[ 4 ] = context.video_crop_x ;
	texcoords[ 5 ] = context.video_crop_y ;
	texcoords[ 6 ] = context.video_crop_x ;
	texcoords[ 7 ] = context.video_height - context.video_crop_y ;
    
	for( nInx = 0 ; nInx < 8 ; nInx += 2 )
    {
		texcoords[ nInx + 0 ] /= context.video_width ;
		texcoords[ nInx + 1 ] /= context.video_height ;
	}
}

- ( void ) switchToOrtho
{
	[ self disableLighting ] ;
	
	glDisable( GL_DEPTH_TEST ) ;
    
    // Projection Matrix ;
	glMatrixMode( GL_PROJECTION ) ;
	glLoadIdentity() ;

    // Ortho ;
    glOrthof( 0, context.viewport_width, context.viewport_height, 0, -1, 1 ) ;
    
    // Camera Matrix ;
	glMatrixMode( GL_MODELVIEW ) ;
	glLoadIdentity() ;
}

- ( void ) switchToCamera
{
    [ self enableLighting ] ;
	
	glShadeModel( GL_SMOOTH ) ;
	
    glDisable( GL_BLEND ) ;
    
	glEnable( GL_DEPTH_TEST ) ;
	
	// Projection Matrix ;
	glMatrixMode( GL_PROJECTION ) ;
	glLoadMatrixf( projectMatrix.data ) ;
    
	// Camera Matrix ;
	glMatrixMode( GL_MODELVIEW ) ;
	glLoadMatrixf( cameraMatrix.data ) ;
}

- ( void ) initLighting
{
    float light_ambient[ 4 ]    = { 1.0f, 1.0f, 1.0f, 1.0f } ;
	float light_diffuse[ 4 ]    = { 1.0f, 1.0f, 1.0f, 1.0f } ;
	float light_specular[ 4 ]   = { 1.0f, 1.0f, 1.0f, 1.0f } ;
    float light_position[ 4 ]   = { 0.0f, 0.0f, -1.0f, 0 } ;
    
	glLightfv( GL_LIGHT0, GL_AMBIENT, light_ambient ) ;
	glLightfv( GL_LIGHT0, GL_DIFFUSE, light_diffuse ) ;
	glLightfv( GL_LIGHT0, GL_SPECULAR, light_specular ) ;
    glLightfv( GL_LIGHT0, GL_POSITION, light_position ) ;
}

- ( void ) enableLighting
{
	glEnable( GL_LIGHTING ) ;
	glEnable( GL_LIGHT0 ) ;
}

- ( void ) disableLighting
{
	glDisable( GL_LIGHT0 ) ;
	glDisable( GL_LIGHTING ) ;
}

- ( void ) loadCameraTexture : ( char* ) _data
{	
	if( !_data )
	{
        return ;
    }
    
	glBindTexture( GL_TEXTURE_2D, videoTexture ) ;
    
	assert( context.video_format == POINTCLOUD_BGRA_8888 ) ;
	glTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, context.video_width, context.video_height, GL_BGRA, GL_UNSIGNED_BYTE, _data ) ;
}

- ( void ) processCameraFrame : ( char* ) _data
{
	pointcloud_on_camera_frame( _data ) ;
	
	cameraMatrix      = pointcloud_get_camera_matrix() ;
	projectMatrix     = pointcloud_get_frustum( 0.1, 100 ) ;
}

- ( void ) renderCameraFrame
{
    [ self switchToOrtho ] ;
	
	glClear( GL_DEPTH_BUFFER_BIT ) ;
	
	glBindTexture( GL_TEXTURE_2D, videoTexture ) ;
    
	glDisable( GL_DEPTH_TEST ) ;
	glEnable( GL_TEXTURE_2D ) ;
	
	glEnableClientState( GL_VERTEX_ARRAY ) ;
	glEnableClientState( GL_TEXTURE_COORD_ARRAY ) ;
    
    glColor4f( 1.0, 1.0, 1.0, 1.0 ) ;
	glVertexPointer( 2, GL_FLOAT, 0, vertices ) ;
	glTexCoordPointer( 2, GL_FLOAT, 0, texcoords ) ;
	glDrawArrays( GL_TRIANGLE_FAN, 0, 4 ) ;
	
	glDisableClientState( GL_TEXTURE_COORD_ARRAY ) ;
	glDisableClientState( GL_VERTEX_ARRAY ) ;
	
	glDisable( GL_TEXTURE_2D ) ;
	glEnable( GL_DEPTH_TEST ) ;
}

- ( void ) renderPointCloud
{
    pointcloud_state state = pointcloud_get_state() ;
    pointcloud_point_cloud* points = NULL ;
    
	if( state == POINTCLOUD_INITIALIZING || state == POINTCLOUD_TRACKING_SLAM_MAP )
    {
        if( ( points = pointcloud_get_points() ) )
        {
            [ self switchToCamera ] ;
            [ self disableLighting ] ;
            
            // Draw Point Cloud ;
            glDisable( GL_DEPTH_TEST ) ;
            
            glColor4f( 0.9, 0.95, 1.0, 0.6 ) ;
            
            glEnable( GL_POINT_SPRITE_OES ) ;
            glEnable( GL_TEXTURE_2D ) ;
            
            glEnable( GL_BLEND ) ;
            glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA ) ;
            
            glBindTexture( GL_TEXTURE_2D, pointTexture ) ;
            
            glTexEnvi( GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE ) ;
            
            glPointParameterf( GL_POINT_SIZE_MAX, 64.0f ) ;
            
            glPointSize( 32.0 ) ;
            glEnableClientState( GL_VERTEX_ARRAY ) ;
            glVertexPointer( 3,GL_FLOAT,0, ( float* )points->points ) ;
            glDrawArrays( GL_POINTS,0, points->size ) ;
            glDisableClientState( GL_VERTEX_ARRAY ) ;
            
            glColor4f( 1, 1, 1, 1 ) ;
            
            glPointSize( 1 ) ;
            
            glDisable( GL_BLEND ) ;
            glDisable( GL_TEXTURE_2D ) ;
            glDisable( GL_POINT_SPRITE_OES ) ;
            
            pointcloud_destroy_point_cloud( points ) ;
            
            [ self switchToOrtho ] ;
        }
    }
}

- ( void ) renderContent
{
    pointcloud_state state = pointcloud_get_state() ;
    
	if( state == POINTCLOUD_TRACKING_SLAM_MAP || state == POINTCLOUD_TRACKING_IMAGES )
    {
        [ self switchToCamera ] ;
        
        // Draw Model ;
        if( self.model != nil )
        {
            [ self.model drawModel ] ;
        }
	}
}

- ( void ) renderFrame : ( char* ) _data length : ( int ) _length
{
    // Load Camera ;
    if( running == false )
    {
        return ;
    }

	[ self loadCameraTexture : _data ] ;

    // Precess Camera ;
    if( running == false )
    {
        return ;
    }
	
    [ self processCameraFrame : _data ] ;

    // Render Camera ;
    if( running == false )
    {
        return ;
    }
    
	[ self renderCameraFrame ] ;
    
    // Render Point Cloud ;
    if( running == false )
    {
        return ;
    }
    
	[ self renderPointCloud ] ;

    // Draw Model ;
    if( running == false )
    {
        return ;
    }

	[ self renderContent ] ;
}

#pragma mark - Load
- ( void ) loadModelWithProgress : ( NSString* ) _pathForModel
{
    NSString*   path    = [ [ NSBundle mainBundle ] pathForResource : @"Sennheiser_HD202_(obj)" ofType : @"obj" ] ;
    
    // ProgressBar Show ;
    [ [ MBProgressHUD showHUDAddedTo : self.view animated : YES ] setLabelText : @"Loading Model..." ] ;
    
    // Load Model ;
    [ self performSelector : @selector( loadModel : ) withObject : path afterDelay : 0.1f ] ;
}

- ( void ) loadModel : ( NSString* ) _pathForModel
{
    ObjModel* newModel = nil ;
    
    // Stop Camera ;
    [ self stopCamera ] ;
    
    // Load Model ;
    newModel = [ [ ObjModel alloc ] initWithPath : _pathForModel ] ;
    
    [ self setModel : newModel ] ;
    [ newModel release ] ;
    
    // Start Camera ;
    [ self startCamera ] ;
    
    // ProgressBar Hide ;
    [ MBProgressHUD hideHUDForView : self.view animated : YES ] ;
}

- ( void ) loadTrackPoints
{
    pointTexture = read_png_texture( [ [ [ NSBundle mainBundle ] pathForResource : @"Img - Point" ofType : @"png" ] UTF8String ] ) ;
}

@end