
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
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};

/**
 *   shader that generates screen-space position only, used for stencile-based color,
 *   or depth-only rendering (e.g. shadow-map)
 */

vertex PositionSimple vertex_simple_textured(device Vertex *vertices [[buffer(0)]],
                                             constant NuoUniforms &uniforms [[buffer(1)]],
                                             constant NuoMeshUniforms &meshUniforms [[buffer(2)]],
                                             uint vid [[vertex_id]])
{
    return vertex_simple<Vertex>(vertices, uniforms, meshUniforms, vid);
}


#pragma mark -- SCreen Space Shaders --


vertex VertexScreenSpace vertex_screen_space_textured(device Vertex *vertices [[buffer(0)]],
                                                      constant NuoUniforms &uniforms [[buffer(1)]],
                                                      constant NuoMeshUniforms &meshUniform [[buffer(3)]],
                                                      uint vid [[vertex_id]])
{
    VertexScreenSpace result;
    
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    float3 meshNormal = meshUniform.normalTransform * vertices[vid].normal.xyz;
    
    result.projectedPosition = uniforms.viewProjectionMatrix * meshPosition;
    result.position =  uniforms.viewMatrix * meshPosition;
    result.normal = float4(meshNormal, 1.0);
    result.diffuseColorFactor = material.diffuseColor;
    result.opacity = 1.0;
    
    return result;
}


fragment FragementScreenSpace fragement_screen_space_textured(VertexScreenSpace vert [[stage_in]],
                                                              constant NuoLightUniforms& lightUniform [[ buffer(0) ]],
                                                              texture2d<float> diffuseTexture [[ texture(0) ]],
                                                              sampler samplr [[ sampler(0) ]])
{
    FragementScreenSpace result;
    result.position = vert.position;
    result.normal = vert.normal;
    
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float3 diffuseColor = diffuseTexel.rgb / diffuseTexel.a;
    float alpha = diffuseTexel.a * vert.opacity;
    result.ambientColorFactor = float4(saturate(vert.diffuseColorFactor * diffuseColor * lightUniform.ambientDensity) * alpha, alpha);
    
    result.shadowOverlay = kShadowOverlay ? 1.0 : 0.0;
    
    return result;
}


#pragma mark -- Phong Model Shaders --


vertex ProjectedVertex vertex_project_textured(device Vertex *vertices [[buffer(0)]],
                                               constant NuoUniforms &uniforms [[buffer(1)]],
                                               constant NuoLightVertexUniforms &lightCast [[buffer(2)]],
                                               constant NuoMeshUniforms &meshUniforms [[buffer(3)]],
                                               uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    
    float4 meshPosition = meshUniforms.transform * vertices[vid].position;
    outVert.position = uniforms.viewProjectionMatrix * meshPosition;
    outVert.eye =  -(uniforms.viewMatrix * meshPosition).xyz;
    outVert.normal = meshUniforms.normalTransform * vertices[vid].normal.xyz;
    outVert.texCoord = vertices[vid].texCoord;
    
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    
    return outVert;
}


fragment float4 fragment_light_textured(ProjectedVertex vert [[stage_in]],
                                        constant NuoLightUniforms &lightUniform [[buffer(0)]],
                                        depth2d<float> shadowMap0 [[texture(0)]],
                                        depth2d<float> shadowMap1 [[texture(1)]],
                                        texture2d<float> diffuseTexture [[texture(2)]],
                                        sampler depthSamplr [[sampler(0)]],
                                        sampler samplr [[sampler(1)]])
{
    float3 normal = normalize(vert.normal);
    float4 diffuseTexel = diffuseTexture.sample(samplr, vert.texCoord);
    float3 diffuseColor = diffuseTexel.rgb / diffuseTexel.a;
    
    float3 colorForLights = 0.0;
    
    depth2d<float> shadowMap[2] = {shadowMap0, shadowMap1};
    const float4 shadowPosition[2] = {vert.shadowPosition0, vert.shadowPosition1};
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightUniform.lightParams[i];
        
        float diffuseIntensity = saturate(dot(normal, normalize(lightParams.direction.xyz)));
        float3 diffuseTerm = diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(normalize(lightParams.direction.xyz) + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower) * diffuseIntensity;
            specularTerm = material.specularColor * specularFactor;
        }
        
        float shadowPercent = 0.0;
        if (i < 2)
        {
            const NuoShadowParameterUniformField shadowParams = lightUniform.shadowParams[i];
            shadowPercent = shadow_coverage_common(shadowPosition[i],
                                                   shadowParams, diffuseIntensity, 3,
                                                   shadowMap[i], depthSamplr);
        }
        
        colorForLights += (diffuseTerm * lightParams.density + specularTerm * lightParams.spacular) * (1 - shadowPercent);
    }
    
    return float4(colorForLights, diffuseTexel.a);
}

