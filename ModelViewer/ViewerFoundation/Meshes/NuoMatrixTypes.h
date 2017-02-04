//
//  NuoMatrixTypes.h
//  ModelViewer
//
//  Created by middleware on 2/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoMatrixTypes_h
#define NuoMatrixTypes_h


/**
 *  Matrix/Vector types that cross the C++ and shader code
 *
 */


#ifndef Metal

#import <simd/simd.h>

#define matrix44 matrix_float4x4
#define matrix33 matrix_float3x3
#define vector4 vector_float4

#else

#include <metal_stdlib>
#include <metal_matrix>

#define matrix44 metal::float4x4
#define matrix33 metal::float3x3
#define vector4 metal::float4

#endif


#endif /* NuoMatrixTypes_h */
