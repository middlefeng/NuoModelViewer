//
//  NuoMatrixTypes.h
//  ModelViewer
//
//  Created by middleware on 2/3/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#ifndef NuoMatrixTypes_h
#define NuoMatrixTypes_h


#define USE_SIMD 1

/**
 *  Matrix/Vector types that cross the C++ and shader code
 *
 */


#ifndef Metal

#if USE_SIMD

    #import <simd/simd.h>

    #define matrix44 matrix_float4x4
    #define matrix33 matrix_float3x3
    #define vector4 vector_float4

#else

    #include <glm/glm.hpp>

    #define matrix44 glm::mat4x4
    #define matrix33 glm::mat3x3
    typedef glm::vec4 vector4;

#endif

#else

#include <metal_stdlib>
#include <metal_matrix>

#define matrix44 metal::float4x4
#define matrix33 metal::float3x3
#define vector4 metal::float4

#endif


#endif /* NuoMatrixTypes_h */
