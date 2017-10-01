

#ifndef NuoUniforms_h
#define NuoUniforms_h


#include "NuoMatrixTypes.h"


/**
 *  vertex shader uniform for transform. if a mesh does not cast shadow, all its transforms
 *  can be multiplied into one on the CPU side and put to a single uniform.
 *  example: cube (skybox) mesh
 *
 *  otherwise, the view-projection matrix has to be separated vith the model transform.
 */
typedef struct
{
    matrix44 viewProjectionMatrix;
    matrix44 viewMatrix;
}
NuoUniforms;


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
NuoLightVertexUniforms;



typedef struct
{
    vector4 direction;
    float density;
    float spacular;
}
NuoLightParameterUniformField;



typedef struct
{
    float soften;
    float bias;
    float occluderRadius;
}
NuoShadowParameterUniformField;


/**
 *  fragement shader uniform to calulate lighted color
 */
typedef struct
{
    NuoLightParameterUniformField lightParams[4];
    NuoShadowParameterUniformField shadowParams[2];
    
    float ambientDensity;
}
NuoLightUniforms;


typedef struct
{
    float opacity;
}
NuoModelCharacterUniforms;


typedef struct
{
    float sampleRadius;
    float scale;
    float bias;
    float intensity;
}
NuoAmbientOcclusionUniforms;


typedef enum
{
    kMeshMode_Normal,
    kMeshMode_ShadowOccluder,
    kMeshMode_ShadowPenumbraFactor
}
NuoMeshModeShaderParameter;


#endif

