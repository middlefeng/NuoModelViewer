

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
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};


ProjectedVertex vertex_project_common(device Vertex *vertices,
                                      constant NuoUniforms &uniforms,
                                      constant NuoMeshUniforms &meshUniform,
                                      uint vid [[vertex_id]]);

float3 fresnel_schlick(float3 specularColor, float3 lightVector, float3 halfway);



/**
 *  shader that generates screen-space position only, used for stencile-based color,
 *  or depth-only rendering (e.g. shadow-map)
 */

vertex PositionSimple vertex_simple(device Vertex *vertices [[buffer(0)]],
                                    constant NuoUniforms &uniforms [[buffer(1)]],
                                    constant NuoMeshUniforms &meshUniform [[buffer(2)]],
                                    uint vid [[vertex_id]])
{
    return vertex_simple<Vertex>(vertices, uniforms, meshUniform, vid);
}


fragment float4 depth_simple(PositionSimple vert [[stage_in]])
{
    return float4((vert.positionNDC.z / vert.positionNDC.w), 0.0, 0.0, 1.0);
}




/**
 *  shaders that generate phong result without shadow casting,
 *  used for simple annotation.
 */

vertex ProjectedVertex vertex_project(device Vertex *vertices [[buffer(0)]],
                                      constant NuoUniforms &uniforms [[buffer(1)]],
                                      constant NuoMeshUniforms &meshUniform [[buffer(2)]],
                                      uint vid [[vertex_id]])
{
    return vertex_project_common(vertices, uniforms, meshUniform, vid);
}



fragment float4 fragment_light(ProjectedVertex vert [[stage_in]],
                               constant NuoLightUniforms &lightUniform [[buffer(0)]],
                               constant NuoModelCharacterUniforms &modelCharacterUniforms [[buffer(1)]],
                               sampler samplr [[sampler(0)]])
{
    float3 normal = normalize(vert.normal);
    float3 colorForLights = 0.0;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightUniform.lightParams[i];
        
        float diffuseIntensity = saturate(dot(normal, normalize(lightParams.direction.xyz)));
        float3 diffuseTerm = material.diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(normalize(lightParams.direction.xyz) + eyeDirection);
            float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
            specularTerm = material.specularColor * specularFactor;
        }
        
        colorForLights += diffuseTerm * lightParams.density + specularTerm * lightParams.spacular;
    }
    
    return float4(colorForLights, modelCharacterUniforms.opacity);
}



#pragma mark -- Screen Space Shaders --


vertex VertexScreenSpace vertex_project_screen_space(device Vertex *vertices [[buffer(0)]],
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


fragment FragementScreenSpace fragement_screen_space(VertexScreenSpace vert [[stage_in]],
                                                     constant NuoLightUniforms& lightUniform [[ buffer(0) ]])
{
    FragementScreenSpace result;
    result.position = vert.position;
    result.normal = vert.normal;
    result.ambientColorFactor = float4(saturate(vert.diffuseColorFactor * lightUniform.ambientDensity) * vert.opacity, vert.opacity);
    
    result.shadowOverlay = kShadowOverlay ? 1.0 : 0.0;
    
    return result;
}



#pragma mark -- Phong Model Shaders --



/**
 *  shaders that generate phong result with shadow casting,
 */

vertex ProjectedVertex vertex_project_shadow(device Vertex *vertices [[buffer(0)]],
                                             constant NuoUniforms &uniforms [[buffer(1)]],
                                             constant NuoLightVertexUniforms &lightCast [[buffer(2)]],
                                             constant NuoMeshUniforms &meshUniform [[buffer(3)]],
                                             uint vid [[vertex_id]])
{
    ProjectedVertex outVert = vertex_project_common(vertices, uniforms, meshUniform, vid);
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    return outVert;
}


fragment float4 fragment_light_shadow(ProjectedVertex vert [[stage_in]],
                                      constant NuoLightUniforms &lightUniform [[buffer(0)]],
                                      constant NuoModelCharacterUniforms &modelCharacterUniforms [[buffer(1)]],
                                      texture2d<float> shadowMap0 [[texture(0)]],
                                      texture2d<float> shadowMap1 [[texture(1)]],
                                      sampler samplr [[sampler(0)]])
{
    float3 normal = normalize(vert.normal);
    float3 colorForLights = 0.0;
    
    float shadowOverlay = 0.0;
    float surfaceBrightness = 0.0;
    
    texture2d<float> shadowMap[2] = {shadowMap0, shadowMap1};
    const float4 shadowPosition[2] = {vert.shadowPosition0, vert.shadowPosition1};
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightUniform.lightParams[i];
        
        float diffuseIntensity = saturate(dot(normal, normalize(lightParams.direction.xyz)));
        float shadowPercent = 0.0;
        if (i < 2)
        {
            const NuoShadowParameterUniformField shadowParams = lightUniform.shadowParams[i];
            shadowPercent = shadow_coverage_common(shadowPosition[i],
                                                   shadowParams, diffuseIntensity, 3,
                                                   shadowMap[i], samplr);
        }
        
        if (kMeshMode == kMeshMode_ShadowOccluder || kMeshMode == kMeshMode_ShadowPenumbraFactor)
            return float4(shadowPercent, 0.0, 0.0, 1.0);
        
        if (kShadowOverlay)
        {
            shadowOverlay += lightUniform.lightParams[i].density * diffuseIntensity * shadowPercent;
            surfaceBrightness += lightUniform.lightParams[i].density * diffuseIntensity;
        }
        else
        {
            float3 diffuseTerm = material.diffuseColor * diffuseIntensity;
            
            float3 specularTerm(0);
            if (diffuseIntensity > 0)
            {
                float3 eyeDirection = normalize(vert.eye);
                float3 halfway = normalize(normalize(lightUniform.lightParams[i].direction.xyz) + eyeDirection);
                float specularFactor = pow(saturate(dot(normal, halfway)), material.specularPower);
                specularTerm = material.specularColor * specularFactor;
            }
            
            colorForLights += (diffuseTerm * lightParams.density +
                               specularTerm * lightParams.spacular) * (1.0 - shadowPercent);
        }
    }
    
    if (kShadowOverlay)
        return float4(0.0, 0.0, 0.0, shadowOverlay / surfaceBrightness);
    else
        return float4(colorForLights, modelCharacterUniforms.opacity);
}


