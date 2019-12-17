

#include "ShadersCommon.h"

using namespace metal;

struct Vertex
{
    float4 position;
    float4 normal;
};

struct ProjectedVertex
{
    float4 positionNDC;
    
    float4 position [[position]];
    float3 eye;
    float3 normal;
    
    float4 shadowPosition0;
    float4 shadowPosition1;
};


/**
 *  3.0 is used to be used to determind how shadow maps are sampled. that crash shaders on macOS
 *  10.15 and 10.14.6 due to unknown driver bugs. reduce the value to 2.0 but add a compensation
 *  factor to maintain the same penumbera effect (yet of course higher level of noise due to the
 *  fewer samples)
 */
constant static float kSampleCount = 2.0; // 3.0 before 10.14.6
constant static float kSampleCountCompensate = ((3.0 /* previous sample count */ * 2.0) + 1.0) /
                                               ((kSampleCount * 2.0) + 1.0);


ProjectedVertex vertex_project_common(device const Vertex *vertices,
                                      constant NuoUniforms &uniforms,
                                      constant NuoMeshUniforms &meshUniform,
                                      uint vid);

float3 fresnel_schlick(float3 specularColor, float3 lightVector, float3 halfway);



/**
 *  shader that generates screen-space position only, used for stencile-based color,
 *  or depth-only rendering (e.g. shadow-map)
 */

vertex PositionSimple vertex_simple(device const Vertex *vertices [[buffer(0)]],
                                    constant NuoUniforms &uniforms [[buffer(1)]],
                                    constant NuoMeshUniforms &meshUniform [[buffer(2)]],
                                    uint vid [[vertex_id]])
{
    return vertex_simple<Vertex>(vertices, uniforms, meshUniform, vid);
}


/**
 *  generate depth map as red-channel color texture (for Metal's forbiding type check)
 */
fragment float4 depth_simple(PositionSimple vert [[stage_in]])
{
    return float4((vert.positionNDC.z / vert.positionNDC.w), 0.0, 0.0, 1.0);
}




/**
 *  shaders that generate phong result without shadow casting,
 *  used for simple annotation.
 */

vertex ProjectedVertex vertex_project(device const Vertex *vertices [[buffer(0)]],
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
    float opacity = modelCharacterUniforms.opacity;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightUniform.lightParams[i];
        
        float cosTheta = saturate(dot(normal, normalize(lightParams.direction.xyz)));
        float3 diffuseTerm = material.diffuseColor * opacity * cosTheta * lightParams.irradiance;
        
        float3 specularTerm(0);
        if (cosTheta > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(normalize(lightParams.direction.xyz) + eyeDirection);
            
            specularTerm = specular_common(material.specularColor, material.specularPower,
                                           lightParams, vert.normal, halfway, cosTheta);
        }
        
        colorForLights += diffuseTerm + specularTerm;
    }
    
    return float4(colorForLights, opacity);
}



#pragma mark -- Screen Space Shaders --


vertex VertexScreenSpace vertex_project_screen_space(device const Vertex *vertices [[buffer(0)]],
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
    result.ambientColorFactor = float4(saturate(vert.diffuseColorFactor * lightUniform.ambient) * vert.opacity, vert.opacity);
    
    result.shadowOverlay = kShadowOverlay ? 1.0 : 0.0;
    
    return result;
}



#pragma mark -- Phong Model Shaders --



/**
 *  shaders that generate phong result with shadow casting,
 */

vertex ProjectedVertex vertex_project_shadow(device const Vertex *vertices [[buffer(0)]],
                                             constant NuoUniforms &uniforms [[buffer(1)]],
                                             constant NuoLightVertexUniforms &lightCast [[buffer(2)]],
                                             constant NuoMeshUniforms &meshUniform [[buffer(3)]],
                                             uint vid [[vertex_id]])
{
    ProjectedVertex outVert = vertex_project_common(vertices, uniforms, meshUniform, vid);
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    outVert.positionNDC = outVert.position;
    outVert.shadowPosition0 = lightCast.lightCastMatrix[0] * meshPosition;
    outVert.shadowPosition1 = lightCast.lightCastMatrix[1] * meshPosition;
    return outVert;
}


