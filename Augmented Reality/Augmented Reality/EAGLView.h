//
//  EAGLView.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

// --- Classes --- ;
@class EAGLContext ;

// --- Defines --- ;
// EAGLViewDelegate Delegate ;
@protocol EAGLViewDelegate

- ( void ) drawView : ( UIView* ) _view ;
- ( void ) setupView : ( UIView* ) _view ;

@end

// EAGLView ;
@interface EAGLView : UIView
{    
@private
    
    GLuint      frameBuffer ;
    GLint       frameWidth ;
    GLint       frameHeight ;
    GLuint      renderBuffer ;
    GLuint      depthBuffer ;
}

// Properties ;
@property ( assign ) id < EAGLViewDelegate >    delegate ;
@property ( strong, nonatomic ) EAGLContext*    context ;

// Functions ;
- ( void ) drawView ;

@end
