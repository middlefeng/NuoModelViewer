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
                                   texture2d<float> immediateResult             [[ texture(3) ]],
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
    
    float resultAlpha = params.clearColor.a + immediateTerm.a - params.clearColor.a * immediateTerm.a;
    float3 resultColor = (ambientTerm.rgb + immediateTerm.rgb) /* these two terms are alpha-premultiplied */ +
                         (params.clearColor.rgb * params.clearColor.a) * (1.0 - immediateTerm.a);
    
    return float4(resultColor, resultAlpha);
}