float4 fragment_light_tex_materialed_common(VertexFragmentCharacters vert,
                                            float3 normal,
                                            constant NuoLightUniforms &lightingUniform,
                                            float4 diffuseTexel,
                                            texture2d<float> shadowMap[2],
                                            sampler samplr)
{
    normal = normalize(normal);
    
    float3 diffuseColor = diffuseTexel.rgb * vert.diffuseColor;
    float opacity = diffuseTexel.a * vert.opacity;
    
    float3 colorForLights = 0.0;
    
    float transparency = (1 - opacity);
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightingUniform.lightParams[i];
        
        float3 lightVector = normalize(lightParams.direction.xyz);
        float diffuseIntensity = saturate(dot(normal, lightVector));
        float3 diffuseTerm = diffuseColor * diffuseIntensity;
        
        float3 specularTerm(0);
        if (diffuseIntensity > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(lightVector + eyeDirection);
            
            specularTerm = specular_common(vert.specularColor, vert.specularPower,
                                           lightParams, normal, halfway, diffuseIntensity);
            transparency *= ((1 - saturate(pow(length(specularTerm), 1.0))));
        }
        
        float shadowPercent = 0.0;
        if (i < 2)
        {
            const NuoShadowParameterUniformField shadowParams = lightingUniform.shadowParams[i];
            shadowPercent = shadow_coverage_common(vert.shadowPosition[i],
                                                   shadowParams, diffuseIntensity, 3,
                                                   shadowMap[i], samplr);
            
            if (kMeshMode == kMeshMode_ShadowOccluder || kMeshMode == kMeshMode_ShadowPenumbraFactor)
                return float4(shadowPercent, 0.0, 0.0, 1.0);
        }
        
        colorForLights += (diffuseTerm * lightParams.density + specularTerm) *
                          (1 - shadowPercent);
    }
    
    return float4(colorForLights, 1.0 - transparency);
}



ProjectedVertex vertex_project_common(device Vertex *vertices,
                                      constant NuoUniforms &uniforms,
                                      constant NuoMeshUniforms &meshUniform,
                                      uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    float3 meshNormal = meshUniform.normalTransform * vertices[vid].normal.xyz;
    
    outVert.position = uniforms.viewProjectionMatrix * meshPosition;
    outVert.eye =  -(uniforms.viewMatrix * meshPosition).xyz;
    outVert.normal = meshNormal;
    
    return outVert;
}



