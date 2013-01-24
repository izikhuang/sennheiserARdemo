//
//  ObjMaterial.m
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import "ObjMaterial.h"

// --- Defines --- ;
// ObjMaterial Class ;
@implementation ObjMaterial

// Properties ;
@synthesize name ;
@synthesize diffuse ;
@synthesize ambient ;
@synthesize specular ;
@synthesize shininess ;
@synthesize texture ;

// Functions ;
#pragma mark - Shared Functions
+ ( id ) defaultMaterial
{
	return [ [ ObjMaterial alloc ] initWithName : @"default" shininess : 65.0 diffuse : Color3DMake( 0.8, 0.8, 0.8, 1.0 ) ambient : Color3DMake( 0.2, 0.2, 0.2, 1.0 ) specular : Color3DMake( 0.0, 0.0, 0.0, 1.0 ) ] ;
}

+ ( id ) materialsFromMtlFile : ( NSString* ) _path
{
    // File ;
    NSString*       fileString      = [ NSString stringWithContentsOfFile : _path encoding : NSUTF8StringEncoding error : nil ] ;
    
    // Line ;
    NSScanner*      lineScanner     = [ NSScanner scannerWithString : fileString ] ;
    NSString*       lineString      = nil ;
    
    // Type ;
    NSScanner*      scanner         = nil ;
    NSString*       string          = nil ;
    
    // Material ;
    ObjMaterial*    material        = nil ;

    // Color ;
    GLfloat         red ;
    GLfloat         green ;
    GLfloat         blue ;
    
    // Shininess ;
    GLfloat         shininess ;
    
    // Texture ;
    NSString*       texturePath     = nil ;
    ObjTexture*     texture         = nil ;
    
    // Materials ;
    NSMutableDictionary* materials = [ NSMutableDictionary dictionary ] ;

    // Parse Materials ;
    while( ![ lineScanner isAtEnd ] )
    {
        // Line ;
        [ lineScanner scanUpToCharactersFromSet : [ NSCharacterSet newlineCharacterSet ] intoString : &lineString ] ;
        
        // Type ;
        scanner = [ NSScanner scannerWithString : lineString ] ;
        [ scanner scanUpToCharactersFromSet : [ NSCharacterSet whitespaceCharacterSet ] intoString : &string ] ;
        
        if( [ string isEqualToString : @"newmtl" ] )
        {
            // Material ;
            [ scanner scanUpToCharactersFromSet : [ NSCharacterSet newlineCharacterSet ] intoString : &string ] ;
            
            material            = [ [ ObjMaterial alloc ] init ] ;
            material.name       = string ;
            
            // Add ;
            [ materials setObject : material forKey : material.name ] ;
            [ material release ] ;
        }
        else if( [ string isEqualToString : @"Ka" ] )
        {
            // Ambient ;
            [ scanner scanFloat : &red ] ;
            [ scanner scanFloat : &green ] ;
            [ scanner scanFloat : &blue ] ;
            
            material.ambient    = Color3DMake( red, green, blue, 1.0f ) ;
        }
        else if( [ string isEqualToString : @"Kd" ] )
        {
            // Diffuse ;
            [ scanner scanFloat : &red ] ;
            [ scanner scanFloat : &green ] ;
            [ scanner scanFloat : &blue ] ;
            
            material.diffuse    = Color3DMake( red, green, blue, 1.0f ) ;
        }
        else if( [ string isEqualToString : @"Ks" ] )
        {
            // Specular ;
            [ scanner scanFloat : &red ] ;
            [ scanner scanFloat : &green ] ;
            [ scanner scanFloat : &blue ] ;
            
            material.specular   = Color3DMake( red, green, blue, 1.0f ) ;
        }
        else if( [ string isEqualToString : @"Tr" ] )
        {
            
        }
        else if( [ string isEqualToString : @"illum" ] )
        {
            
        }
        else if( [ string isEqualToString : @"Ns" ] )
        {
            // Shininess ;
            [ scanner scanFloat : &shininess ] ;
            
            material.shininess  = shininess ;
        }
        else if( [ string isEqualToString : @"map_Kd" ] )
        {
            // Texture ;
            [ scanner scanUpToCharactersFromSet : [ NSCharacterSet newlineCharacterSet ] intoString : &string ] ;
            
            texturePath = [ [ _path stringByDeletingLastPathComponent ] stringByAppendingPathComponent : string ] ;
            texture     = [ [ ObjTexture alloc ] initWithFilename : texturePath
                                                            width : 0
                                                           height : 0 ] ;
            
            material.texture = texture ;
            [ texture release ] ;
        }
    }
    
	return materials ;
}

#pragma mark - Material
- ( id ) initWithName : ( NSString* ) _name shininess : ( GLfloat ) _shininess diffuse : ( Color3D ) _diffuse ambient : ( Color3D ) _ambient specular : ( Color3D ) _specular
{
	return [ self initWithName : _name shininess : _shininess diffuse : _diffuse ambient : _ambient specular : _specular texture : nil ] ;
}

- ( id ) initWithName : ( NSString* ) _name shininess : ( GLfloat ) _shininess diffuse : ( Color3D ) _diffuse ambient : ( Color3D ) _ambient specular : ( Color3D ) _specular texture : ( ObjTexture* ) _texture
{
	if( ( self = [ super init ] ) )
	{
		self.name       = ( _name == nil ) ? @"default" : _name ;
		self.shininess  = _shininess ;
		self.diffuse    = _diffuse ;
		self.ambient    = _ambient ;
		self.specular   = _specular ;
		self.texture    = _texture ;
	}
    
	return self ;
}

- ( void ) dealloc 
{
	[ name release ] ;
	[ texture release ] ;
    
    [ super dealloc ] ;
}

@end
