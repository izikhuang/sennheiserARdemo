//
//  ObjGroup.m
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import "ObjGroup.h"

// --- Defines --- ;
// ObjGroup Class ;
@implementation ObjGroup

// Properties ;
@synthesize name ;
@synthesize faceData ;
@synthesize material ;

// Functions ;
#pragma mark - Group
- ( id ) initWithName : ( NSString* ) _name
{
	return [ self initWithName : _name material : nil ] ;
}

- ( id ) initWithName : ( NSString* ) _name material : ( ObjMaterial* ) _material
{
    self = [ super init ] ;
    
	if( self )
	{
		self.name           = _name ;
		self.faceData       = [ NSMutableData data ] ;
		self.material       = _material ;
	}
    
	return self ;
}

- ( void ) dealloc
{
	[ name release ] ;
    [ faceData release ] ;
	[ material release ] ;
    
	[ super dealloc ] ;
}

#pragma mark - Material
- ( BOOL ) defaultMaterial
{
    if( self.material && [ self.material.name isEqualToString : @"default" ] )
    {
        return YES ;
    }
    
    return NO ;
}

@end