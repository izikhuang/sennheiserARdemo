//
//  ObjGroup.h
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
// ObjGroup Class ;
@interface ObjGroup : NSObject

// Properties ;
@property ( nonatomic, retain ) NSString*       name ;
@property ( nonatomic, retain ) NSMutableData*  faceData ;
@property ( nonatomic, retain ) ObjMaterial*    material ;

// Functions ;
- ( id ) initWithName : ( NSString* ) _name ;
- ( id ) initWithName : ( NSString* ) _name material : ( ObjMaterial* ) _material ;

- ( BOOL ) defaultMaterial ;

@end
