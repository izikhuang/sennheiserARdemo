//
//  ARScanController.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreMotion/CoreMotion.h>

#import "EAGLView.h"
#import "PointCloud.h"
#import "ObjModel.h"

// --- Defines --- ;
// ARScanController Class ;
@interface ARScanController : UIViewController < EAGLViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate >
{
    // UI ;
    IBOutlet EAGLView*      cameraView ;
 
    // Camera ;
    BOOL                    restartCamera ;
    BOOL                    accelerometerAvailable ;
    BOOL                    deviceMotionAvailable ;
    
    CVPixelBufferRef        pixelBuffer ;
	CMMotionManager*        motionManager ;
    AVCaptureSession*       captureSession ;
    
    // Point Cloud ;
    BOOL                    loading ;
    BOOL                    running ;
	double                  scaleFactor ;
    
    GLuint                  videoTexture ;
	float                   vertices[ 8 ] ;
	float                   texcoords[ 8 ] ;
    
    GLuint                  pointTexture ;

    pointcloud_context      context ;
    pointcloud_matrix_4x4   cameraMatrix ;
	pointcloud_matrix_4x4   projectMatrix ;
}

// Properties ;
@property ( nonatomic, retain ) ObjModel*   model ;

// Functions ;
+ ( ARScanController* ) sharedController ;

@end