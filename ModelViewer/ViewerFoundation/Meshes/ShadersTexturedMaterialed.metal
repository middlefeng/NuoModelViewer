
#include "ShadersCommon.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
    float2 texCoord;
    
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
    float2 texCoord;
    
    float3 diffuseColor;
    float3 ambientColor;
    float3 specularColor;
    float specularPower;
    float dissolve [[flat]];
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};



/**
 *  shaders that generates screen-space position only, used for stencile-based color,
 *  or depth-only rendering (e.g. shadow-map)
 */

vertex PositionSimple vertex_simple_tex_materialed(device Vertex *vertices [[buffer(0)]],
                                                   constant NuoUniforms &uniforms [[buffer(1)]],
                                                   constant NuoMeshUniforms &meshUniforms [[buffer(2)]],
                                                   uint vid [[vertex_id]])
{
    return vertex_simple<Vertex>(vertices, uniforms, meshUniforms, vid);
}




vertex ProjectedVertex vertex_project_tex_materialed(device Vertex *vertices [[buffer(0)]],
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
    outVert.eye =  eyePosition.xyz - meshPosition.xyz;
    outVert.normal = meshUniforms.normalTransform * vertices[vid].normal.xyz;
    outVert.texCoord = vertices[vid].texCoord;
    
    outVert.ambientColor = vertices[vid].ambientColor;
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.specularColor = vertices[vid].specularColor;
    outVert.specularPower = vertices[vid].specularPowerDisolve.x;
    outVert.dissolve = vertices[vid].specularPowerDisolve.y;
    
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    
    return outVert;
}



VertexFragmentCharacters vertex_characters(ProjectedVertex vert);



fragment float4 fragment_light_tex_materialed(ProjectedVertex vert [[stage_in]],
                                              constant NuoLightUniforms &lighting [[buffer(0)]],
                                              depth2d<float> shadowMap0 [[texture(0)]],
                                              depth2d<float> shadowMap1 [[texture(1)]],
                                              depth2d<float> depth      [[texture(2), function_constant(kDepthPrerenderred)]],
                                              texture2d<float> diffuseTexture [[texture(3)]],
                                              texture2d<float> opacityTexture [[texture(4), function_constant(kAlphaChannelInSeparatedTexture)]],
                                              sampler depthSamplr [[sampler(0)]],
                                              sampler samplr [[sampler(1)]])
{
    VertexFragmentCharacters outVert = vertex_characters(vert);
    
    if (kMeshMode == kMeshMode_Selection)
        return diffuse_lighted_selection(vert.positionNDC, vert.normal, depth, depthSamplr);
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float4 opacityTexel = 1.0;
    if (kAlphaChannelInSeparatedTexture)
        opacityTexel = opacityTexture.sample(samplr, vert.texCoord);
    
    float4 diffuseColor = diffuse_common(diffuseTexel, opacityTexel.a);
    
    depth2d<float> shadowMap[2] = {shadowMap0, shadowMap1};
    return fragment_light_tex_materialed_common(outVert, vert.normal, lighting, diffuseColor,
                                                shadowMap, depthSamplr);
}


VertexFragmentCharacters vertex_characters(ProjectedVertex vert)
{
    VertexFragmentCharacters outVert;
    
    outVert.eye = vert.eye;
    outVert.diffuseColor = vert.diffuseColor;
    outVert.ambientColor = vert.ambientColor;
    outVert.specularColor = vert.specularColor;
    outVert.specularPower = vert.specularPower;
    outVert.opacity = vert.dissolve;
    
    outVert.shadowPosition[0] = vert.shadowPosition0;
    outVert.shadowPosition[1] = vert.shadowPosition1;
    
    return outVert;
}


#pragma mark -- Screen Space Shaders --


vertex VertexScreenSpace vertex_screen_space_tex_materialed(device Vertex *vertices [[buffer(0)]],
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
    result.diffuseColorFactor = vertices[vid].diffuseColor;
    result.texCoord = vertices[vid].texCoord;
    result.opacity = vertices[vid].specularPowerDisolve.y;
    
    return result;
}

