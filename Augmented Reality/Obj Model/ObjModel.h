//
//  ObjModel.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <Foundation/Foundation.h>

#import "ObjCommon.h"
#import "ObjMaterial.h"

// --- Defines --- ;
// ObjModel Class ;
@interface ObjModel : NSObject
{
    // Vertiecs ;
    NSInteger       numOfVertiecs ;
    Vertex3D*       vertices ;
    Vertex3D*       verticesForZoom ;
    
    // Normal ;
    NSInteger       numOfNormals ;
    Vertex3D*       normals ;
    
    // Texcoords ;
    NSInteger       numOfTexcoords ;
	GLfloat*        texcoords ;
    
    // Zoom ;
    Vertex3D        zoomInfo ;
    
    Vertex3D        minVertex ;
    Vertex3D        maxVertex ;
    Vertex3D        transform ;
}

// Properties ;
@property ( nonatomic, retain ) NSString*       objPath ;
@property ( nonatomic, retain ) NSString*       mtlPath ;
@property ( nonatomic, retain ) NSDictionary*   materials ;
@property ( nonatomic, retain ) NSMutableArray* groups ;

// Functions ;
- ( id ) initWithPath : ( NSString* ) _path ;

- ( void ) drawModel ;

- ( void ) setMaterial : ( NSString* ) _materialPath ;
- ( void ) zoomOut ;
- ( void ) zoomIn ;

@end