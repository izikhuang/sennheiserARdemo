//
//  ObjTexture.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>

// --- Defines --- ;
// ObjTexture Class ;
@interface ObjTexture : NSObject

// Properties ;
@property ( nonatomic, retain )  NSString* fileName ;
@property GLuint texture ;

// Functions ;
- ( id ) initWithFilename : ( NSString* ) _fileName width : ( GLuint ) _width height : ( GLuint ) _height ;
- ( void ) bind ;

@end