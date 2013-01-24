//
//  ObjCommon.h
//  Augmented Reality
//
//  Created by Xin ZhangZhe on 01/24/2013.
//  Copyright (c) 2012 HongJi Soft Co, Ltd. All rights reserved.
//
// --- Headers --- ;
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

// --- Defines --- ;
#define FREE_VALUE( M ) { if( ( M ) ) { free( ( M ) ) ; } }

typedef struct
{
	GLfloat     red ;
	GLfloat     green ;
	GLfloat     blue ;
	GLfloat     alpha ;
} Color3D ;

static inline Color3D Color3DMake( CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha )
{
    Color3D color ;
    
	color.red   = red ;
	color.green = green ;
	color.blue  = blue ;
	color.alpha = alpha ;
    
    return color ;
}

typedef struct
{
	GLfloat     x ;
	GLfloat     y ;
	GLfloat     z ;
} Vertex3D ;

static inline Vertex3D Vertex3DMake( CGFloat x, CGFloat y, CGFloat z )
{
	Vertex3D vertex ;
    
	vertex.x    = x ;
	vertex.y    = y ;
	vertex.z    = z ;
    
	return vertex ;
}

typedef Vertex3D Vector3D ;
#define Vector3DMake( x,y,z ) ( Vector3D ) Vertex3DMake( x, y, z )

static inline GLfloat Vector3DMagnitude( Vector3D vector )
{
	return sqrt( ( vector.x * vector.x ) + ( vector.y * vector.y ) + ( vector.z * vector.z ) ) ; 
}

static inline void Vector3DNormalize( Vector3D* vector )
{
	GLfloat vecMag = Vector3DMagnitude( *vector ) ;
    
	if( vecMag == 0.0 )
	{
		vector->x = 1.0 ;
		vector->y = 0.0 ;
		vector->z = 0.0 ;
	}
    
	vector->x /= vecMag ;
	vector->y /= vecMag ;
	vector->z /= vecMag ;
}

static inline GLfloat InvSqrt( GLfloat dTx )
{
    GLfloat     dHalf   = 0.5f * dTx ;
	NSInteger   nVal    = *( NSInteger* )&dTx ;
    
	nVal = 0x5f3759d5 - ( nVal >> 1 ) ;
    
	dTx = *( GLfloat* )&nVal ;
	dTx = dTx * ( 1.5f - dHalf * dTx * dTx ) ;
    
	return dTx ;
}

static inline GLfloat Vector3DFastInverseMagnitude( Vector3D stVector )
{
	return InvSqrt( ( stVector.x * stVector.x ) + ( stVector.y * stVector.y ) + ( stVector.z * stVector.z ) ) ;
}

static inline void Vector3DFastNormalize( Vector3D* pstVector )
{
	GLfloat dVecInverse = Vector3DFastInverseMagnitude( *pstVector ) ;
    
	if( dVecInverse == 0.0 )
	{
		pstVector->x = 1.0 ;
		pstVector->y = 0.0 ;
		pstVector->z = 0.0 ;
	}
    
	pstVector->x *= dVecInverse ;
	pstVector->y *= dVecInverse ;
	pstVector->z *= dVecInverse ;
}

static inline GLfloat Vector3DDotProduct( Vector3D stVector1, Vector3D stVector2 )
{		
	return stVector1.x * stVector2.x + stVector1.y * stVector2.y + stVector1.z * stVector2.z ;
}

static inline Vector3D Vector3DCrossProduct( Vector3D stVector1, Vector3D stVector2 )
{
	Vector3D stRet ;
    
	stRet.x = ( stVector1.y * stVector2.z ) - ( stVector1.z * stVector2.y ) ;
	stRet.y = ( stVector1.z * stVector2.x ) - ( stVector1.x * stVector2.z ) ;
	stRet.z = ( stVector1.x * stVector2.y ) - ( stVector1.y * stVector2.x ) ;
    
	return stRet ;
}

static inline Vector3D Vector3DMakeWithStartAndEndPoints( Vertex3D stStart, Vertex3D stEnd )
{
	Vector3D stRet ;
    
	stRet.x = stEnd.x - stStart.x ;
	stRet.y = stEnd.y - stStart.y ;
	stRet.z = stEnd.z - stStart.z ;
    
	Vector3DNormalize( &stRet ) ;
    
	return stRet ;
}

static inline Vector3D Vector3DAdd( Vector3D stVector1, Vector3D stVector2 )
{
	Vector3D stRet ;
    
	stRet.x = stVector1.x + stVector2.x ;
	stRet.y = stVector1.y + stVector2.y ;
	stRet.z = stVector1.z + stVector2.z ;
    
	return stRet ;
}

static inline void Vector3DFlip( Vector3D* stVector )
{
	stVector->x = - stVector->x ;
	stVector->y = - stVector->y ;
	stVector->z = - stVector->z ;
}

typedef Vertex3D Rotation3D ;
#define Rotation3DMake( x,y,z ) ( Rotation3D ) Vertex3DMake( x, y, z )

typedef struct
{
	GLushort	v1 ;
	GLushort	v2 ;
	GLushort	v3 ;
} Face3D ;

static inline Face3D Face3DMake( int dVal1, int dVal2, int dVal3 )
{
	Face3D stRet ;
    
	stRet.v1 = dVal1 ;
	stRet.v2 = dVal2 ;
	stRet.v3 = dVal3 ;
    
	return stRet ;
}

typedef struct
{
	Vertex3D v1 ;
	Vertex3D v2 ;
	Vertex3D v3 ;
} Triangle3D ;

