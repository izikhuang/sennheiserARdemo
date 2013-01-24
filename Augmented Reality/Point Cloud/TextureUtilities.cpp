//
//  TextureUtilities.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#include <iostream>
#include <assert.h>

#include "TextureUtilities.h"

// --- Defines --- ;
GLuint create_texture( char* _data, int _width, int _height, bool _pixel_texture, GLenum _texture_format )
{
	const char* extensions      = ( char* )glGetString( GL_EXTENSIONS ) ;
	bool full_npot_supported    = strstr( extensions, "GL_OES_texture_npot" ) != 0 ;
	bool limited_npot_supported = strstr( extensions, "GL_APPLE_texture_2D_limited_npot" ) != 0 ;
    
	assert( full_npot_supported || limited_npot_supported ) ;
	
	bool is_pot = ( ( _width & ( _width - 1 ) ) == 0 ) && ( ( _height & ( _height - 1 ) ) == 0 ) ;
	bool limit  = !is_pot && !full_npot_supported ;

	GLenum internal_format = _texture_format == GL_BGRA_EXT ? GL_RGBA : _texture_format ;
	GLuint texture_object ;

	// Create texture and set up parameters
	glGenTextures( 1, &texture_object ) ;
	glBindTexture( GL_TEXTURE_2D, texture_object ) ;
	glTexImage2D( GL_TEXTURE_2D, 0, internal_format, _width, _height, 0, _texture_format, GL_UNSIGNED_BYTE, _data ) ;
	
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _pixel_texture ? GL_NEAREST : GL_LINEAR ) ;
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR ) ;
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, limit ? GL_CLAMP_TO_EDGE : GL_REPEAT ) ;
	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, limit ? GL_CLAMP_TO_EDGE : GL_REPEAT ) ;
	glTexParameteri( GL_TEXTURE_2D, GL_GENERATE_MIPMAP, _pixel_texture || limit ? GL_FALSE : GL_TRUE ) ;
	
    return texture_object ;
}

GLuint read_png_texture( const char* name, bool pixel_texture )
{
	int     width   = 0 ; 
	int     height  = 0 ;
	char*   data    = NULL ;
	
	bool success = read_png_image( name, &data, &width, &height ) ;
	
	if( !success )
    {
		return 0 ;
    }
	
	GLuint texture_object = create_texture( data, width, height, pixel_texture ) ;
	delete data ;
	
	return texture_object ;
}

/*
 * Draws an image (texture) to the screen given position, dimensions and texture coordinates
 */
void draw_image( GLuint texture_id, double x, double y, double width, double height, double texcoord_x1, double texcoord_y1, double texcoord_x2, double texcoord_y2, double opacity )
{
	
	glEnable( GL_TEXTURE_2D ) ;
	glEnable( GL_BLEND ) ;
	glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA ) ;
	glBindTexture( GL_TEXTURE_2D, texture_id ) ;
	
	float vertices[ 8 ] = { x, y, x+width, y, x+width, y+height, x, y+height } ;
	float texcoords[ 8 ] = { texcoord_x1, texcoord_y1, texcoord_x2, texcoord_y1, texcoord_x2, texcoord_y2, texcoord_x1, texcoord_y2 } ;
	
	glEnableClientState(GL_VERTEX_ARRAY ) ;
	glEnableClientState( GL_TEXTURE_COORD_ARRAY ) ;
	
	glColor4f( 1.0, 1.0, 1.0, opacity ) ;
	glVertexPointer( 2, GL_FLOAT, 0, vertices ) ;
	glTexCoordPointer( 2, GL_FLOAT, 0, texcoords ) ;             
	glDrawArrays( GL_TRIANGLE_FAN, 0, 4 ) ;
	
	glColor4f( 1.0, 1.0, 1.0, 1.0 ) ;
	
	glDisableClientState( GL_TEXTURE_COORD_ARRAY ) ;
	glDisableClientState( GL_VERTEX_ARRAY ) ;
	
	glDisable( GL_BLEND ) ;
	glDisable( GL_TEXTURE_2D ) ;
}