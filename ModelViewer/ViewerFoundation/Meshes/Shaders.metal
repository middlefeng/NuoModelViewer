

#include "ShadersCommon.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
};

struct ProjectedVertex
{
    float4 position [[position]];
    float3 eye;
    float3 normal;
};

vertex ProjectedVertex vertex_project(device Vertex *vertices [[buffer(0)]],
                                      constant Uniforms &uniforms [[buffer(1)]],
                                      uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    outVert.eye =  -(uniforms.modelViewMatrix * vertices[vid].position).xyz;
    outVert.normal = uniforms.normalMatrix * vertices[vid].normal.xyz;
    
    return outVert;
}

fragment float4 fragment_light(ProjectedVertex vert [[stage_in]],
                               constant LightUniform &lightUniform [[buffer(0)]])
{
    float3 ambientTerm = light.ambientColor * material.ambientColor;
    
    float3 normal = normalize(vert.normal);
    float diffuseIntensity = saturate(dot(normal, normalize(lightUniform.direction.xyz)));
    float3 diffuseTerm = light.diffuseColor * material.diffuseColor * diffuseIntensity;
    
    float3 specularTerm(0);
    if (diffuseIntensity > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway = normalize(normalize(lightUniform.direction.xyz) + eyeDirection);
        float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
        specularTerm = light.specularColor * material.specularColor * specularFactor;
    }
    
    return float4(ambientTerm + diffuseTerm + specularTerm, 1);
}
