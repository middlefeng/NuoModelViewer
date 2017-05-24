

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
    
    float shadowSoften[2];
    float shadowBias[2];
}
LightUniform;


typedef struct
{
    float opacity;
}
ModelCharacterUniforms;


#endif

