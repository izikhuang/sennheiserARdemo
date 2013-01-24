//
//  ObjModel.m
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import "ObjModel.h"
#import "ObjMaterial.h"
#import "ObjGroup.h"

// --- Defines --- ;
// ObjModel Class ;
@interface ObjModel ( Private )

- ( void ) loadModel : ( NSString* ) _path ;

@end

@implementation ObjModel

// Properties ;
@synthesize objPath ;
@synthesize mtlPath ;
@synthesize materials ;
@synthesize groups ;

// Functions ;
#pragma mark - Model ;
- ( id ) initWithPath : ( NSString* ) _path
{
    self = [ super init ] ;
    
	if( self )
	{
        // Zoom ;
        zoomInfo    = Vertex3DMake( 0.05, 0.05, 0.05 ) ;
        
        // Model ;
        [ self loadModel : _path ] ;
	}
    
    return self ;
}

- ( void ) dealloc
{
    [ objPath release ] ;
    [ mtlPath release ] ;
    [ materials release ] ;
    [ groups release ] ;
    
    if( vertices )
    {
        free( vertices ) ;
    }
    
    if( verticesForZoom )
    {
        free( verticesForZoom ) ;
    }
    
    if( normals )
    {
        free( normals ) ;
    }
    
    if( texcoords )
    {
        free( texcoords ) ;
    }
    
    [ super dealloc ] ;
}

