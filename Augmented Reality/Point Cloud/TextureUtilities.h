//
//  TextureUtilities.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
#ifndef TEXTUREUTILITIES_H
#define TEXTUREUTILITIES_H

// --- Headers --- ;
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

// --- Defines --- ;
extern "C"
{
    bool read_png_image( const char* filename, char** data, int* width, int* height ) ;
}

GLuint create_texture( char* data, int width, int height, bool pixel_texture = false, GLenum texture_format = GL_RGBA ) ;
GLuint read_png_texture( const char* name, bool pixel_texture = false ) ;
void draw_image( GLuint texture_id, double x, double y, double width, double height, double texcoord_x1, double texcoord_y1, double texcoord_x2, double texcoord_y2, double opacity = 1.0 ) ;

#endif
