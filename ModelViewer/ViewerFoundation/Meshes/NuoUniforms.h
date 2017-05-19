

#ifndef NuoUniforms_h
#define NuoUniforms_h


#include "NuoMatrixTypes.h"


/**
 *  vertex shader uniform to calculate interpolatable per-vertex data
 */
typedef struct
{
    matrix44 modelViewProjectionMatrix;
    matrix44 modelViewMatrix;
    matrix33 normalMatrix;
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

