//
//  PointCloudApplication.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 7/2/12.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
#ifndef POINTCLOUDAPPLICATION_H
#define POINTCLOUDAPPLICATION_H

// --- Headers --- ;
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include <QuartzCore/QuartzCore.h>

#include "PointCloud.h"
#include "TextureUtilities.h"

// --- Defines --- ;
extern bool run_opengl ;

inline double current_time()
{
    return CACurrentMediaTime() ;
}

// PointCloudApplication Class ;
class PointCloudApplication
{
public :
	
    PointCloudApplication( int nViewPortWidth, int nViewPortHeight,
                           int nVideoWidth, int nVideoHeight,
                           pointcloud_video_format nVideoFormat,
                           const char* pszResPath,
                           const char* pszDocPath,
                           const char* pszDevice,
                           double dScale ) ;
    ~PointCloudApplication() ;
	
	// Interface from Objective-C layer
	bool            render_frame( char* pszData, int nLength ) ;

	void            on_accelerometer_update( float dTx, float dTy, float dTz ) ;
	void            on_device_motion_update( float dTx, float dTy, float dTz, float dRx, float dRy, float dRz ) ;

	virtual bool    on_touch_started(double x, double y ) { return false ; }
	virtual bool    on_touch_moved( double x, double y ) { return false ; }
	virtual bool    on_touch_ended( double x, double y ) { return false ; }
	virtual bool    on_touch_cancelled( double x, double y ) { return false ; }
	
	void            on_pause() ;
	void            on_resume() ;

protected :

	// Switch to orthogonal projection (for UI etc)
	virtual void    switch_to_ortho() ;
	
	// Switch to camera projection
	virtual void    switch_to_camera() ;
	
	// Add a simple light to the scene
	virtual void    init_lighting() ;
	virtual void    enable_lighting() ;
	virtual void    disable_lighting() ;

	virtual void    render_point_cloud();
	virtual void    render_content( double time_since_last_frame ) ;
	
	void            setup_graphics() ;
	void            load_camera_texture( char* pszData ) ;
	void            process_camera_frame( char* pszData ) ;
	void            setup_video_texture();
	void            render_camera_frame();
	void            draw_logo();
	void            clean_up();

protected :

	bool            bRunning ;
	double          dScaleFactor ;
	
    pointcloud_context stContext ;
	
    pointcloud_matrix_4x4 stCameraMatrix ;
	pointcloud_matrix_4x4 stProjectMatrix ;
    
	const char*     pszStrResource ;
	pointcloud_state nLastState ;
	


	GLuint          nVideoTexture ;
	
	float           adVertex[ 8 ] ;
	float           adTexcoord[ 8 ] ;
	
	double          dLastFrameClock ;
} ;

#endif
