
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
    float4 position [[position]];
    float3 eye;
    float3 normal;
    
    float3 diffuseColor;
    float3 ambientColor;
    float3 specularColor;
    float2 specularPowerDisolve;
};

vertex ProjectedVertex vertex_project_materialed(device Vertex *vertices [[buffer(0)]],
                                                 constant ModelUniforms &uniforms [[buffer(1)]],
                                                 uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    outVert.eye =  -(uniforms.modelViewMatrix * vertices[vid].position).xyz;
    outVert.normal = uniforms.normalMatrix * vertices[vid].normal.xyz;
    
    outVert.ambientColor = vertices[vid].ambientColor;
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.specularColor = vertices[vid].specularColor;
    outVert.specularPowerDisolve = vertices[vid].specularPowerDisolve;
    
    return outVert;
}

fragment float4 fragment_light_materialed(ProjectedVertex vert [[stage_in]],
                                          constant LightUniform &lightUniform [[buffer(0)]])
{
    float3 normal = normalize(vert.normal);
    float3 diffuseColor = vert.diffuseColor;
    float3 ambientTerm = lightUniform.ambientDensity * vert.ambientColor;
    
    float3 colorForLights = 0.0;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        float diffuseIntensity = saturate(dot(normal, normalize(lightUniform.direction[i].xyz)));
        float3 diffuseTerm = diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(normalize(lightUniform.direction[i].xyz) + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), vert.specularPowerDisolve.x);
            specularTerm = vert.specularColor * specularFactor;
        }
        
        colorForLights += diffuseTerm * lightUniform.density[i] + specularTerm * lightUniform.spacular[i];
    }
    
    return float4(ambientTerm + colorForLights, vert.specularPowerDisolve.y);
}
