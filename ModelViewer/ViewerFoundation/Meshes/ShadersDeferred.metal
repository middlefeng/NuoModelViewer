//
//  ShadersAmbient.metal
//  ModelViewer
//
//  Created by Dong on 9/30/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include <metal_stdlib>
#include "ShadersCommon.h"


using namespace metal;

/**
 *  deferred rendering does not have a dedicated vertex shader as it happens on the screen space,
 */



static float do_ambient_occlusion(texture2d<float> positionBuffer, sampler samplr,
                                  float2 tcoord, float2 uv, float3 p, float3 cnorm,
                                  constant NuoAmbientOcclusionUniformField& occlusionUniforms)
{
    float3 diff = positionBuffer.sample(samplr, tcoord + uv).xyz - p;
    const float3 v = normalize(diff);
    const float d = length(diff) * occlusionUniforms.scale;
    return max(0.0, dot(cnorm, v) - occlusionUniforms.bias) * (1.0 / (1.0 + d)) * occlusionUniforms.intensity;
}


fragment float4 fragement_deferred(PositionTextureSimple vert                   [[ stage_in   ]],
                                   texture2d<float> positionBuffer              [[ texture(0) ]],
                                   texture2d<float> normalBuffer                [[ texture(1) ]],
                                   texture2d<float> ambientColor                [[ texture(2) ]],
                                   texture2d<float> shadowOverlay               [[ texture(3) ]],
                                   texture2d<float> immediateResult             [[ texture(4) ]],
                                   sampler samplr                               [[ sampler(0) ]],
                                   constant NuoDeferredRenderUniforms& params   [[ buffer(0)  ]])
{
    const float2 vec[4] =
    {
        float2(1, 0), float2(-1, 0),
        float2(0, 1), float2(0, -1),
    };
    
    constant NuoAmbientOcclusionUniformField& occlusionUniforms = params.ambientOcclusionParams;
    
    float3 p = positionBuffer.sample(samplr, vert.texCoord).xyz;
    float3 n = normalBuffer.sample(samplr, vert.texCoord).xyz;
    float2 ran = rand(vert.texCoord);
    float ao = 0.0f;
    float rad = occlusionUniforms.sampleRadius / p.z;
    
    // SSAO Calculation
    // -- https://www.gamedev.net/articles/programming/graphics/a-simple-and-practical-approach-to-ssao-r2753/
    int iterations = 4;
    for (int j = 0; j < iterations; ++j)
    {
        float2 coord1 = reflect(vec[j], ran) * rad;
        float2 coord2 = float2(coord1.x * 0.707 - coord1.y * 0.707, coord1.x * 0.707 + coord1.y * 0.707);
        
        ao += do_ambient_occlusion(positionBuffer, samplr, vert.texCoord, coord1 * 0.25, p, n, occlusionUniforms);
        ao += do_ambient_occlusion(positionBuffer, samplr, vert.texCoord, coord2 * 0.5, p, n, occlusionUniforms);
        ao += do_ambient_occlusion(positionBuffer, samplr, vert.texCoord, coord1 * 0.75, p, n, occlusionUniforms);
        ao += do_ambient_occlusion(positionBuffer, samplr, vert.texCoord, coord2, p, n, occlusionUniforms);
    }
    
    ao /= (float)iterations * 4.0;
    
    float4 immediateTerm = immediateResult.sample(samplr, vert.texCoord);
    float4 ambientTerm = ambientColor.sample(samplr, vert.texCoord);
    ambientTerm.rgb = (ambientTerm.rgb) * (1.0 - ao);
    
    // when the alpha ambient term does not agree with that the immediate render result, take the lower one.
    // this usually happens in the case of "overlay" objects (e.g. shadow-casting overlay) which are meant to
    // be blended with (non-rendered) enviornment.
    //
    // considering: maybe a special flag to indicate a overlay object. for now, this check works fine
    //
    if (ambientTerm.a > 0.001 && ambientTerm.a > immediateTerm.a)
        ambientTerm.rgb = ambientTerm.rgb / ambientTerm.a * immediateTerm.a;
    
    // shadow-overlay factor is 1.0 for board object, 0.0 for normal objects, and in between on edge through MSAA.
    // a board object contributes to the reduction of alpha in proportion to the ambient illumination (i.e. let the backdrop come through more)
    // a normal object contributes to the addition of diffuse color in proportion to the ambient illumination.
    //
    float shadowOverlayFactor = shadowOverlay.sample(samplr, vert.texCoord).r;
    float shadowOverlayAlpha = color_to_grayscale(ambientTerm.rgb) * shadowOverlayFactor;
    
    // alpha channel composite formula: a1 + a2 - a1 * a2
    //
    float resultAlpha = (params.clearColor.a + immediateTerm.a - params.clearColor.a * immediateTerm.a)
                                             - shadowOverlayAlpha /* reduction of alpha by board objects */;
    
    // color channels composite formula: c1 * a1 + c2 * a2 * (1 - a1)        ; the value is alpha-premultiplied
    //
    float3 resultColor = (ambientTerm.rgb * (1.0 - shadowOverlayFactor) /* addition of diffuse          // these two terms are alpha-premultiplied
                                                                           color by normal objects */   //
                                                   + immediateTerm.rgb) +                               //
                         (params.clearColor.rgb * params.clearColor.a) * (1.0 - immediateTerm.a);
    
    return float4(resultColor, resultAlpha);
}