static inline Triangle3D Triangle3DMake( Vertex3D stVector1, Vertex3D stVector2, Vertex3D stVector3 )
{
	Triangle3D stRet ;
    
	stRet.v1 = stVector1 ;
	stRet.v2 = stVector2 ;
	stRet.v3 = stVector3 ;
    
	return stRet ;
}

static inline Vector3D Triangle3DCalculateSurfaceNormal( Triangle3D stTriangle )
{
	Vector3D stVector1  = Vector3DMakeWithStartAndEndPoints( stTriangle.v2, stTriangle.v1 ) ;
	Vector3D stVector2  = Vector3DMakeWithStartAndEndPoints( stTriangle.v3, stTriangle.v1 ) ;
	Vector3D stRet ;
    
	stRet.x = ( stVector1.y * stVector2.z ) - ( stVector1.z * stVector2.y ) ;
	stRet.y = ( stVector1.z * stVector2.x ) - ( stVector1.x * stVector2.z ) ;
	stRet.z = ( stVector1.x * stVector2.y ) - ( stVector1.y * stVector2.x ) ;
    
	return stRet ;
}

struct VertexTextureIndex
{
	GLuint	originalVertex ;
	GLuint	textureCoords ;
	GLuint	actualVertex ;
	struct VertexTextureIndex* greater ;
	struct VertexTextureIndex* lesser ;
	
} ;

static inline struct VertexTextureIndex* VertexTextureIndexMake( GLuint inVertex, GLuint inTextureCoords, GLuint inActualVertex )
{
	struct VertexTextureIndex* pstRet = ( struct VertexTextureIndex* )malloc( sizeof( struct VertexTextureIndex ) ) ;
    
	pstRet->originalVertex  = inVertex ;
	pstRet->textureCoords   = inTextureCoords ;
	pstRet->actualVertex    = inActualVertex ;
	pstRet->greater         = NULL ;
	pstRet->lesser          = NULL ;
    
	return pstRet ;
}

#define VertexTextureIndexMakeEmpty( x, y ) VertexTextureIndexMake( x, y, UINT_MAX )

static inline GLuint VertexTextureIndexMatch( struct VertexTextureIndex* node, GLuint matchVertex, GLuint matchTextureCoords )
{
    GLuint nIndex = 0 ;
    
	if( node->originalVertex == matchVertex && node->textureCoords == matchTextureCoords )
    {
		return node->actualVertex ;
    }
	
	if( node->greater != NULL )
	{
		nIndex  = VertexTextureIndexMatch( node->greater, matchVertex, matchTextureCoords ) ;
        
		if( nIndex != UINT_MAX )
        {
			return nIndex ;
        }
	}
	
	if( node->lesser != NULL )
	{
		nIndex  = VertexTextureIndexMatch( node->lesser, matchVertex, matchTextureCoords ) ;
		return nIndex ;
	}
    
	return UINT_MAX ;
}

static inline struct VertexTextureIndex* VertexTextureIndexAddNode( struct VertexTextureIndex* pstNode, GLuint nNewVertex, GLuint nNewTextureCoords )
{
	if( pstNode->originalVertex == nNewVertex && pstNode->textureCoords == nNewTextureCoords )
    {
		return pstNode ;
    }
    
	if( pstNode->originalVertex > nNewVertex || ( pstNode->originalVertex == nNewVertex && pstNode->textureCoords > nNewTextureCoords ) )
	{
		if( pstNode->lesser != NULL )
        {
			return VertexTextureIndexAddNode( pstNode->lesser, nNewVertex, nNewTextureCoords ) ;
        }
		else
		{
			pstNode->lesser     = VertexTextureIndexMakeEmpty( nNewVertex, nNewTextureCoords ) ;
			return pstNode->lesser ;
		}
	}
	else
	{
		if( pstNode->greater != NULL )
        {
			return VertexTextureIndexAddNode( pstNode->greater, nNewVertex, nNewTextureCoords ) ;
        }
		else
		{
			pstNode->greater    = VertexTextureIndexMakeEmpty( nNewVertex, nNewTextureCoords ) ;
			return pstNode->greater ;
		}	
	}
    
	return NULL ;
}

static inline BOOL VertexTextureIndexContainsVertexIndex( struct VertexTextureIndex* pstNode, GLuint nMatchVertex )
{
	BOOL bHasGreater    = NO ;
	BOOL bHasLesser     = NO ;

	if( pstNode->originalVertex == nMatchVertex )
    {
		return YES ;
    }
	
	if( pstNode->greater != NULL )
    {
		bHasGreater = VertexTextureIndexContainsVertexIndex( pstNode->greater, nMatchVertex ) ;
    }
    
	if( pstNode->lesser != NULL )
    {
		bHasLesser  = VertexTextureIndexContainsVertexIndex( pstNode->lesser, nMatchVertex ) ;
    }
    
	return bHasGreater || bHasLesser ;
}

static inline void VertexTextureIndexFree( struct VertexTextureIndex* pstNode )
{
	if( pstNode != NULL )
	{
		if( pstNode->greater != NULL )
        {
			VertexTextureIndexFree( pstNode->greater ) ;
        }
        
		if( pstNode->lesser != NULL )
        {
			VertexTextureIndexFree( pstNode->lesser ) ;
        }
        
		free( pstNode ) ;
	}
}

static inline GLuint VertexTextureIndexCountNodes( struct VertexTextureIndex* pstNode )
{
	GLuint nRet = 0 ;
	
	if( pstNode )
	{
		nRet ++ ;
 
		if( pstNode->greater != NULL )
        {
			nRet += VertexTextureIndexCountNodes( pstNode->greater ) ;
        }
        
		if( pstNode->lesser != NULL )
        {
			nRet += VertexTextureIndexCountNodes( pstNode->lesser ) ;
        }
	}
    
	return nRet ;
}