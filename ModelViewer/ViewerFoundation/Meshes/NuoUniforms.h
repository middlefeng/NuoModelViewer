

#ifndef NuoUniforms_h
#define NuoUniforms_h


#include "NuoMatrixTypes.h"


/**
 *  vertex shader uniform for transform. if a mesh does not cast shadow, all its transforms
 *  can be multiplied into one on the CPU side and put to a single uniform.
 *  example: cube (skybox) mesh
 *
 *  otherwise, the view-projection matrix has to be separated vith the model transform.
 *
 *  vertices are transformed to the camera coordinates (eye is always at (0, 0, 0)) before passed
 *  into the fragement shader. other info required by shading (e.g. normals, light vectors) are in
 *  the world coordinate (i.e. eye being transformed through the inverse of the view matrix)
 */
typedef struct
{
    matrix44 viewProjectionMatrix;
    matrix44 viewMatrix;
    
    /**
     *  required by eye vector. light vectors and normals are pre-view-transform, so
     *  eye vectors must be transformed by the inverse of the view transform.
     */
    matrix44 viewMatrixInverse;
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
    vector4 direction __attribute__ ((aligned (16)));
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
NuoAmbientOcclusionUniformField;


typedef struct
{
    NuoAmbientOcclusionUniformField ambientOcclusionParams;
    vector4 clearColor;
}
NuoDeferredRenderUniforms;


typedef struct
{
    // the contribution of direct light in relative to ambient lighting on a
    // surface which is not part of the scene but part of the blend-in background.
    // there is no way to calculate so it has to be estimated by user through trial-and-error
    //
    float directLightDensity;
    
    // a ray's color when it intersect with nothing after bouncing enough
    // number of times, or travel enough distance
    //
    float ambientDensity;
}
NuoGlobalIlluminationUniforms;


typedef enum
{
    kPipeline_AlphaEmbeded,
    kPipeline_TextureAlpha,
    kPipeline_PhysicallyBased,
    kPipeline_ShadowOverlay,
    kPipeline_PCSS,
    kPipeline_PCF,
    kPipeline_Mode
}
NuoMeshPipelineConstantIndex;


typedef enum
{
    kMeshMode_Normal,
    kMeshMode_ShadowOccluder,
    kMeshMode_ShadowPenumbraFactor,
    kMeshMode_Selection
}
NuoMeshModeShaderParameter;


#endif

