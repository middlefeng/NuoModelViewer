
#include "ShadersCommon.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
    float2 texCoord;
};

struct ProjectedVertex
{
    float4 position [[position]];
    float4 positionNDC;
    float3 eye;
    float3 normal;
    float2 texCoord;
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};

/**
 *   shader that generates screen-space position only, used for stencile-based color,
 *   or depth-only rendering (e.g. shadow-map)
 */

vertex PositionSimple vertex_simple_textured(device Vertex *vertices [[buffer(0)]],
                                             constant NuoUniforms &uniforms [[buffer(1)]],
                                             constant NuoMeshUniforms &meshUniforms [[buffer(2)]],
                                             uint vid [[vertex_id]])
{
    return vertex_simple<Vertex>(vertices, uniforms, meshUniforms, vid);
}


#pragma mark -- SCreen Space Shaders --


vertex VertexScreenSpace vertex_screen_space_textured(device Vertex *vertices [[buffer(0)]],
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
    result.diffuseColorFactor = material.diffuseColor;
    result.texCoord = vertices[vid].texCoord;
    result.opacity = 1.0;
    
    return result;
}


fragment FragementScreenSpace fragement_screen_space_textured(VertexScreenSpace vert [[stage_in]],
                                                              constant NuoLightUniforms& lightUniform [[ buffer(0) ]],
                                                              texture2d<float> diffuseTexture [[ texture(0) ]],
                                                              sampler samplr [[ sampler(0) ]])
{
    FragementScreenSpace result;
    result.position = vert.position;
    result.normal = vert.normal;
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float3 diffuseColor = diffuseTexel.rgb / diffuseTexel.a;
    float alpha = diffuseTexel.a * vert.opacity;
    result.ambientColorFactor = float4(saturate(vert.diffuseColorFactor * diffuseColor * lightUniform.ambientDensity) * alpha, alpha);
    
    result.shadowOverlay = kShadowOverlay ? 1.0 : 0.0;
    
    return result;
}


#pragma mark -- Phong Model Shaders --


vertex ProjectedVertex vertex_project_textured(device Vertex *vertices [[buffer(0)]],
                                               constant NuoUniforms &uniforms [[buffer(1)]],
                                               constant NuoLightVertexUniforms &lightCast [[buffer(2)]],
                                               constant NuoMeshUniforms &meshUniforms [[buffer(3)]],
                                               uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    
    float4 meshPosition = meshUniforms.transform * vertices[vid].position;
    float4 eyePosition = uniforms.viewMatrixInverse * float4(0.0, 0.0, 0.0, 1.0);
    
    outVert.position = uniforms.viewProjectionMatrix * meshPosition;
    outVert.positionNDC = outVert.position;
    outVert.eye = eyePosition.xyz - meshPosition.xyz;
    outVert.normal = meshUniforms.normalTransform * vertices[vid].normal.xyz;
    outVert.texCoord = vertices[vid].texCoord;
    
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    
    return outVert;
}


static VertexFragmentCharacters vertex_characters(ProjectedVertex vert)
{
    VertexFragmentCharacters outVert;
    
    outVert.projectedNDC = vert.positionNDC;
    
    outVert.eye = vert.eye;
    outVert.normal = normalize(vert.normal);
    outVert.diffuseColor = material.diffuseColor;
    outVert.specularColor = material.specularColor;
    outVert.specularPower = material.specularPower;
    outVert.opacity = 1.0;
    
    outVert.shadowPosition[0] = vert.shadowPosition0;
    outVert.shadowPosition[1] = vert.shadowPosition1;
    
    return outVert;
}


fragment float4 fragment_light_textured(ProjectedVertex vert [[stage_in]],
                                        constant NuoLightUniforms &lightUniform [[buffer(0)]],
                                        texture_array<2>::t shadowMaps    [[texture(0)]],
                                        texture_array<2>::t shadowMapsExt [[texture(2)]],
                                        texture2d<float> diffuseTexture   [[texture(4)]],
                                        sampler depthSamplr [[sampler(0)]],
                                        sampler samplr [[sampler(1)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float3 diffuseColor = diffuseTexel.rgb / diffuseTexel.a;
    
    VertexFragmentCharacters outVert = vertex_characters(vert);
    outVert.diffuseColor = diffuseColor;
    outVert.opacity = diffuseTexel.a;
    
    return fragment_light_tex_materialed_common(outVert, lightUniform, shadowMaps, shadowMapsExt, depthSamplr);
}

