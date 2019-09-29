
#include "ShadersCommon.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
    
    float3 diffuseColor;
    float3 ambientColor;
    float3 specularColor;
    float2 specularPowerDisolve;
};

struct ProjectedVertex
{
    float4 position     [[position]];
    float4 positionNDC;
    float3 eye;
    float3 normal;
    
    float3 diffuseColor;
    float3 ambientColor;
    float3 specularColor;
    float2 specularPowerDisolve;
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};



static VertexFragmentCharacters vertex_characters(ProjectedVertex vert);


vertex PositionSimple vertex_simple_materialed(device const Vertex *vertices [[buffer(0)]],
                                               constant NuoUniforms &uniforms [[buffer(1)]],
                                               constant NuoMeshUniforms &meshUniforms [[buffer(2)]],
                                               uint vid [[vertex_id]])
{
    return vertex_simple<Vertex>(vertices, uniforms, meshUniforms, vid);
}


#pragma mark -- Phong Model Shaders --


vertex ProjectedVertex vertex_project_materialed(device const Vertex *vertices [[buffer(0)]],
                                                 constant NuoUniforms &uniforms [[buffer(1)]],
                                                 constant NuoLightVertexUniforms &lightCast [[buffer(2)]],
                                                 constant NuoMeshUniforms &meshUniforms [[buffer(3)]],
                                                 uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    
    float4 meshPosition = meshUniforms.transform * vertices[vid].position;
    float4 eyePosition = uniforms.viewMatrixInverse * float4(0.0, 0.0, 0.0, 1.0);
    
    outVert.position = uniforms.viewProjectionMatrix * meshPosition;
    outVert.positionNDC = uniforms.viewProjectionMatrix * meshPosition;
    outVert.eye = eyePosition.xyz - meshPosition.xyz;
    outVert.normal = meshUniforms.normalTransform * vertices[vid].normal.xyz;
    
    outVert.ambientColor = vertices[vid].ambientColor;
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.specularColor = vertices[vid].specularColor;
    outVert.specularPowerDisolve = vertices[vid].specularPowerDisolve;
    
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    
    return outVert;
}

fragment float4 fragment_light_materialed(ProjectedVertex vert [[stage_in]],
                                          constant NuoLightUniforms &lightUniform [[buffer(0)]],
                                          texture_array<2>::t shadowMaps [[texture(0)]],
                                          texture_array<2>::t shadowMapsExt [[texture(2)]],
                                          texture2d<float> depth [[texture(4), function_constant(kDepthPrerenderred)]],
                                          sampler depthSamplr [[sampler(0)]])
{
    if (kMeshMode == kMeshMode_Selection)
        return diffuse_lighted_selection(vert.positionNDC, vert.normal, depth, depthSamplr);
    
    VertexFragmentCharacters vertFrag = vertex_characters(vert);
    return fragment_light_tex_materialed_common(vertFrag, lightUniform, shadowMaps, shadowMapsExt, depthSamplr);
}



VertexFragmentCharacters vertex_characters(ProjectedVertex vert)
{
    VertexFragmentCharacters outVert;
    
    outVert.projectedNDC = vert.positionNDC;
    outVert.eye = vert.eye;
    outVert.normal = normalize(vert.normal);
    outVert.diffuseColor = vert.diffuseColor;
    outVert.specularColor = vert.specularColor;
    outVert.specularPower = vert.specularPowerDisolve.x;
    outVert.opacity = vert.specularPowerDisolve.y;
    
    outVert.shadowPosition[0] = vert.shadowPosition0;
    outVert.shadowPosition[1] = vert.shadowPosition1;
    
    return outVert;
}


#pragma mark -- Screen Space Shaders --


vertex VertexScreenSpace vertex_screen_space_materialed(device const Vertex *vertices [[buffer(0)]],
                                                        constant NuoUniforms &uniforms [[buffer(1)]],
                                                        constant NuoMeshUniforms &meshUniform [[buffer(3)]],
                                                        uint vid [[vertex_id]])
{
    VertexScreenSpace result;
    
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    float3 meshNormal = meshUniform.normalTransform * vertices[vid].normal.xyz;
    
    result.projectedPosition = uniforms.viewProjectionMatrix * meshPosition;
    result.position =  uniforms.viewMatrix * meshPosition;
    result.normal = float4(meshNormal, 1.0);
    result.diffuseColorFactor = vertices[vid].diffuseColor.rgb;
    result.opacity = vertices[vid].specularPowerDisolve.y;
    
    return result;
}

