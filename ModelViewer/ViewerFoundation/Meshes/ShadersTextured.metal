
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
    float3 eye;
    float3 normal;
    float2 texCoord;
    
    float4 shadowPosition;
};

vertex PositionSimple vertex_shadow_textured(device Vertex *vertices [[buffer(0)]],
                                             constant ModelUniforms &uniforms [[buffer(1)]],
                                             uint vid [[vertex_id]])
{
    PositionSimple outShadow;
    outShadow.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    return outShadow;
}


fragment void fragment_shadow_textured(PositionSimple vert [[stage_in]])
{
}


vertex ProjectedVertex vertex_project_textured(device Vertex *vertices [[buffer(0)]],
                                               constant ModelUniforms &uniforms [[buffer(1)]],
                                               constant ModelUniforms &lightCast [[buffer(2)]],
                                               uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    outVert.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    outVert.eye =  -(uniforms.modelViewMatrix * vertices[vid].position).xyz;
    outVert.normal = uniforms.normalMatrix * vertices[vid].normal.xyz;
    outVert.texCoord = vertices[vid].texCoord;
    
    outVert.shadowPosition = lightCast.modelViewProjectionMatrix * vertices[vid].position;

    return outVert;
}

fragment float4 fragment_light_textured(ProjectedVertex vert [[stage_in]],
                                        constant LightUniform &lightUniform [[buffer(0)]],
                                        texture2d<float> shadowMap [[texture(0)]],
                                        texture2d<float> diffuseTexture [[texture(1)]],
                                        sampler samplr [[sampler(0)]])
{
    float3 normal = normalize(vert.normal);
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float3 diffuseColor = diffuseTexel.rgb / diffuseTexel.a;
    
    float3 ambientTerm = lightUniform.ambientDensity * material.ambientColor;
    
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
            float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
            specularTerm = material.specularColor * specularFactor;
        }
        
        colorForLights += diffuseTerm * lightUniform.density[i] + specularTerm * lightUniform.spacular[i];
    }
    
    
    float2 shadowCoord = float2(vert.shadowPosition.x / vert.shadowPosition.w, vert.shadowPosition.y / vert.shadowPosition.w);
    shadowCoord.x = (shadowCoord.x + 1) * 0.5;
    shadowCoord.y = (-shadowCoord.y + 1) * 0.5;
    
    float texelSize = 1.0 / 4096;
    int shadowCoverage = 0;
    int shadowSoftRadius = 16;
    
    /*float4 shadowDepth = shadowMap.sample(samplr, shadowCoord);
    if (shadowDepth.x < (vert.shadowPosition.z / vert.shadowPosition.w) - 0.001)
    {
        return float4(ambientTerm, diffuseTexel.a);
    }*/
    
    float xCurrent = shadowCoord.x - shadowSoftRadius * texelSize;
    for (int i = 0; i < shadowSoftRadius * 2; ++i)
    {
        float yCurrent = shadowCoord.y - shadowSoftRadius * texelSize;
        for (int j = 0; j < shadowSoftRadius * 2; ++j)
        {
            float4 shadowDepth = shadowMap.sample(samplr, float2(xCurrent, yCurrent));
            if (shadowDepth.x < (vert.shadowPosition.z / vert.shadowPosition.w) - 0.001)
            {
                shadowCoverage += 1;
            }
            
            yCurrent += texelSize;
        }
        
        xCurrent += texelSize;
    }
    
    if (shadowCoverage > 0)
    {
        float shadowPercent = shadowCoverage / (shadowSoftRadius * shadowSoftRadius * 4.0);
        return float4(ambientTerm + colorForLights * (1 - shadowPercent), diffuseTexel.a);
    }
    
    return float4(ambientTerm + colorForLights, diffuseTexel.a);
}