- ( void ) loadModel : ( NSString* ) _path
{
    // File ;
    NSString*       fileString      = [ NSString stringWithContentsOfFile : _path encoding : NSUTF8StringEncoding error : nil ] ;

    // Line ;
    NSScanner*      lineScanner     = [ NSScanner scannerWithString : fileString ] ;
    NSString*       lineString      = nil ;

    // Type ;
    NSScanner*      scanner         = nil ;
    NSString*       string          = nil ;
    
    // Vertices ;
    Vertex3D        vertex ;
    NSMutableData*  vertexData      = [ NSMutableData data ] ;
    NSMutableData*  vertexTemp      = [ NSMutableData data ] ;
    
    // Texcoord ;
    GLfloat         texcoord[ 2 ]   = { 0 } ;    
    NSMutableData*  texcoordData    = [ NSMutableData data ] ;
    NSMutableData*  texcoordTemp    = [ NSMutableData data ] ;
    
    // Normal ;
    NSMutableData*  normalData      = [ NSMutableData data ] ;
    NSMutableData*  normalTemp      = [ NSMutableData data ] ;
    
    // Face ;
    NSInteger       uniqueIndex     = 0 ;
    NSInteger       count           = 0 ;
    GLuint          faceIndex       = 0 ;
    NSInteger       vertexIndex     = 0 ;
    NSInteger       texIndex        = 0 ;
    NSInteger       normalIndex     = 0 ;
    NSString*       index           = nil ;
//  NSNumber*       number          = nil ;
    NSArray*        array           = nil ;
//  NSMutableDictionary* indexDict  = [ NSMutableDictionary dictionary ] ;
    
    // Group ;
    ObjGroup*       group           = nil ;
    ObjMaterial*    material        = nil ;

    minVertex   = Vertex3DMake( 9999.9999, 9999.9999, 9999.9999 ) ;
    maxVertex   = Vertex3DMake( -9999.9999, -9999.9999, -9999.9999 ) ;
    
    // Set ;
    [ self setObjPath : _path ] ;
    [ self setGroups : [ NSMutableArray array ] ] ;
    
    // Parse ;
    while( ![ lineScanner isAtEnd ] )
    {
        // Line ;
        [ lineScanner scanUpToCharactersFromSet : [ NSCharacterSet newlineCharacterSet ] intoString : &lineString ] ;
        
/*      while( true )
        {
            NSRange range   = [ lineString rangeOfString : @"\\" ] ;
            
            if( range.length == 0 )
            {
                break ;
            }
            
            NSString*   temp = nil ;
            [ lineScanner scanUpToCharactersFromSet : [ NSCharacterSet newlineCharacterSet ] intoString : &temp ] ;
            
            lineString  = [ lineString substringToIndex : range.location ] ;
            lineString  = [ lineString stringByAppendingFormat : @" %@", temp ] ;
        } */
        
        // Type ;
        scanner = [ NSScanner scannerWithString : lineString ] ;
        [ scanner scanUpToCharactersFromSet : [ NSCharacterSet whitespaceCharacterSet ] intoString : &string ] ;
        
        if( [ string isEqualToString : @"mtllib" ] )
        {
            NSString*       path            = nil ;
            NSDictionary*   dictionary      = nil ;

            // Materials ;
            [ scanner scanUpToCharactersFromSet : [ NSCharacterSet newlineCharacterSet ] intoString : &string ] ;
            
            path        = [ [ self.objPath  stringByDeletingLastPathComponent ] stringByAppendingPathComponent : string ] ;
            dictionary  = [ ObjMaterial materialsFromMtlFile : path ] ;
            
            self.mtlPath    = path ;
            self.materials  = dictionary  ;
        }
        else if( [ string isEqualToString : @"v" ] )
        {
            // Vertiecs ;
            [ scanner scanFloat : &vertex.x ] ;
            [ scanner scanFloat : &vertex.y ] ;
            [ scanner scanFloat : &vertex.z ] ;
            
            [ vertexTemp appendBytes : &vertex length : sizeof( Vertex3D ) ] ;
            
            if( minVertex.x > vertex.x )
            {
                minVertex.x = vertex.x ;
            }
            
            if( minVertex.y > vertex.y )
            {
                minVertex.y = vertex.y ;
            }
            
            if( minVertex.z > vertex.z )
            {
                minVertex.z = vertex.z ;
            }
            
            if( maxVertex.x < vertex.x )
            {
                maxVertex.x = vertex.x ;
            }
            
            if( maxVertex.y < vertex.y )
            {
                maxVertex.y = vertex.y ;
            }
            
            if( maxVertex.z < vertex.z )
            {
                maxVertex.z = vertex.z ;
            }
        }
        else if( [ string isEqualToString : @"vn" ] )
        {
            // Normal ;
            [ scanner scanFloat : &vertex.x ] ;
            [ scanner scanFloat : &vertex.y ] ;
            [ scanner scanFloat : &vertex.z ] ;
            
            [ normalTemp appendBytes : &vertex length : sizeof( Vertex3D ) ] ;
        }
        else if( [ string isEqualToString : @"vt" ] )
        {
            // Texcoords ;
            [ scanner scanFloat : &texcoord[ 0 ] ] ;
            [ scanner scanFloat : &texcoord[ 1 ] ] ;
            
            [ texcoordTemp appendBytes : &texcoord length : 2 * sizeof( GLfloat ) ] ;
        }
        else if( [ string isEqualToString : @"g" ] )
        {
            // Group ;
            [ scanner scanUpToCharactersFromSet : [ NSCharacterSet whitespaceCharacterSet ] intoString : &string ] ;
            
            group       = [ [ ObjGroup alloc ] initWithName : string ] ;
            
            [ groups addObject : group ] ;
            [ group release ] ;
        }
        else if( [ string isEqualToString : @"usemtl" ] )
        {
            // Material ;
            [ scanner scanUpToCharactersFromSet : [ NSCharacterSet whitespaceCharacterSet ] intoString : &string ] ;
            
            material    = [ materials objectForKey : string ] ;
            
            if( material == nil )
            {
                material = [ ObjMaterial defaultMaterial ] ;
            }
            
            if( group && ( [ group material ] == nil ) )
            {
                [ group setMaterial : material ] ;
            }
            else
            {
                group   = [ [ ObjGroup alloc ] initWithName : nil material : material ] ;
                
                [ groups addObject : group ] ;
                [ group release ] ;
            }
        }
        else if( [ string isEqualToString : @"f" ] )
        {
            // Face ;
            if( group == nil )
            {
                if( material == nil )
                {
                    material = [ ObjMaterial defaultMaterial ] ;
                }

                group   = [ [ ObjGroup alloc ] initWithName : nil material : material ] ;
                
                [ groups addObject : group ] ;
                [ group release ] ;
            }
            else
            {
                if( [ group material ] == nil )
                {
                    material = [ ObjMaterial defaultMaterial ] ;
                    [ group setMaterial : material ] ;
                }
            }
            
             // Set ;
            count   = 0 ;
            
            // Add Faces ;
            while( ![ scanner isAtEnd ] )
            {
                [ scanner scanUpToCharactersFromSet : [ NSCharacterSet whitespaceAndNewlineCharacterSet ] intoString : &index ] ;
                
                count   ++ ;
//              number  = [ indexDict objectForKey : index ] ;
                array   = [ index componentsSeparatedByString : @"/" ] ;
                
//              if( number == nil )
                {
                    faceIndex   = uniqueIndex ;
                    uniqueIndex ++ ;
                    
//                  [ indexDict setObject : [ NSNumber numberWithShort : faceIndex ]  forKey : index ] ;
                    
                    if( [ array count ] > 0 )
                    {
                        vertexIndex     = [ [ array objectAtIndex : 0 ] intValue ] ;
                        
                        // Vertex ;
                        [ vertexData appendBytes : vertexTemp.bytes + ( vertexIndex - 1 ) * sizeof( Vertex3D ) length : sizeof( Vertex3D ) ] ;
                    }
                    
                    if( [ array count ] > 1 )
                    {
                        texIndex        = [ [ array objectAtIndex : 1 ] intValue ] ;
                        
                        // Texcoord ;
                        if( texIndex )
                        {
                            [ texcoordData appendBytes : texcoordTemp.bytes + ( texIndex - 1 ) * 2 * sizeof( GLfloat ) length : 2 * sizeof( GLfloat ) ] ;
                        }
                    }
                    
                    if( [ array count ] > 2 )
                    {
                        normalIndex     = [ [ array objectAtIndex : 2 ] intValue ] ;
                        
                        // Normal ;
                        if( normalIndex )
                        {
                            [ normalData appendBytes : normalTemp.bytes + ( normalIndex - 1 ) * sizeof( Vertex3D ) length : sizeof( Vertex3D ) ] ;
                        }
                    }
                }
/*              else
                {
                    faceIndex   = [ number unsignedIntValue ] ;
                } */
                
                if( count > 3 )
                {
                    [ group.faceData appendBytes : group.faceData.bytes + group.faceData.length - 3 * sizeof( GLuint ) length : sizeof( GLuint ) ] ;
                    [ group.faceData appendBytes : group.faceData.bytes + group.faceData.length - 2 * sizeof( GLuint ) length : sizeof( GLuint ) ] ;
                }
                
                [ group.faceData appendBytes : &faceIndex length : sizeof( GLuint ) ] ;
            }
        }
    }

    // Vertices ;
    if( [ vertexData length ] )
    {
        numOfVertiecs   = [ vertexData length ] / sizeof( Vertex3D ) ;
        vertices        = ( Vertex3D* )malloc( [ vertexData length ] ) ;
        memcpy( vertices, [ vertexData bytes ], [ vertexData length ] ) ;
        
        verticesForZoom = ( Vertex3D* )malloc( [ vertexData length ] ) ;

        // Center ;
        transform = Vertex3DMake( ( maxVertex.x + minVertex.x ) / 2, ( maxVertex.y + minVertex.y ) / 2,  ( maxVertex.z + minVertex.z ) / 2 ) ;

        [ self zoomOut ] ;
    }
    
    // Normals ;
    if( [ normalData length ] )
    {
        numOfNormals    = [ normalData length ] / sizeof( Vertex3D ) ;
        normals         = ( Vertex3D* )malloc( [ normalData length ] ) ;
        memcpy( normals, [ normalData bytes ], [ normalData length ] ) ;
    }
    
    // Texcoords ;
    if( [ texcoordData length ] )
    {
        numOfTexcoords  = [ texcoordData length ] / sizeof( GLfloat ) ;
        texcoords       = ( GLfloat* )malloc( [ texcoordData length ] ) ;
        memcpy( texcoords, [ texcoordData bytes ], [ texcoordData length ] ) ;
    }
}

