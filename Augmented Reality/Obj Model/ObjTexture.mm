//
//  ObjTexture.m
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import "ObjTexture.h"
#import "TextureUtilities.h"

// --- Defines --- ;
// ObjTexture Class ;
@interface ObjTexture ( Private )

- ( void ) loadTexture : ( NSString* ) _fileName width : ( GLuint ) _width height : ( GLuint ) _height ;

@end

@implementation ObjTexture

// Properties ;
@synthesize texture ;
@synthesize fileName ;

// Functions ;

#pragma mark - ObjTexture
- ( id ) initWithFilename : ( NSString* ) _fileName width : ( GLuint ) _width height : ( GLuint ) _height
{
	if( ( self = [ super init ] ) )
	{
        [ self loadTexture : _fileName width : _width height : _height ] ;
	}
    
	return self ;
}

- ( void ) dealloc
{
	glDeleteTextures( 1, &texture ) ;
    [ fileName release ] ;
    
	[ super dealloc ] ;
}

#pragma mark - Functions
- ( void ) loadTexture : ( NSString* ) _fileName width : ( GLuint ) _width height : ( GLuint ) _height
{
    self.fileName   = _fileName ;
    self.texture    = read_png_texture( [ _fileName UTF8String ] ) ;
    return ;
    
//  glEnable( GL_TEXTURE_2D ) ;
    
    glGenTextures( 1, &texture ) ;
    glBindTexture( GL_TEXTURE_2D, texture ) ;
    
    NSString*   extension   = [ _fileName pathExtension ] ;
    NSString*   base        = [ [ _fileName componentsSeparatedByString : @"." ] objectAtIndex : 0 ] ;
    NSString*   path        = [ [ NSBundle mainBundle ] pathForResource : base ofType : extension ] ;
    NSData*     texData     = [ NSData dataWithContentsOfFile : path ] ;
    
    // Assumes pvr4 is RGB not RGBA, which is how texturetool generates them
    if( [ extension isEqualToString : @"pvr4" ] )
    {
        glCompressedTexImage2D( GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG, _width, _height, 0, ( _width * _height ) / 2, [ texData bytes ] ) ;
    }
    else if( [ extension isEqualToString : @"pvr2" ] )
    {
        glCompressedTexImage2D( GL_TEXTURE_2D, 0, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG, _width, _height, 0, ( _width * _height ) / 2, [ texData bytes ] ) ;
    }
    else
    {
        UIImage*    image = [ [ UIImage alloc ] initWithData : texData ] ;
        
        if( image == nil )
        {
            return ;
        }
        
        GLuint width    = image.size.width ;
        GLuint height   = image.size.height ;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB() ;
        
        void* imageData = malloc( height * width * 4 ) ;
        
        memset( imageData, 0, height * width * 4 ) ;
        
        CGContextRef context = CGBitmapContextCreate( imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast ) ;
        
        CGContextClearRect( context, CGRectMake( 0, 0, width, height ) ) ;
        CGContextTranslateCTM( context, 0, 0 ) ;
        CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage ) ;
        
        glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData ) ;
        
        CGContextRelease( context ) ;
        CGColorSpaceRelease( colorSpace ) ;
        
        free( imageData ) ;
        [ image release ] ;
    }
    
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE ) ;
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE ) ;
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR ) ;
    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR ) ;
//  glTexParameteri( GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE ) ;
//  glDisable( GL_TEXTURE_2D ) ;
}

- ( void ) bind
{
    glActiveTexture( GL_TEXTURE0 ) ;
	glBindTexture( GL_TEXTURE_2D, texture ) ;
}

@end