float4 diffuse_lighted_selection(float4 vertPositionNDC, float3 normal,
                                 texture2d<float> depth, sampler depthSamplr)
{
    float2 screenPos = vertPositionNDC.xy / vertPositionNDC.w;
    screenPos.x = (screenPos.x + 1) * 0.5;
    screenPos.y = (-screenPos.y + 1) * 0.5;
    
    float depthSample = depth.sample(depthSamplr, screenPos).r;
    float indicatorDepth = vertPositionNDC.z / vertPositionNDC.w;
    
    // light always comes from the direct front
    //
    const float3 lightVector = float3(0.0, 0.0, 1.0);
    
    // as light coming from front, a negative diffuse intensity means the normal
    // should be reversed to show the object's front most surface (even when it is
    // back facing).
    //
    float diffuseIntensity = saturate(dot(normal, lightVector));
    if (diffuseIntensity <= 0)
        diffuseIntensity = saturate(dot(-normal, lightVector));
    
    if (depthSample > indicatorDepth - 0.001)
        return float4(float3(0.0, 0.8, 0.0) * diffuseIntensity, 0.30);
    else
        return float4(float3(0.8, 0.0, 0.0) * diffuseIntensity, 0.15);
}



float4 diffuse_common(float4 diffuseTexel, float extraOpacity)
{
    if (kAlphaChannelInSeparatedTexture)
    {
        diffuseTexel = diffuseTexel / diffuseTexel.a;
        diffuseTexel.a = extraOpacity;
    }
    else if (kAlphaChannelInTexture)
    {
        diffuseTexel = float4(diffuseTexel.rgb / diffuseTexel.a, diffuseTexel.a);
    }
    else
    {
        if (diffuseTexel.a < 1e-9)
            diffuseTexel.rgb = float3(1.0);
        else
            diffuseTexel = diffuseTexel / diffuseTexel.a;
        
        diffuseTexel.a = 1.0;
    }
    
    return diffuseTexel;
}



// see p233 real-time rendering
// see https://seblagarde.wordpress.com/2011/08/17/hello-world/
//
float3 fresnel_schlick(float3 specularColor, float3 lightVector, float3 halfway)
{
    return specularColor + (1.0f - specularColor) * pow(1.0f - saturate(dot(lightVector, halfway)), 5);
}


float3 specular_common(float3 materialSpecularColor, float materialSpecularPower,
                       NuoLightParameterUniformField lightParams,
                       float3 normal, float3 halfway, float dotNL)
{
    float dotNHPower = pow(saturate(dot(normal, halfway)), materialSpecularPower);
    float specularFactor = dotNHPower * dotNL;
    float3 adjustedCsepcular = materialSpecularColor * lightParams.spacular;
    
    if (kPhysicallyReflection)
    {
        return fresnel_schlick(adjustedCsepcular / 3.0, lightParams.direction.xyz, halfway) *
               ((materialSpecularPower + 2) / 8) * specularFactor * lightParams.density;
    }
    else
    {
        return adjustedCsepcular * specularFactor;
    }
}



float shadow_penumbra_factor(const float2 texelSize, float shadowMapSampleRadius, float occluderRadius,
                             float shadowMapBias, float modelDepth, float2 shadowCoord,
                             metal::texture2d<float> shadowMap, metal::sampler samplr)
{
    float penumbraFactor = 1.0;
    float blocker = 0;
    int blockerSampleCount = 0;
    int blockerSampleSkipped = 0;
    
    const float sampleEnlargeFactor = occluderRadius;
    
    const float2 searchSampleSize = texelSize * sampleEnlargeFactor;
    const float2 searchRegion = shadowMapSampleRadius * 2 * searchSampleSize;
    const float searchDiameter = shadowMapSampleRadius * 2 * 2;
    const float sampleDiameter = length(texelSize);
    
    float xCurrentSearch = shadowCoord.x - searchRegion.x;
    
    for (int i = 0; i < searchDiameter; ++i)
    {
        float yCurrentSearch = shadowCoord.y - searchRegion.y;
        for (int j = 0; j < searchDiameter; ++j)
        {
            float shadowDepth = shadowMap.sample(samplr, float2(xCurrentSearch, yCurrentSearch)).r;
            if (shadowDepth < modelDepth - shadowMapBias * length(shadowCoord - float2(xCurrentSearch, yCurrentSearch)) / sampleDiameter)
            {
                blockerSampleCount += 1;
                blocker += shadowDepth;
            }
            else
            {
                blockerSampleSkipped += 1;
            }
            
            yCurrentSearch += searchSampleSize.y;
        }
        
        xCurrentSearch += searchSampleSize.x;
    }
    
    /* not turning on this short cut because the penumbra-factor is clamp to a
     * small positive number to alliveate the shadow-map-sampling alias
     *
     if (blockerSampleCount == 0)
     return 0.0;
    
    if (blockerSampleSkipped == 0)
        return 1.0; */
    
    blocker /= blockerSampleCount;
    penumbraFactor = (modelDepth - blocker) / blocker;
    
    if (kMeshMode == kMeshMode_ShadowOccluder)
        return (modelDepth - blocker) * 10.0;
    
    // in order to alliveate alias, always present a bit softness
    //
    return max(0.02, penumbraFactor);
}