#pragma mark - Draw
- ( void ) drawModel
{    
    // Enable ;
    glEnable( GL_TEXTURE_2D ) ;
    
	glEnableClientState( GL_VERTEX_ARRAY ) ;
	glVertexPointer( 3, GL_FLOAT, 0, verticesForZoom ) ;
    
    glEnableClientState( GL_NORMAL_ARRAY ) ;
    glNormalPointer( GL_FLOAT, 0, normals ) ;
    
	// Enable the Texture ;
	if( texcoords != NULL )
	{
        glEnableClientState( GL_TEXTURE_COORD_ARRAY ) ;
        glTexCoordPointer( 2, GL_FLOAT, 0, texcoords ) ;
	}
    
    // Rotate ;
  glRotatef( 220, 40, 40, 40 ) ;
    
    // For Each Group ;
    for( ObjGroup* group in groups )
	{
        if( group != NULL && group.material.texture != nil )
        {
            [ group.material.texture bind ] ;
        }
        
        // Ambient ;
        Color3D ambient = group.material.ambient ;
		glMaterialfv( GL_FRONT_AND_BACK, GL_AMBIENT, ( const GLfloat* )&ambient ) ;
        
		// Diffuse ;
		Color3D diffuse = group.material.diffuse ;
		glMaterialfv( GL_FRONT_AND_BACK, GL_DIFFUSE,  ( const GLfloat* )&diffuse ) ;
		
        // Specular ;
		Color3D specular = group.material.specular ;
		glMaterialfv( GL_FRONT_AND_BACK, GL_SPECULAR, ( const GLfloat* )&specular ) ;
		
        // Shininess ;
		glMaterialf( GL_FRONT_AND_BACK, GL_SHININESS, 100.0f ) ;
        
		// Draw ;
        glDrawElements( GL_TRIANGLES, [ group.faceData length ] / sizeof( GLuint ), GL_UNSIGNED_INT, [ group.faceData bytes ] ) ;
    }
    
    // Disable ;
	if( texcoords != NULL )
    {
        glDisableClientState( GL_TEXTURE_COORD_ARRAY ) ;
    }
	
	glDisableClientState( GL_VERTEX_ARRAY ) ;
	glDisableClientState( GL_NORMAL_ARRAY ) ;

    glDisable( GL_TEXTURE_2D ) ;
}

