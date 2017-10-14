
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
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};


vertex PositionSimple vertex_shadow_materialed(device Vertex *vertices [[buffer(0)]],
                                               constant NuoUniforms &uniforms [[buffer(1)]],
                                               constant NuoMeshUniforms &meshUniforms [[buffer(2)]],
                                               uint vid [[vertex_id]])
{
    PositionSimple outShadow;
    outShadow.position = uniforms.viewProjectionMatrix * meshUniforms.transform * vertices[vid].position;
    return outShadow;
}


#pragma mark -- Phong Model Shaders --


vertex ProjectedVertex vertex_project_materialed(device Vertex *vertices [[buffer(0)]],
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
    
    outVert.ambientColor = vertices[vid].ambientColor;
    outVert.diffuseColor = vertices[vid].diffuseColor;
    outVert.specularColor = vertices[vid].specularColor;
    outVert.specularPowerDisolve = vertices[vid].specularPowerDisolve;
    
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    
    return outVert;
}

fragment float4 fragment_light_materialed(ProjectedVertex vert [[stage_in]],
                                          constant NuoLightUniforms &lightUniform [[buffer(0)]],
                                          depth2d<float> shadowMap0 [[texture(0)]],
                                          depth2d<float> shadowMap1 [[texture(1)]],
                                          sampler depthSamplr [[sampler(0)]])
{
    float3 normal = normalize(vert.normal);
    float3 diffuseColor = vert.diffuseColor;
    
    float3 colorForLights = 0.0;
    
    depth2d<float> shadowMap[2] = {shadowMap0, shadowMap1};
    const float4 shadowPosition[2] = {vert.shadowPosition0, vert.shadowPosition1};
    
    float opacity = vert.specularPowerDisolve.y;
    float transparency = (1 - opacity);
    
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
            
            specularTerm = specular_common(vert.specularColor, vert.specularPowerDisolve.x,
                                           lightParams, normal, halfway, diffuseIntensity);
            transparency *= ((1 - saturate(pow(length(specularTerm), 1.0))));
        }
        
        float shadowPercent = 0.0;
        if (i < 2)
        {
            const NuoShadowParameterUniformField shadowParams = lightUniform.shadowParams[i];
            shadowPercent = shadow_coverage_common(shadowPosition[i],
                                                   shadowParams, diffuseIntensity, 3,
                                                   shadowMap[i], depthSamplr);
            
            if (kMeshMode == kMeshMode_ShadowOccluder || kMeshMode == kMeshMode_ShadowPenumbraFactor)
                return float4(shadowPercent, 0.0f, 0.0f, 1.0f);
        }
        
        colorForLights += (diffuseTerm * lightParams.density + specularTerm) *
                          (1 - shadowPercent);
    }
    
    return float4(colorForLights, 1.0 - transparency);
}


#pragma mark -- Screen Space Shaders --


vertex VertexScreenSpace vertex_screen_space_materialed(device Vertex *vertices [[buffer(0)]],
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
    result.diffuseColorFactor = vertices[vid].diffuseColor.rgb;
    result.opacity = vertices[vid].specularPowerDisolve.y;
    
    return result;
}

