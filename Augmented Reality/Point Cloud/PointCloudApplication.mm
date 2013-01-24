//
//  PointCloudApplication.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 7/2/12.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#include <cassert>
#include <string>

#include "PointCloudApplication.h"

// --- Defines --- ;
// PointCloudApplication Class ;
PointCloudApplication::PointCloudApplication( int nViewPortWidth, int nViewPortHeight,
                                              int nVideoWidth, int nVideoHeight,
                                              pointcloud_video_format nVideoFormat,
                                              const char* pszResPath,
                                              const char* pszDocPath,
                                              const char* pszDevice,
                                              double dScale )
{
    // PointCloud Create ;
	pointcloud_create( nViewPortWidth, nViewPortHeight,
                       nVideoWidth, nVideoHeight,
                       nVideoFormat,		
                       pszDevice, 
                       "e474d362-9c39-4966-bcb0-5c3d3698caa1" ) ;

    // Init ;
	bRunning            = true ;
	dScaleFactor        = dScale ;
	nVideoTexture       = 0 ;
	dLastFrameClock     = current_time() ;
	stContext           = pointcloud_get_context() ;
	pszStrResource      = pszResPath ;
	    
	setup_graphics() ;
	init_lighting() ;

	std::string image_target_1_path = pszResPath + std::string( "image_target_1.model" ) ;
    std::string image_target_2_path = pszResPath + std::string( "image_target_2.model" ) ;
    
    pointcloud_add_image_target( "image_1", image_target_1_path.c_str(), 0.3, -1 ) ;
    pointcloud_add_image_target( "image_2", image_target_2_path.c_str(), 0.3, -1 ) ;
    
    pointcloud_reset() ;
    pointcloud_disable_map_expansion() ;
    pointcloud_activate_image_target( "image_1" ) ;
    pointcloud_activate_image_target( "image_2" ) ;
    
//  pointcloud_start_slam() ;
}

PointCloudApplication::~PointCloudApplication()
{
    
}

void PointCloudApplication::setup_graphics()
{
	glViewport( 0, 0, stContext.viewport_width * dScaleFactor, stContext.viewport_height * dScaleFactor ) ;
    
	setup_video_texture() ;
	switch_to_ortho() ;
}

void PointCloudApplication::setup_video_texture()
{
    int nInx = 0 ;
    
	assert( stContext.video_format == POINTCLOUD_BGRA_8888 ) ;
	
	nVideoTexture = create_texture( NULL, stContext.video_width, stContext.video_height, true, GL_BGRA ) ;

	// Setup geometry for the video overlay
	adVertex[ 0 ] = 0 ;
	adVertex[ 1 ] = stContext.viewport_height ;
	adVertex[ 2 ] = stContext.viewport_width ;
	adVertex[ 3 ] = stContext.viewport_height ;
	adVertex[ 4 ] = stContext.viewport_width ;
	adVertex[ 5 ] = 0 ;
	adVertex[ 6 ] = 0 ;
	adVertex[ 7 ] = 0 ;
	
	adTexcoord[ 0 ] = stContext.video_width  - stContext.video_crop_x ;
	adTexcoord[ 1 ] = stContext.video_height - stContext.video_crop_y ;
	adTexcoord[ 2 ] = stContext.video_width  - stContext.video_crop_x ;
	adTexcoord[ 3 ] = stContext.video_crop_y ;
	adTexcoord[ 4 ] = stContext.video_crop_x ;
	adTexcoord[ 5 ] = stContext.video_crop_y ;
	adTexcoord[ 6 ] = stContext.video_crop_x ;
	adTexcoord[ 7 ] = stContext.video_height - stContext.video_crop_y ;

	for( nInx = 0 ; nInx < 8 ; nInx += 2 )
    {
		adTexcoord[ nInx + 0 ] /= stContext.video_width ;
		adTexcoord[ nInx + 1 ] /= stContext.video_height ;
	}
}