#pragma mark - Material
- ( void ) setMaterial : ( NSString* ) _materialPath
{
    NSString*       strMTLPath      = nil ;
    NSDictionary*   newMaterials    = nil ;
    ObjMaterial*    material        = nil ;
    
    // MTL ;
    strMTLPath      = [ [ self.objPath  stringByDeletingLastPathComponent ] stringByAppendingPathComponent : _materialPath ] ;
    newMaterials    = [ ObjMaterial materialsFromMtlFile : strMTLPath ] ;
    
    if( newMaterials == nil )
    {
        return ;
    }
    
    for( ObjGroup* group in groups )
	{
		if( group.material != nil )
        {
            material = [ newMaterials objectForKey : group.material.name ] ;
            
            if( material == nil )
            {
                material = [ ObjMaterial defaultMaterial ] ;
            }
            
            group.material = material ;
        }
    }
    
    self.mtlPath    = _materialPath ;
    self.materials  = newMaterials ;
}

#pragma mark - Zoom
- ( void ) zoomOut
{
    int vertexIndex = 0 ;
    
    for( vertexIndex = 0 ; vertexIndex < numOfVertiecs ; vertexIndex ++ )
    {
        verticesForZoom[ vertexIndex ].x = ( vertices[ vertexIndex ].x - transform.x ) * zoomInfo.x ;
        verticesForZoom[ vertexIndex ].y = vertices[ vertexIndex ].y * zoomInfo.y ;
        verticesForZoom[ vertexIndex ].z = ( vertices[ vertexIndex ].z - transform.z ) * zoomInfo.z ;
    }
}

- ( void ) zoomIn
{
    int vertexIndex = 0 ;
    
    for( vertexIndex = 0 ; vertexIndex < numOfVertiecs ; vertexIndex ++ )
    {
        verticesForZoom[ vertexIndex ].x = ( vertices[ vertexIndex ].x - transform.x ) * zoomInfo.x ;
        verticesForZoom[ vertexIndex ].y = ( vertices[ vertexIndex ].y - transform.y ) * zoomInfo.y ;
        verticesForZoom[ vertexIndex ].z = ( vertices[ vertexIndex ].z - transform.z ) * zoomInfo.z ;
    }
}

@end