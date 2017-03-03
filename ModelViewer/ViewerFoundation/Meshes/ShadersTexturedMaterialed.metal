
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
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};



/**
 *  shaders that generate shadow-map texture from the light view point
 */

vertex PositionSimple vertex_shadow_tex_materialed(device Vertex *vertices [[buffer(0)]],
                                                   constant ModelUniforms &uniforms [[buffer(1)]],
                                                   constant MeshUniforms &meshUniforms [[buffer(2)]],
                                                   uint vid [[vertex_id]])
{
    PositionSimple outShadow;
    outShadow.position = uniforms.modelViewProjectionMatrix * meshUniforms.transform * vertices[vid].position;
    return outShadow;
}




vertex ProjectedVertex vertex_project_tex_materialed(device Vertex *vertices [[buffer(0)]],
                                                     constant ModelUniforms &uniforms [[buffer(1)]],
                                                     constant LightVertexUniforms &lightCast [[buffer(2)]],
                                                     constant MeshUniforms &meshUniforms [[buffer(3)]],
                                                     uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    
    float4 meshPosition = meshUniforms.transform * vertices[vid].position;
    
    outVert.position = uniforms.modelViewProjectionMatrix * meshPosition;
    outVert.eye =  -(uniforms.modelViewMatrix * meshPosition).xyz;
    outVert.normal = uniforms.normalMatrix * meshUniforms.normalTransform * vertices[vid].normal.xyz;
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
                                              constant LightUniform &lighting [[buffer(0)]],
                                              texture2d<float> shadowMap0 [[texture(0)]],
                                              texture2d<float> shadowMap1 [[texture(1)]],
                                              texture2d<float> diffuseTexture [[texture(2)]],
                                              texture2d<float> opacityTexture [[texture(3), function_constant(kAlphaChannelInSeparatedTexture)]],
                                              sampler depthSamplr [[sampler(0)]],
                                              sampler samplr [[sampler(1)]])
{
    VertexFragmentCharacters outVert = vertex_characters(vert);
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float4 opacityTexel = 1.0;
    if (kAlphaChannelInSeparatedTexture)
        opacityTexel = opacityTexture.sample(samplr, vert.texCoord);
    
    float4 diffuseColor = diffuse_common(diffuseTexel, opacityTexel.a);
    
    texture2d<float> shadowMap[2] = {shadowMap0, shadowMap1};
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

