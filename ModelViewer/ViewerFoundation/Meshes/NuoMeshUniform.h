//
//  NuoMeshUniform.h
//  ModelViewer
//
//  Created by middleware on 2/2/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoMeshUniform_h
#define NuoMeshUniform_h


#ifndef matrix44
#ifndef matrix33

#ifndef Metal

#import <simd/simd.h>

#define matrix44 matrix_float4x4
#define matrix33 matrix_float3x3

#else

#include <metal_stdlib>
#include <metal_matrix>

#define matrix44 metal::float4x4
#define matrix33 matrix_float3x3

#endif

#endif
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