void PointCloudApplication::switch_to_ortho()
{
	disable_lighting() ;
	
	glDisable( GL_DEPTH_TEST ) ;
	glMatrixMode( GL_PROJECTION ) ;
	glLoadIdentity() ;
	glOrthof( 0, stContext.viewport_width, stContext.viewport_height, 0, -1, 1 ) ;
	glMatrixMode( GL_MODELVIEW ) ;
	glLoadIdentity() ;
}

void PointCloudApplication::switch_to_camera()
{
	enable_lighting() ;
	
	glShadeModel( GL_SMOOTH ) ;
	
	glDisable( GL_BLEND ) ;
	glDisable( GL_TEXTURE_2D ) ;
	
	glEnable( GL_DEPTH_TEST ) ;
	
	// Set up projection matrix
	glMatrixMode( GL_PROJECTION ) ;
	glLoadMatrixf( stProjectMatrix.data ) ;
    
	// Set up camera matrix
	glMatrixMode( GL_MODELVIEW ) ;
	glLoadMatrixf( stCameraMatrix.data ) ;
}

void PointCloudApplication::init_lighting()
{
	float light_ambient[ 4 ]    = { 0.2f, 0.2f, 0.2f, 1.0f } ;
	float light_diffuse[ 4 ]    = { 1.0f, 1.0f, 1.0, 1.0f } ;
	float light_specular[ 4 ]   = { 1.0f, 1.0f, 1.0f, 1.0f } ;
	float light_position[ 4 ]   = { 1, -6, 0.5, 1.0f } ;
	
	// Assign created components to GL_LIGHT0
	glLightfv( GL_LIGHT0, GL_AMBIENT, light_ambient ) ;
	glLightfv( GL_LIGHT0, GL_DIFFUSE, light_diffuse ) ;
	glLightfv( GL_LIGHT0, GL_SPECULAR, light_specular ) ;
	
	glPushMatrix() ;
	glLoadIdentity() ;
	glLightfv( GL_LIGHT0, GL_POSITION, light_position ) ;
	glPopMatrix() ;
}

void PointCloudApplication::enable_lighting()
{
	glEnable( GL_LIGHTING ) ;
	glEnable( GL_LIGHT0 ) ;
}

void PointCloudApplication::disable_lighting()
{
	glDisable( GL_LIGHTING ) ;
	glDisable( GL_LIGHT0 ) ;
}

void PointCloudApplication::load_camera_texture( char* pszData )
{	
	if( !pszData )
	{
        return ;
    }

	glBindTexture( GL_TEXTURE_2D, nVideoTexture ) ;

	assert( stContext.video_format == POINTCLOUD_BGRA_8888 ) ;
	glTexSubImage2D( GL_TEXTURE_2D, 0, 0, 0, stContext.video_width, stContext.video_height, GL_BGRA, GL_UNSIGNED_BYTE, pszData ) ;
}

void PointCloudApplication::render_camera_frame()
{
	switch_to_ortho() ;
	
	//glClearColor(0.0, 0.0, 0.0, 1.0);
	glClear( /*GL_COLOR_BUFFER_BIT | */GL_DEPTH_BUFFER_BIT ) ;
	
	glBindTexture( GL_TEXTURE_2D, nVideoTexture ) ;

	glEnable( GL_TEXTURE_2D ) ;
	glDisable( GL_DEPTH_TEST ) ;
	
	glEnableClientState( GL_VERTEX_ARRAY ) ;
	glEnableClientState( GL_TEXTURE_COORD_ARRAY ) ;
	
	glColor4f( 1.0, 1.0, 1.0, 1.0 ) ;
	glVertexPointer( 2, GL_FLOAT, 0, adVertex ) ;
	glTexCoordPointer( 2, GL_FLOAT, 0, adTexcoord ) ;
	glDrawArrays( GL_TRIANGLE_FAN, 0, 4 ) ;
	
	glDisableClientState( GL_TEXTURE_COORD_ARRAY ) ;
	glDisableClientState( GL_VERTEX_ARRAY ) ;
	
	glDisable( GL_TEXTURE_2D ) ;
	glEnable( GL_DEPTH_TEST ) ;
}

void PointCloudApplication::clean_up()
{
    
}

void PointCloudApplication::on_pause()
{
	bRunning    = true ;
}

void PointCloudApplication::on_resume()
{
	bRunning    = false ;
}

