#include <metal_stdlib>
#include <metal_matrix>

using namespace metal;

struct Light
{
    float3 direction1;
    float3 direction2;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

constant Light light = {
    .direction1 = { 0.13, 0.72, 0.68 },
    .direction2 = { 0.13, -0.72, 0.68 },
    .ambientColor = { 0.28, 0.28, 0.28 },
    .diffuseColor = { 1, 1, 1 },
    .specularColor = { 0.5, 0.5, 0.5 }
};

struct Uniforms
{
    float4x4 modelViewProjectionMatrix;
    float4x4 modelViewMatrix;
    float3x3 normalMatrix;
};

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



float4 fragment_light_tex_materialed_common(ProjectedVertex vert [[stage_in]],
                                            float4 diffuseTexel);


fragment float4 fragment_light_tex_a_materialed(ProjectedVertex vert [[stage_in]],
                                                texture2d<float> diffuseTexture [[texture(0)]],
                                                sampler samplr [[sampler(0)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    diffuseTexel = float4(diffuseTexel.rgb / diffuseTexel.a, diffuseTexel.a);
    return fragment_light_tex_materialed_common(vert, diffuseTexel);
}


fragment float4 fragment_light_tex_materialed(ProjectedVertex vert [[stage_in]],
                                              texture2d<float> diffuseTexture [[texture(0)]],
                                              sampler samplr [[sampler(0)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    if (diffuseTexel.a < 1e-9)
        diffuseTexel.rgb = float3(1.0);
    else
        diffuseTexel = diffuseTexel / diffuseTexel.a;
    
    diffuseTexel.a = 1.0;
    return fragment_light_tex_materialed_common(vert, diffuseTexel);
}


fragment float4 fragment_light_tex_materialed_tex_opacity(ProjectedVertex vert [[stage_in]],
                                                          texture2d<float> diffuseTexture [[texture(0)]],
                                                          texture2d<float> opacityTexture [[texture(1)]],
                                                          sampler samplr [[sampler(0)]])
{
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float4 opacityTexel = opacityTexture.sample(samplr, vert.texCoord);
    diffuseTexel = diffuseTexel / diffuseTexel.a;
    diffuseTexel.a = opacityTexel.a;
    return fragment_light_tex_materialed_common(vert, diffuseTexel);
}


float4 fragment_light_tex_materialed_common(ProjectedVertex vert [[stage_in]],
                                            float4 diffuseTexel)
{
    float3 diffuseColor = diffuseTexel.rgb * vert.diffuseColor;
    float3 ambientTerm = light.ambientColor * vert.ambientColor;
    
    float3 normal = normalize(vert.normal);
    float diffuseIntensity1 = saturate(dot(normal, light.direction1));
    float diffuseIntensity2 = saturate(dot(normal, light.direction2));
    
    float3 diffuseTerm1 = light.diffuseColor * diffuseColor * diffuseIntensity1;
    float3 diffuseTerm2 = light.diffuseColor * diffuseColor * diffuseIntensity2;
    float3 diffuseTerm = diffuseTerm1 + diffuseTerm2;
    
    float3 specularTerm1(0), specularTerm2(0);
    if (diffuseIntensity1 > 0)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway1 = normalize(light.direction1 + eyeDirection);
        float specularFactor1 = pow(saturate(dot(normal, halfway1)), vert.specularPowerDisolve.x);
        specularTerm1 = light.specularColor * vert.specularColor * specularFactor1;
    }
    
    if (diffuseIntensity2 > 00)
    {
        float3 eyeDirection = normalize(vert.eye);
        float3 halfway2 = normalize(light.direction2 + eyeDirection);
        float specularFactor2 = pow(saturate(dot(normal, halfway2)), vert.specularPowerDisolve.x);
        specularTerm2 = light.specularColor * vert.specularColor * specularFactor2;
    }
    
    float3 specularTerm = specularTerm1 + specularTerm2;
    
    return float4(ambientTerm + diffuseTerm + specularTerm, diffuseTexel.a * vert.specularPowerDisolve.y);
}

