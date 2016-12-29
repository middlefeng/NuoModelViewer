

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
                               constant LightUniform &lightUniform [[buffer(0)]],
                               constant ModelCharacterUniforms &modelCharacterUniforms [[buffer(1)]])
{
    float3 normal = normalize(vert.normal);
    float3 ambientTerm = lightUniform.ambientDensity * material.ambientColor;
    float3 colorForLights = 0.0;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        float diffuseIntensity = saturate(dot(normal, normalize(lightUniform.direction[i].xyz)));
        float3 diffuseTerm = material.diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(normalize(lightUniform.direction[i].xyz) + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
            specularTerm = material.specularColor * specularFactor;
        }
        
        colorForLights += (diffuseTerm + specularTerm) * lightUniform.density[i];
    }
    
    return float4(ambientTerm + colorForLights, modelCharacterUniforms.opacity);
}


float4 fragment_light_tex_materialed_common(VertexFragmentCharacters vert,
                                            float3 normal,
                                            constant LightUniform &lightingUniform,
                                            float4 diffuseTexel)
{
    normal = normalize(normal);
    
    float3 diffuseColor = diffuseTexel.rgb * vert.diffuseColor;
    float opacity = diffuseTexel.a * vert.opacity;
    
    float3 ambientTerm = lightingUniform.ambientDensity * vert.ambientColor;
    float3 colorForLights = 0.0;
    
    float transparency = 1.0;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        float3 lightVector = normalize(lightingUniform.direction[i].xyz);
        float diffuseIntensity = saturate(dot(normal, lightVector));
        float3 diffuseTerm = diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(lightVector + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), vert.specularPowerDisolve);
            transparency *= ((1 - opacity) * (1 - saturate(pow(specularFactor * lightingUniform.density[i], 3.0))));
            specularTerm = vert.specularColor * specularFactor;
        }
        
        colorForLights += (diffuseTerm + specularTerm) * lightingUniform.density[i];
    }
    
    if (opacity < 1.0 && transparency < 1.0)
        opacity = 1.0 - transparency;
    
    return float4(ambientTerm + colorForLights, opacity);
}