fragment float4 fragment_light_shadow(ProjectedVertex vert [[stage_in]],
                                      constant NuoLightUniforms &lightUniform [[buffer(0)]],
                                      constant NuoModelCharacterUniforms &modelCharacterUniforms [[buffer(1)]],
                                      texture_array<2>::t shadowMaps    [[texture(0)]],
                                      texture_array<2>::t shadowMapsExt [[texture(2)]],
                                      texture2d<float> depth            [[texture(4), function_constant(kDepthPrerenderred)]],
                                      sampler samplr [[sampler(0)]])
{
    if (kMeshMode == kMeshMode_Selection)
        return diffuse_lighted_selection(vert.positionNDC, vert.normal, depth, samplr);
    
    float3 normal = normalize(vert.normal);
    float3 colorForLights = 0.0;
    
    float3 shadowOverlay = 0.0;
    float surfaceBrightness = 0.0;
    
    const float4 shadowPosition[2] = {vert.shadowPosition0, vert.shadowPosition1};
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightUniform.lightParams[i];
        
        float cosTheta = saturate(dot(normal, normalize(lightParams.direction.xyz)));
        float3 shadowPercent = float3(0.0);
        if (i < 2)
        {
            float4 shadowPostionCurrent = kShadowRayTracing ? vert.positionNDC : shadowPosition[i];
            const NuoShadowParameterUniformField shadowParams = lightUniform.shadowParams[i];
            shadowPercent = shadow_coverage_common(shadowPostionCurrent, false,
                                                   shadowParams, cosTheta, kSampleCount,
                                                   shadowMaps[i], shadowMapsExt[i], samplr);
        }
        
        if (kMeshMode == kMeshMode_ShadowOccluder || kMeshMode == kMeshMode_ShadowPenumbraFactor)
            return float4(shadowPercent.r, 0.0, 0.0, 1.0);
        
        if (kShadowOverlay)
        {
            shadowOverlay += lightUniform.lightParams[i].irradiance * cosTheta * shadowPercent;
            surfaceBrightness += lightUniform.lightParams[i].irradiance * cosTheta;
        }
        else
        {
            float3 diffuseTerm = material.diffuseColor * cosTheta * lightParams.irradiance;
            
            float3 specularTerm(0);
            if (cosTheta > 0)
            {
                float3 eyeDirection = normalize(vert.eye);
                float3 halfway = normalize(normalize(lightUniform.lightParams[i].direction.xyz) + eyeDirection);
                
                specularTerm = specular_common(material.specularColor, material.specularPower,
                                               lightParams, vert.normal, halfway, cosTheta);
            }
            
            colorForLights += (diffuseTerm + specularTerm) * (1.0 - shadowPercent);
        }
    }
    
    if (kShadowOverlay && kShadowRayTracing)
    {
        return float4(0.0);
    }
    else if (kShadowOverlay)
    {
        /**
         *  the old shadowOverlayMap is abandaned (see comments in the deferred-blending shader),
         *  though they should never have been used in the real-time result in the first place
         *
        // the primitive coverage on the pixel
        float shadowOverlayCoverage = shadowOverlayMap.sample(samplr, ndc_to_texture_coord(vert.positionNDC)).r;
        
        // this happens when a translucent object blocking the overlay-only object
        if (shadowOverlayCoverage < 0.000001)
            shadowOverlayCoverage = 1.0;

        // anti-alias compensation by being divided by shadowOverlayCoverage
        //
        // the shadowOverlayCoverage/surfaceBrightness has already taken in acount the anti-aliasing when it is
        // computed through ray tracing. if being returned from this fragement shader, it will be subject to the
        // MSAA by the pipeline. to avoid this mistaken anti-aliasing double-blending, the value should be divided
        // by the primitive coverage (in order to get its pre-anti-aliasing value, at least approximately)
        // */
        float shadowOverlayStrength = color_to_grayscale(shadowOverlay);
        return float4(0.0, 0.0, 0.0, shadowOverlayStrength / surfaceBrightness);
    }
    else
    {
        return float4(colorForLights, modelCharacterUniforms.opacity);
    }
}


