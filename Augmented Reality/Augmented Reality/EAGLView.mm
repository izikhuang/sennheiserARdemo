//
//  EAGLView.cpp
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <UIKit/UIKit.h>

#import "EAGLView.h"

// --- Defines --- ;
// EAGLView Class ;
@interface EAGLView ( Private ) 

- ( BOOL ) createFramebuffer ;
- ( void ) deleteFramebuffer ;

@end

@implementation EAGLView

// Properties ;
@synthesize delegate ;
@synthesize context ;

// Functions ;
#pragma mark - Shared Funtions
+ ( Class ) layerClass
{
    return [ CAEAGLLayer class ] ;
}

#pragma mark - View
- ( id ) initWithCoder : ( NSCoder* ) _coder
{
    CAEAGLLayer*    eaglLayer = nil ;
    
    self = [ super initWithCoder : _coder ] ;
    
	if( self )
    {
        eaglLayer                       = ( CAEAGLLayer* )( self.layer ) ;
        eaglLayer.opaque                = YES ;
        eaglLayer.drawableProperties    = [ NSDictionary dictionaryWithObjectsAndKeys : [ NSNumber numberWithBool : FALSE ],
                                                kEAGLDrawablePropertyRetainedBacking,
                                                kEAGLColorFormatRGBA8,
                                                kEAGLDrawablePropertyColorFormat,
                                                nil ] ;
        
        self.contentScaleFactor         = [ UIScreen mainScreen ].scale ;
        context                         = [ [ EAGLContext alloc ] initWithAPI : kEAGLRenderingAPIOpenGLES1 ] ;
        
		if( !context || ![ EAGLContext setCurrentContext : context ] )
        {
            [ context release ] ;
			return nil ;
        }
    }
    
    return self ;
}

- ( void ) dealloc
{
    if( [ EAGLContext currentContext ] == context ) 
    {
        [ EAGLContext setCurrentContext : nil ] ;
    }
 
    [ context release ] ;
    
    [ super dealloc ] ;
}

- ( void ) layoutSubviews
{
    [ EAGLContext setCurrentContext : context ] ;
    
    // Delete ;
    [ self deleteFramebuffer ] ;
    
    // Create and Draw ;
    [ self createFramebuffer ] ;
    [ self drawView ] ;
}

#pragma mark - OpenGL
- ( BOOL ) createFramebuffer
{
    // Render Buffer ;
    glGenRenderbuffersOES( 1, &renderBuffer ) ;
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, renderBuffer ) ;
    [ context renderbufferStorage : GL_RENDERBUFFER_OES fromDrawable : ( CAEAGLLayer* )self.layer ] ;

    // Frame Buffer ;
    glGenFramebuffersOES( 1, &frameBuffer ) ;
    glBindFramebufferOES( GL_FRAMEBUFFER_OES, frameBuffer ) ;
    glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, renderBuffer ) ;
    
    glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &frameWidth ) ;
    glGetRenderbufferParameterivOES( GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &frameHeight ) ;
    
    glGenRenderbuffersOES( 1, &depthBuffer ) ;
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, depthBuffer ) ;
    glRenderbufferStorageOES( GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT24_OES, frameWidth, frameHeight ) ;
    glFramebufferRenderbufferOES( GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthBuffer ) ;
    
    if( glCheckFramebufferStatusOES( GL_FRAMEBUFFER_OES ) != GL_FRAMEBUFFER_COMPLETE )
    {
        return NO ;
    }
    
    [ delegate setupView : self ] ;
    return YES ;
}

- ( void ) deleteFramebuffer
{
    glDeleteFramebuffersOES( 1, &frameBuffer ) ;
    frameBuffer = 0 ;

    glDeleteRenderbuffersOES( 1, &renderBuffer ) ;
    renderBuffer = 0 ;

    glDeleteRenderbuffersOES( 1, &depthBuffer ) ;
    depthBuffer = 0 ;
}

- ( void ) drawView
{
    glBindFramebufferOES( GL_FRAMEBUFFER_OES, frameBuffer ) ;
	[ delegate drawView : self ] ;
    glBindRenderbufferOES( GL_RENDERBUFFER_OES, renderBuffer ) ;
	[ context presentRenderbuffer : GL_RENDERBUFFER_OES ] ;
}

@end
