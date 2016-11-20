
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
    float2 specularPowerDisolve;
};

vertex ProjectedVertex vertex_project_tex_materialed(device Vertex *vertices [[buffer(0)]],
                                                     constant Uniforms &uniforms [[buffer(1)]],
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
    outVert.specularPowerDisolve = vertices[vid].specularPowerDisolve;
    
    return outVert;
}



float4 fragment_light_tex_materialed_common(ProjectedVertex vert,
                                            constant LightUniform &lighting,
                                            float4 diffuseTexel);


fragment float4 fragment_light_tex_a_materialed(ProjectedVertex vert [[stage_in]],
                                                constant LightUniform &lighting [[buffer(0)]],
                                                texture2d<float> diffuseTexture [[texture(0)]],
                                                sampler samplr [[sampler(0)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    diffuseTexel = float4(diffuseTexel.rgb / diffuseTexel.a, diffuseTexel.a);
    return fragment_light_tex_materialed_common(vert, lighting, diffuseTexel);
}


fragment float4 fragment_light_tex_materialed(ProjectedVertex vert [[stage_in]],
                                              constant LightUniform &lighting [[buffer(0)]],
                                              texture2d<float> diffuseTexture [[texture(0)]],
                                              sampler samplr [[sampler(0)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    if (diffuseTexel.a < 1e-9)
        diffuseTexel.rgb = float3(1.0);
    else
        diffuseTexel = diffuseTexel / diffuseTexel.a;
    
    diffuseTexel.a = 1.0;
    return fragment_light_tex_materialed_common(vert, lighting, diffuseTexel);
}


fragment float4 fragment_light_tex_materialed_tex_opacity(ProjectedVertex vert [[stage_in]],
                                                          constant LightUniform &lighting [[buffer(0)]],
                                                          texture2d<float> diffuseTexture [[texture(0)]],
                                                          texture2d<float> opacityTexture [[texture(1)]],
                                                          sampler samplr [[sampler(0)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float4 opacityTexel = opacityTexture.sample(samplr, vert.texCoord);
    diffuseTexel = diffuseTexel / diffuseTexel.a;
    diffuseTexel.a = opacityTexel.a;
    return fragment_light_tex_materialed_common(vert, lighting, diffuseTexel);
}


float4 fragment_light_tex_materialed_common(ProjectedVertex vert,
                                            constant LightUniform &lightingUniform,
                                            float4 diffuseTexel)
{
    float3 diffuseColor = diffuseTexel.rgb * vert.diffuseColor;
    float opacity = diffuseTexel.a * vert.specularPowerDisolve.y;
    
    float3 ambientTerm = light.ambientColor * vert.ambientColor;
    float3 colorForLights = 0.0;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        float3 lightVector = normalize(lightingUniform.direction[i].xyz);
        
        float3 normal = normalize(vert.normal);
        float diffuseIntensity = saturate(dot(normal, lightVector));
        float3 diffuseTerm = light.diffuseColor * diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(lightVector + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), vert.specularPowerDisolve.x);
            opacity = 1 - (1 - opacity) * (1 - pow(specularFactor, 3.0));
            specularTerm = light.specularColor * vert.specularColor * specularFactor;
        }
        
        colorForLights += (diffuseTerm + specularTerm) * lightingUniform.density[i];
    }
    
    return float4(ambientTerm + colorForLights, opacity);
}

