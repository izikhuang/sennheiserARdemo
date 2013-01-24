//
//  ObjMaterial.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <Foundation/Foundation.h>

#import "ObjCommon.h"
#import "ObjTexture.h"

// --- Defines --- ;
// ObjMaterial Class ;
@interface ObjMaterial : NSObject

// Properties ;
@property ( nonatomic, retain ) NSString*           name ;
@property                       GLfloat             shininess ;
@property                       Color3D             diffuse ;
@property                       Color3D             ambient ;
@property                       Color3D             specular ;
@property ( nonatomic, retain ) ObjTexture*         texture ;

// Functions ;
+ ( id ) defaultMaterial ;
+ ( id ) materialsFromMtlFile : ( NSString* ) _path ;

- ( id ) initWithName : ( NSString* ) _name shininess : ( GLfloat ) _shininess diffuse : ( Color3D ) _diffuse ambient : ( Color3D ) _ambient specular : ( Color3D ) _specular ;
- ( id ) initWithName : ( NSString* ) _name shininess : ( GLfloat ) _shininess diffuse : ( Color3D ) _diffuse ambient : ( Color3D ) _ambient specular : ( Color3D ) _specular texture : ( ObjTexture* ) _texture ;

@end