void PointCloudApplication::on_accelerometer_update( float dTx, float dTy, float dTz )
{
	pointcloud_on_accelerometer_update( dTx, dTy, dTz ) ;
}

void PointCloudApplication::on_device_motion_update( float dTx, float dTy, float dTz, float dRx, float dRy, float dRz )
{
	pointcloud_on_device_motion_update( dTx, dTy, dTz, dRx, dRy, dRz ) ;
}

bool PointCloudApplication::render_frame( char* pszData, int nLength )
{
	if( bRunning == false )
    {
        return false ;        
    }
	
	pointcloud_state nState = pointcloud_get_state() ;
	
	// Timers
	double dNowTime         = current_time() ;
	double dTimeInterval    = dNowTime - dLastFrameClock ;
    
	dLastFrameClock = dNowTime ;
	
    // Load Camera ;
	load_camera_texture( pszData ) ;
    
	if( bRunning == false )
    {
        return false ;        
    }
	
    // Precess Camera ;
	process_camera_frame( pszData ) ;
    
	if( bRunning == false )
    {
        return false ;        
    }
	
    // Render Camera ;
	render_camera_frame() ;
    
	if( bRunning == false )
    {
        return false ;        
    }
	
    // Render Content ;
//	render_point_cloud() ;
    
	if( bRunning == false )
    {
        return false ;        
    }

    render_content( dTimeInterval ) ;
    
    if( bRunning == false )
    {
        return false ;        
    }
    
	clean_up() ;
	
	nLastState = nState ;

    pointcloud_state state = pointcloud_get_state() ;
    
	if( state == POINTCLOUD_TRACKING_SLAM_MAP || state == POINTCLOUD_TRACKING_IMAGES )
    {
        switch_to_camera() ;
        return true ;
    }
    
    return false ;
}

void PointCloudApplication::process_camera_frame( char* pszData )
{
	pointcloud_on_camera_frame( pszData ) ;
	
	stCameraMatrix      = pointcloud_get_camera_matrix() ;
	stProjectMatrix     = pointcloud_get_frustum( 0.1, 100 ) ;
}

void PointCloudApplication::render_point_cloud()
{
    pointcloud_state state = pointcloud_get_state() ;
		     
    if( state == POINTCLOUD_INITIALIZING ||
		state == POINTCLOUD_TRACKING_SLAM_MAP )
    {
        pointcloud_point_cloud* points = pointcloud_get_points() ;
		
        if( points )
        {
			switch_to_camera() ;
			disable_lighting() ;

			glDisable( GL_DEPTH_TEST ) ;

            glColor4f( 0.9, 0.95, 1.0, 0.6 ) ;
            
            glEnable( GL_POINT_SPRITE_OES ) ;
            glEnable( GL_TEXTURE_2D ) ;
            
            glEnable( GL_BLEND ) ;
            glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA ) ;
			
/*          GLuint texture ;
            
            glGenTextures( 1, &texture ) ;
            glBindTexture( GL_TEXTURE_2D, texture ) ; */
            
            
//			glBindTexture(GL_TEXTURE_2D, point_texture);

            glTexEnvi( GL_POINT_SPRITE_OES, GL_COORD_REPLACE_OES, GL_TRUE ) ;
            
            glPointParameterf( GL_POINT_SIZE_MAX, 64.0f ) ;
            
			glPointSize( 32.0 ) ;
			glEnableClientState( GL_VERTEX_ARRAY ) ;
            glVertexPointer( 3, GL_FLOAT, 0, ( float* )points->points ) ;
            glDrawArrays( GL_POINTS, 0 , points->size ) ;
			
			glDisableClientState( GL_VERTEX_ARRAY ) ;
            
            glColor4f( 1, 1, 1, 1 ) ;
			
			glPointSize( 1 ) ;

			glDisable( GL_BLEND ) ;
			glDisable( GL_TEXTURE_2D ) ;
			glDisable( GL_POINT_SPRITE_OES ) ;
			
			pointcloud_destroy_point_cloud( points ) ;
			
			switch_to_ortho() ;
        }
    }
}

