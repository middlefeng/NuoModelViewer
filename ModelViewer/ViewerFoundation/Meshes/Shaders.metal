

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
    
    float4 shadowPosition;
};


ProjectedVertex vertex_project_common(device Vertex *vertices [[buffer(0)]],
                                      constant ModelUniforms &uniforms [[buffer(1)]],
                                      uint vid [[vertex_id]]);



vertex PositionSimple vertex_shadow(device Vertex *vertices [[buffer(0)]],
                                    constant ModelUniforms &uniforms [[buffer(1)]],
                                    uint vid [[vertex_id]])
{
    PositionSimple outShadow;
    outShadow.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    return outShadow;
}



fragment void fragment_shadow(PositionSimple vert [[stage_in]])
{
}



vertex ProjectedVertex vertex_project(device Vertex *vertices [[buffer(0)]],
                                      constant ModelUniforms &uniforms [[buffer(1)]],
                                      uint vid [[vertex_id]])
{
    return vertex_project_common(vertices, uniforms, vid);
}



fragment float4 fragment_light(ProjectedVertex vert [[stage_in]],
                               constant LightUniform &lightUniform [[buffer(0)]],
                               constant ModelCharacterUniforms &modelCharacterUniforms [[buffer(1)]],
                               sampler samplr [[sampler(0)]])
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
        
        colorForLights += diffuseTerm * lightUniform.density[i] + specularTerm * lightUniform.spacular[i];
    }
    
    return float4(ambientTerm + colorForLights, modelCharacterUniforms.opacity);
}



vertex ProjectedVertex vertex_project_shadow(device Vertex *vertices [[buffer(0)]],
                                             constant ModelUniforms &uniforms [[buffer(1)]],
                                             constant ModelUniforms &lightCast [[buffer(2)]],
                                             uint vid [[vertex_id]])
{
    ProjectedVertex outVert = vertex_project_common(vertices, uniforms, vid);
    outVert.shadowPosition = lightCast.modelViewProjectionMatrix * vertices[vid].position;
    return outVert;
}


fragment float4 fragment_light_shadow(ProjectedVertex vert [[stage_in]],
                                      constant LightUniform &lightUniform [[buffer(0)]],
                                      constant ModelCharacterUniforms &modelCharacterUniforms [[buffer(1)]],
                                      texture2d<float> shadowMap [[texture(0)]],
                                      sampler samplr [[sampler(0)]])
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
        
        colorForLights += diffuseTerm * lightUniform.density[i] + specularTerm * lightUniform.spacular[i];
    }
    
    float2 shadowCoord = float2(vert.shadowPosition.x, vert.shadowPosition.y) / vert.shadowPosition.w;
    shadowCoord.x = (shadowCoord.x + 1) * 0.5;
    shadowCoord.y = (-shadowCoord.y + 1) * 0.5;
    
    float4 shadowDepth = shadowMap.sample(samplr, shadowCoord);
    if (shadowDepth.x < (vert.shadowPosition.z / vert.shadowPosition.w) - 0.001)
    {
        return float4(ambientTerm, modelCharacterUniforms.opacity);
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
            float specularFactor = pow(saturate(dot(normal, halfway)), vert.specularPower);
            transparency *= ((1 - opacity) * (1 - saturate(pow(specularFactor * lightingUniform.spacular[i], 3.0))));
            specularTerm = vert.specularColor * specularFactor;
        }
        
        colorForLights += diffuseTerm * lightingUniform.density[i] + specularTerm * lightingUniform.spacular[i];
    }
    
    if (opacity < 1.0 && transparency < 1.0)
        opacity = 1.0 - transparency;
    
    return float4(ambientTerm + colorForLights, opacity);
}



ProjectedVertex vertex_project_common(device Vertex *vertices [[buffer(0)]],
                                      constant ModelUniforms &uniforms [[buffer(1)]],
                                      uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    
    outVert.position = uniforms.modelViewProjectionMatrix * vertices[vid].position;
    outVert.eye =  -(uniforms.modelViewMatrix * vertices[vid].position).xyz;
    outVert.normal = uniforms.normalMatrix * vertices[vid].normal.xyz;
    
    return outVert;
}


