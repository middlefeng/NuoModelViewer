
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
    float4 position [[position]];
    float3 eye;
    float3 normal;
    float2 texCoord;
    
    float3 diffuseColor;
    float3 ambientColor;
    float3 specularColor;
    float specularPower;
    float dissolve [[flat]];
    
    float4 shadowPosition;
};





/**
 *  shaders that generate shadow-map texture from the light view point
 */

vertex PositionSimple vertex_shadow_tex_materialed(device Vertex *vertices [[buffer(0)]],
                                                   constant ModelUniforms &uniforms [[buffer(1)]],
                                                   uint vid [[vertex_id]])
{
    PositionSimple outShadow;
    outShadow.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    return outShadow;
}




vertex ProjectedVertex vertex_project_tex_materialed(device Vertex *vertices [[buffer(0)]],
                                                     constant ModelUniforms &uniforms [[buffer(1)]],
                                                     constant ModelUniforms &lightCast [[buffer(2)]],
                                                     uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    outVert.eye =  -(uniforms.modelViewMatrix * vertices[vid].position).xyz;
    outVert.normal = uniforms.normalMatrix * vertices[vid].normal.xyz;
    outVert.texCoord = vertices[vid].texCoord;
    
    outVert.ambientColor = vertices[vid].ambientColor;
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.specularColor = vertices[vid].specularColor;
    outVert.specularPower = vertices[vid].specularPowerDisolve.x;
    outVert.dissolve = vertices[vid].specularPowerDisolve.y;
    
    outVert.shadowPosition = lightCast.modelViewProjectionMatrix * vertices[vid].position;
    
    return outVert;
}



VertexFragmentCharacters vertex_characters(ProjectedVertex vert);



fragment float4 fragment_light_tex_a_materialed(ProjectedVertex vert [[stage_in]],
                                                constant LightUniform &lighting [[buffer(0)]],
                                                texture2d<float> shadowMap [[texture(0)]],
                                                texture2d<float> diffuseTexture [[texture(1)]],
                                                sampler samplr [[sampler(0)]])
{
    VertexFragmentCharacters outVert = vertex_characters(vert);
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    diffuseTexel = float4(diffuseTexel.rgb / diffuseTexel.a, diffuseTexel.a);
    return fragment_light_tex_materialed_common(outVert, vert.normal, lighting, diffuseTexel);
}


fragment float4 fragment_light_tex_materialed(ProjectedVertex vert [[stage_in]],
                                              constant LightUniform &lighting [[buffer(0)]],
                                              texture2d<float> shadowMap [[texture(0)]],
                                              texture2d<float> diffuseTexture [[texture(1)]],
                                              sampler samplr [[sampler(0)]])
{
    VertexFragmentCharacters outVert = vertex_characters(vert);
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    if (diffuseTexel.a < 1e-9)
        diffuseTexel.rgb = float3(1.0);
    else
        diffuseTexel = diffuseTexel / diffuseTexel.a;
    
    diffuseTexel.a = 1.0;
    return fragment_light_tex_materialed_common(outVert, vert.normal, lighting, diffuseTexel);
}


fragment float4 fragment_light_tex_materialed_tex_opacity(ProjectedVertex vert [[stage_in]],
                                                          constant LightUniform &lighting [[buffer(0)]],
                                                          texture2d<float> shadowMap [[texture(0)]],
                                                          texture2d<float> diffuseTexture [[texture(1)]],
                                                          texture2d<float> opacityTexture [[texture(2)]],
                                                          sampler samplr [[sampler(0)]])
{
    VertexFragmentCharacters outVert = vertex_characters(vert);
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float4 opacityTexel = opacityTexture.sample(samplr, vert.texCoord);
    diffuseTexel = diffuseTexel / diffuseTexel.a;
    diffuseTexel.a = opacityTexel.a;
    return fragment_light_tex_materialed_common(outVert, vert.normal, lighting, diffuseTexel);
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
    
    return outVert;
}