float4 fragment_light_tex_materialed_common(VertexFragmentCharacters vert,
                                            constant NuoLightUniforms &lightingUniform,
                                            texture_array<2>::t shadowMaps,
                                            texture_array<2>::t shadowMapsExt,
                                            sampler samplr)
{
    // for transparent objects, the blending formula is
    //   Cfront + Cback * (1 - opacity), where Cfront = Cdiff * opacity + Cspec
    //
    // note that whether or not to multiple a reflectance by the opacity is arbitrary, yet most existing
    // model files define in such a way that the Cdiff should be down-scaled, but the Cspec should not
    
    float3 colorForLights = 0.0;
    
    for (unsigned i = 0; i < 4; ++i)
    {
        const NuoLightParameterUniformField lightParams = lightingUniform.lightParams[i];
        
        float3 lightVector = normalize(lightParams.direction.xyz);
        float cosTheta = saturate(dot(vert.normal, lightVector));
        float3 diffuseTerm = vert.diffuseColor * vert.opacity * cosTheta * lightParams.irradiance;
        
        float3 shadowPercent = float3(0.0);
        if (i < 2)
        {
            const float4 shadowPositionCurrent = kShadowRayTracing ?
                                                    vert.projectedNDC : vert.shadowPosition[i];
            
            const NuoShadowParameterUniformField shadowParams = lightingUniform.shadowParams[i];
            shadowPercent = shadow_coverage_common(shadowPositionCurrent, vert.opacity < 1.0,
                                                   shadowParams, cosTheta, kSampleCount,
                                                   shadowMaps[i], shadowMapsExt[i], samplr);
            
            if (kMeshMode == kMeshMode_ShadowOccluder || kMeshMode == kMeshMode_ShadowPenumbraFactor)
                return float4(shadowPercent.r, 0.0, 0.0, 1.0);
        }
        
        float3 specularTerm(0);
        if (cosTheta > 0)
        {
            float3 eyeDirection = normalize(vert.eye);
            float3 halfway = normalize(lightVector + eyeDirection);
            
            specularTerm = specular_common(vert.specularColor, vert.specularPower,
                                           lightParams, vert.normal, halfway, cosTheta);
        }
        
        colorForLights += (diffuseTerm + specularTerm) * (1 - shadowPercent);
    }
    
    return float4(colorForLights, vert.opacity);
}



