
#include "ShadersCommon.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
    float4 tangent;
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
    float3 tangent;
    float2 texCoord;
    
    float3 diffuseColor;
    float3 ambientColor;
    float3 specularColor;
    float2 specularPowerDisolve;
};

vertex ProjectedVertex vertex_tex_materialed_tangent(device Vertex *vertices [[buffer(0)]],
                                                     constant Uniforms &uniforms [[buffer(1)]],
                                                     uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    outVert.eye =  -(uniforms.modelViewMatrix * vertices[vid].position).xyz;
    outVert.normal = uniforms.normalMatrix * vertices[vid].normal.xyz;
    outVert.tangent = uniforms.normalMatrix * (vertices[vid].tangent.xyz / vertices[vid].tangent.w);
    outVert.texCoord = vertices[vid].texCoord;
    
    outVert.ambientColor = vertices[vid].ambientColor;
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.specularColor = vertices[vid].specularColor;
    outVert.specularPowerDisolve = vertices[vid].specularPowerDisolve;
    
    return outVert;
}



static VertexFragmentCharacters vertex_characters(ProjectedVertex vert);



fragment float4 fragment_tex_a_materialed_bump(ProjectedVertex vert [[stage_in]],
                                               constant LightUniform &lighting [[buffer(0)]],
                                               texture2d<float> diffuseTexture [[texture(0)]],
                                               texture2d<float> bumpTexture [[texture(1)]],
                                               sampler samplr [[sampler(0)]])
{
    VertexFragmentCharacters outVert = vertex_characters(vert);
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    diffuseTexel = float4(diffuseTexel.rgb / diffuseTexel.a, diffuseTexel.a);
    
    float4 bumpNormal = bumpTexture.sample(samplr, vert.texCoord);
    bumpNormal.x = (bumpNormal.x * 2.) - 1.;
    bumpNormal.y = (bumpNormal.y * 2.) - 1.;
    bumpNormal.z = (bumpNormal.z * 2.) - 1.;
    bumpNormal.w = 0;
    
    float4 tangent = float4(vert.tangent, 0);
    float4 normal = float4(normalize(vert.normal), 0);
    float4 bitagent = normal * tangent;
    float4x4 m = { tangent, bitagent, normal,
                   float4(0, 0, 0, 1) };
    normal = normalize(m * bumpNormal);
    
    return fragment_light_tex_materialed_common(outVert, normal.xyz, lighting, diffuseTexel);
}


fragment float4 fragment_tex_materialed_bump(ProjectedVertex vert [[stage_in]],
                                             constant LightUniform &lighting [[buffer(0)]],
                                             texture2d<float> diffuseTexture [[texture(0)]],
                                             texture2d<float> bumpTexture [[texture(1)]],
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


fragment float4 fragment_tex_materialed_tex_opacity_bump(ProjectedVertex vert [[stage_in]],
                                                         constant LightUniform &lighting [[buffer(0)]],
                                                         texture2d<float> diffuseTexture [[texture(0)]],
                                                         texture2d<float> opacityTexture [[texture(1)]],
                                                         texture2d<float> bumpTexture [[texture(2)]],
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
    outVert.specularPowerDisolve = vert.specularPowerDisolve.x;
    outVert.opacity = vert.specularPowerDisolve.y;
    
    return outVert;
}