void PointCloudApplication::render_content( double time_since_last_frame )
{
    float   cuboid_vertices[ 19 ][ 3 ] ;
    float   cuboid_normals[ 19 ][ 3 ] ;
    float   corners[ 8 ][ 3 ] ;
    float   normals[ 6 ][ 3 ] ;
    double  len = 0.2 ;
    
    int     nInx ;
    int     nIdx ;
        
    for( nInx = 0 ; nInx < 8 ; nInx ++ )
    {
        corners[ nInx ][ 0 ] = - len / 2 ;
        corners[ nInx ][ 1 ] = 0 ;
        corners[ nInx ][ 2 ] = - len / 2 ;
    }
    
    for( nInx = 0 ; nInx < 6 ; nInx ++ )
    {
        for( nIdx = 0 ; nIdx < 3 ; nIdx ++ )
        {
            normals[ nInx ][ nIdx ] = 0 ;
        }
    }

    normals[ 0 ][ 0 ] = 0.3 ;
    normals[ 1 ][ 2 ] = 0.3 ;
    normals[ 2 ][ 1 ] = 0.3 ;
    normals[ 3 ][ 0 ] = - 0.3 ;
    normals[ 4 ][ 2 ] = - 0.3 ;
    normals[ 5 ][ 1 ] = - 0.3 ;
		
    corners[ 1 ][ 0 ] = 0.3 ;
    corners[ 2 ][ 0 ] = 0.3 ;
    corners[ 5 ][ 0 ] = 0.3 ;
    corners[ 6 ][ 0 ] = 0.3 ;
        
    corners[ 2 ][ 2 ] = 0.3 ;
    corners[ 3 ][ 2 ] = 0.3 ;
    corners[ 6 ][ 2 ] = 0.3 ;
    corners[ 7 ][ 2 ] = 0.3 ;
    
    corners[ 4 ][ 1 ] += len ;
    corners[ 5 ][ 1 ] += len ;
    corners[ 6 ][ 1 ] += len ;
    corners[ 7 ][ 1 ] += len ;
    
    int strip[] = { 4, 0, 5, 1, 6, 2, 7, 3, 4, 0, 0, 1, 3, 2, 2, 6, 7, 5, 4 } ;
    int side[]  = { 4, 4, 4, 4, 0, 0, 1, 1, 3, 3, 5, 5, 5, 5, 2, 2, 2, 2, 2 } ;
    
    for( nInx = 0 ; nInx < sizeof( strip ) / sizeof( int ) ; nInx ++ )
    {
        int c = strip[ nInx ] ;
        int s = side[ nInx ] ;
        
        for(  nIdx = 0 ; nIdx < 3 ; nIdx ++ )
        {
            cuboid_vertices[ nInx ][ nIdx ] = corners[ c ][ nIdx ] ;
            cuboid_normals[ nInx ][ nIdx ]  = normals[ s ][ nIdx ] ;
        }
    }

//    pointcloud_state state = pointcloud_get_state() ;
	
	// Draw the content if we have SLAM or image tracking
/*	if( state != POINTCLOUD_TRACKING_SLAM_MAP &&
        state != POINTCLOUD_TRACKING_IMAGES )
    {
        return ;
    } */

    switch_to_camera() ;
    
    glDisable( GL_TEXTURE_2D ) ;
	glEnable( GL_COLOR_MATERIAL ) ;
	glShadeModel( GL_FLAT ) ;
	
	glEnableClientState( GL_VERTEX_ARRAY ) ;
	glEnableClientState( GL_NORMAL_ARRAY ) ;

    glColor4f( 1, 0, 0, 1 ) ;

 /*   glVertexPointer( 3, GL_FLOAT, 0, ( float* )cuboid_vertices ) ;
	glNormalPointer( GL_FLOAT, 0, ( float* )cuboid_normals ) ;
	glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 ) ;

    
	glDisableClientState( GL_NORMAL_ARRAY ) ;
	glDisableClientState( GL_VERTEX_ARRAY ) ;
    
	glShadeModel( GL_SMOOTH ) ;
	glDisable( GL_COLOR_MATERIAL ) ;*/
}