ProjectedVertex vertex_project_common(device const Vertex *vertices,
                                      constant NuoUniforms &uniforms,
                                      constant NuoMeshUniforms &meshUniform,
                                      uint vid [[vertex_id]])
{
    ProjectedVertex outVert;
    float4 meshPosition = meshUniform.transform * vertices[vid].position;
    float4 eyePosition = uniforms.viewMatrixInverse * float4(0.0, 0.0, 0.0, 1.0);
    float3 meshNormal = meshUniform.normalTransform * vertices[vid].normal.xyz;
    
    outVert.position = uniforms.viewProjectionMatrix * meshPosition;
    outVert.positionNDC = outVert.position;
    outVert.eye =  eyePosition.xyz - meshPosition.xyz;
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



// see p233 real-time rendering, 3rd
// see https://seblagarde.wordpress.com/2011/08/17/hello-world/
//
float3 fresnel_schlick(float3 specularColor, float3 lightVector, float3 halfway)
{
    return specularColor + (1.0f - specularColor) * pow(1.0f - saturate(dot(lightVector, halfway)), 5.0);
}


float3 specular_refectance_normalized(float3 specularReflectance, float materialSpecularPower,
                                      float3 lightDirection, float3 halfway)
{
    return fresnel_schlick(specularReflectance, lightDirection, halfway) *
            ((materialSpecularPower + 8.0) / 8.0);
}


// see p257, (7.49) real-time rendering, 3rd
// the code embodies the half-vector based specular which is ((m + 8) / (8 * pi)) * Cspecular * power(cos(theta), m)
//               p253 (7.47) the reflection based version is ((m + 2) / (2 * pi)) * Cspecular * power(cos(reflection), m)
//
// for the details of how the above normalization term is deduced, see http://www.farbrausch.de/%7Efg/stuff/phong.pdf
//          the reflection based version could be deduced by simple integral: cos^m(x)sin(x)dx = -cos^(m+1)d(cos(x))
//          the half-vector based version is an approximation, to a more complicated integral form.
//          a ((m + 2) / (8 * pi)) factor is given in https://seblagarde.wordpress.com/2011/08/17/hello-world/
//
float3 specular_common_physically(float3 specularReflectance, float materialSpecularPower,
                                  float3 lightDirection, float3 normal, float3 halfway)
{
    float cosNHPower = pow(saturate(dot(normal, halfway)), materialSpecularPower);
    return specular_refectance_normalized(specularReflectance, materialSpecularPower,
                                          lightDirection, halfway) * cosNHPower;
}


// D(wh) = (m + 1.0) / (2.0 * pi)) * power(cos(theta), m)
// f = fresnel_schlick * D(wh) / (4 * dot(wi, wh) * max(dot(wi, n), dot(wo, n))
// http://www.pbr-book.org/3ed-2018/Reflection_Models/Fresnel_Incidence_Effects.html
//
float3 specular_fresnel_incident(float3 specularReflectance, float materialSpecularPower,
                                 float3 lightDirection, float3 exitent)
{
    float3 wh = normalize(lightDirection + exitent);
    float cosNHPower = pow(saturate(abs(wh.y)), materialSpecularPower);
    return fresnel_schlick(specularReflectance, lightDirection, wh) *
           ((materialSpecularPower + 1.0) / 2.0) * cosNHPower /
           (4 * dot(lightDirection, wh) * metal::max(abs(lightDirection.y), abs(exitent.y)));
}


// specular_common() returns (radiance * pi), because that saves some calculation and the 1/pi factor
// in radiance is usually cancelled by the outside integral
//
float3 specular_common(float3 materialSpecularColor, float materialSpecularPower,
                       NuoLightParameterUniformField lightParams,
                       float3 normal, float3 halfway, float cosTheta)
{
    // in order to uphold the energy conservativeness, the following invarant need to be kept:
    //   adjustedCsepcular + diffuseColor < 1.0
    //
    // some poorly materialed model do not hold it, which is why a slider is put the UI.
    // the range of the slider is [0, 3.0] for historical reason, which is why it is divided by 3.0
    //
    float3 adjustedCsepcular = materialSpecularColor * lightParams.specular / 3.0;
    
    if (kPhysicallyReflection)
    {
        return specular_common_physically(adjustedCsepcular, materialSpecularPower,
                                          lightParams.direction.xyz, normal, halfway)
                * cosTheta * lightParams.irradiance;
    }
    else
    {
        float cosNHPower = pow(saturate(dot(normal, halfway)), materialSpecularPower);
        return adjustedCsepcular * cosNHPower * cosTheta * lightParams.irradiance;
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
    
    const float sampleEnlargeFactor = occluderRadius * kSampleCountCompensate;
    
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




float3 shadow_coverage_common(metal::float4 shadowCastModelPostion, bool translucent,
                              NuoShadowParameterUniformField shadowParams, float cosTheta, float shadowMapSampleRadius,
                              metal::texture2d<float> shadowMap,
                              metal::texture2d<float> shadowMapExt,   // extra maps needed by ray-tracing
                              metal::sampler samplr)
{
    if (kShadowRayTracing)
    {
        float4 shadowCoverage = translucent ? shadowMapExt.sample(samplr, ndc_to_texture_coord(shadowCastModelPostion)) :
                                              shadowMap.sample(samplr, ndc_to_texture_coord(shadowCastModelPostion));
        return shadowCoverage.rgb;
    }
    
    float shadowMapBias = 0.002;
    shadowMapBias += shadowParams.bias * (1 - cosTheta);
    
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
            sampleSize = kSampleSizeBase * 0.3 + sampleSize * kSampleCountCompensate * (penumbraFactor * 5  * shadowParams.soften);
        
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
            return float3(shadowPercent);
        }
        
        return float3(0.0);
    }
    else
    {
        /** simpler shadow without PCF
         */
        return float3(shadowMap.sample(samplr, shadowCoord).r < modelDepth ? 1 : 0);
    }
}



#pragma mark -- Utility Functions



float2 rand(float2 co)
{
    return normalize(float2(fract(sin(dot(float2(co.x, co.y / 2.0), float2(12.9898, 78.233))) * 43758.5453),
                            fract(sin(dot(float2(co.y, co.x / 2.0), float2(12.9898, 78.233))) * 43758.5453)));
}


float2 ndc_to_texture_coord(float4 ndc)
{
    float2 result = ndc.xy / ndc.w;
    return float2((result.x + 1) * 0.5, (-result.y + 1) * 0.5);
}


float color_to_grayscale(float3 color)
{
    return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722;
}


float3 safe_divide(float3 dividee, float3 divider)
{
    // if dividee is never greater than the divider, and the latter is too small,
    // use 1.0 (rather than use zero)
    
    float3 result = float3(1.0);
    
    for (uint i = 0; i < 3; ++i)
    {
        if (divider[i] > 0.00001)   // avoid divided by zero
            result[i] = saturate(dividee[i] / divider[i]);
    }
    
    return result;
}
