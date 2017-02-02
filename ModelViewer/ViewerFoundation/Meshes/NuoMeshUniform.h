//
//  NuoMeshUniform.h
//  ModelViewer
//
//  Created by middleware on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoMeshUniform_h
#define NuoMeshUniform_h



#ifndef Metal

#import <simd/simd.h>

#define matrix44 matrix_float4x4

#else

#include <metal_stdlib>
#include <metal_matrix>

#define matrix44 metal::float4x4

#endif



/**
 *  vertex shader uniform to calculate interpolatable per-vertex data
 */
typedef struct
{
    matrix44 transform;
    matrix33 normalTransform;
}
MeshUniforms;


#endif /* NuoMeshUniform_h */
