

#ifndef NuoUniforms_h
#define NuoUniforms_h

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



/**
 *  vertex shader uniform to calculate interpolatable per-vertex data
 */
typedef struct
{
    matrix44 modelViewProjectionMatrix;
    matrix44 modelViewMatrix;
    matrix33 normalMatrix;
}
ModelUniforms;


/**
 *  vertex shader uniform to calculate interpolatable per-vertex *shadow* data.
 *  it is separated from ModelUniforms because the dependencies to the shadow map
 *  render-pass
 */
typedef struct
{
    // enabling shadow casting for two light sources
    matrix44 lightCastMatrix[2];
}
LightVertexUniforms;


/**
 *  fragement shader uniform to calulate lighted color
 */
typedef struct
{
    vector4 direction[4];
    float density[4];
    float spacular[4];
    float ambientDensity;
}
LightUniform;


typedef struct
{
    float opacity;
}
ModelCharacterUniforms;


#endif