float shadow_coverage_common(metal::float4 shadowCastModelPostion,
                             NuoShadowParameterUniformField shadowParams, float shadowedSurfaceAngle, float shadowMapSampleRadius,
                             metal::texture2d<float> shadowMap, metal::sampler samplr)
{
    float shadowMapBias = 0.002;
    shadowMapBias += shadowParams.bias * (1 - shadowedSurfaceAngle);
    
    const float2 kSampleSizeBase = 1.0 / float2(shadowMap.get_width(), shadowMap.get_height());
    float2 sampleSize = kSampleSizeBase;
    if (!kShadowPCSS && kShadowPCF)
        sampleSize *= shadowParams.soften;
    
    float2 shadowCoord = shadowCastModelPostion.xy / shadowCastModelPostion.w;
    shadowCoord.x = (shadowCoord.x + 1) * 0.5;
    shadowCoord.y = (-shadowCoord.y + 1) * 0.5;
    
    float modelDepth = (shadowCastModelPostion.z / shadowCastModelPostion.w) - shadowMapBias;
    
    if (kShadowPCF)
    {
        // find PCSS blocker and calculate the penumbra factor according to it
        //
        float penumbraFactor = 1.0;
        if (kShadowPCSS)
        {
            penumbraFactor = shadow_penumbra_factor(kSampleSizeBase, shadowMapSampleRadius, shadowParams.occluderRadius,
                                                    shadowMapBias, modelDepth, shadowCoord,
                                                    shadowMap, samplr);
            
            if (kMeshMode == kMeshMode_ShadowOccluder || kMeshMode == kMeshMode_ShadowPenumbraFactor)
                return penumbraFactor;
        }
        
        float shadowCoverage = 0;
        int shadowSampleCount = 0;
        
        // PCSS-based penumbra
        //
        if (kShadowPCSS)
            sampleSize = kSampleSizeBase * 0.3 + sampleSize * (penumbraFactor * 5  * shadowParams.soften);
        
        const float2 shadowRegion = shadowMapSampleRadius * sampleSize;
        const float shadowDiameter = shadowMapSampleRadius * 2;
        const float sampleDiameter = length(float2(sampleSize));
        
        float xCurrent = shadowCoord.x - shadowRegion.x;
        
        for (int i = 0; i < shadowDiameter; ++i)
        {
            float yCurrent = shadowCoord.y - shadowRegion.y;
            for (int j = 0; j < shadowDiameter; ++j)
            {
                shadowSampleCount += 1;
                
                float2 current = float2(xCurrent, yCurrent) +
                                    // randomized offset to avoid quantization
                                    (rand(shadowCastModelPostion.xy * shadowCastModelPostion.z + float2(i + j)) - 0.5) *
                                    sampleDiameter * 1.5;
                
                // increase the shadow bias in proportion to the distance to the sampling point
                //
                if (kShadowPCSS)
                {
                    if (shadowMap.sample(samplr, current).r <
                           modelDepth + shadowMapBias -
                           shadowMapBias * length(current - shadowCoord) / length(kSampleSizeBase))
                    {
                        shadowCoverage += 1;
                    }
                }
                else
                {
                    if (shadowMap.sample(samplr, current).r <
                           modelDepth -
                           shadowMapBias * length(current - shadowCoord) / length(kSampleSizeBase))
                    {
                        shadowCoverage += 1;
                    }
                }
                
                yCurrent += sampleSize.y;
            }
            
            xCurrent += sampleSize.x;
        }
        
        if (shadowCoverage > 0)
        {
            /* these interesting code come from somewhere being forgotten.
             * cause some artifact
             *
            float l = saturate(smoothstep(0, 0.2, shadowedSurfaceAngle));
            float t = smoothstep((rand(shadowCastModelPostion.x + shadowCastModelPostion.y)) * 0.5, 1.0f, l);
            
            float shadowPercent = shadowCoverage / (float)shadowSampleCount * t; */
            
            float shadowPercent = shadowCoverage / (float)shadowSampleCount;
            return shadowPercent;
        }
        
        return 0.0;
    }
    else
    {
        /** simpler shadow without PCF
         */
        return shadowMap.sample(samplr, shadowCoord).r < modelDepth ? 1 : 0;
    }
}


float2 rand(float2 co)
{
    return normalize(float2(fract(sin(dot(float2(co.x, co.y / 2.0), float2(12.9898, 78.233))) * 43758.5453),
                            fract(sin(dot(float2(co.y, co.x / 2.0), float2(12.9898, 78.233))) * 43758.5453)));
}