/**
 *  illumination and ambient from the ray tracer
 */

fragment float4 illumination_blend(PositionTextureSimple vert [[stage_in]],
                                   constant NuoGlobalIlluminationUniforms& params [[buffer(0)]],
                                   texture2d<float> source [[texture(0)]],
                                   texture2d<float> illumination [[texture(1)]],
                                   texture2d<float> shadowOverlayMap [[texture(2)]],
                                   texture2d<float> translucentCoverMap [[texture(3)]],
                                   sampler samplr [[sampler(0)]])
{
    const float4 sourceColor = source.sample(samplr, vert.texCoord);
    const float3 illumiColor = illumination.sample(samplr, vert.texCoord).rgb;
    
    // reduce the ambient reflected by a translucent surface according to its opacity.
    // the ambient of objects covered (semi-blocked) by it is ignored, for it's too hard to calculate in the screen space
    const float translucentCover = translucentCoverMap.sample(samplr, vert.texCoord).a;
    const float3 illuminateEffective = illumiColor * translucentCover;
    
    const float shadowOverlayFactor = shadowOverlayMap.sample(samplr, vert.texCoord).r;
    const float3 color = (sourceColor.rgb + illuminateEffective) * (1 - shadowOverlayFactor);
    
    // calculate the ambient-affected shadow overlay
    //
    // physically based equation:
    //
    //   - alpha: the alpha of the overlay-only object. (this is the result needed)
    //   - C-direct: the direct ligthing without considing shadow casting
    //   - S-direct: the shadow casting of the direct lighting (the direct light being blocked), which is shadowFactor in code,
    //               and has been calculated by ray-tracing and the forward-rendering consdering multi-light-source
    //   - C-ambient-max: the cap of the ambient, meaning there is no occlusion
    //   - C-ambient: the ambient considering occlusion, which is ambientStrength in code. in the previous ray-tracing
    //                stage, this has been computed in relative to C-ambient-max
    //
    //   (C-direct + C-ambient-max)(1 - alpha) = (C-direct - C-direct * S-direct) + C-ambient
    //
    // note that the case is the overlay-only layer is put on top of a real scene (a caputred photo, usually).
    // the color from the real scene is (C-direct + C-ambient-max), and there is no way to estimate C-direct from other
    // parameters. so C-direct has to be given by user from trial-and-error
    //
    // it derives:
    //   alpha = C-direct / (C-direct + C-ambient-max) * S-direct + (C-ambient-max - C-ambient) / (C-direct + C-ambient)
    //
    //
    const float ambientStrength = color_to_grayscale(illuminateEffective);
    const float shadowFactor = sourceColor.a;
    const float shadowWithAmbient = (params.directLightDensity / (params.directLightDensity + params.ambientDensity)) * shadowFactor +
                                    (params.ambientDensity - ambientStrength) / (params.directLightDensity + params.ambientDensity);
    
    
    // shadowOverlayFactor being 1.0 means it is an overlay-only object and shadowWithAmbient is used, being
    // 0.0 means it is a normal object and sourceColor.a is used (the forward-rendering result using the ray-tracing-based
    // direct light shadowing)
    //
    float alpha = sourceColor.a * (1 - shadowOverlayFactor) + shadowWithAmbient * shadowOverlayFactor;
    
    return (float4(color, alpha));
}
