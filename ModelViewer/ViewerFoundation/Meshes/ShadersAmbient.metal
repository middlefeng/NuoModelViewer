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



static float do_ambient_occlusion(texture2d<float> positionBuffer, sampler samplr,
                                  float2 tcoord, float2 uv, float3 p, float3 cnorm,
                                  constant NuoAmbientOcclusionUniforms& occlusionUniforms)
{
    float3 diff = positionBuffer.sample(samplr, tcoord + uv).xyz - p;
    const float3 v = normalize(diff);
    const float d = length(diff) * occlusionUniforms.scale;
    return max(0.0, dot(cnorm,v) - occlusionUniforms.bias) * (1.0 / (1.0 + d)) * occlusionUniforms.intensity;
}


fragment float ambient_occlusion(PositionTextureSimple vert         [[ stage_in   ]],
                                 texture2d<float> positionBuffer    [[ texture(0) ]],
                                 texture2d<float> normalBuffer      [[ texture(1) ]],
                                 sampler samplr                     [[ sampler(0) ]],
                                 constant NuoAmbientOcclusionUniforms& occlusionUniforms [[ buffer(0)  ]])
{
    const float2 vec[4] =
    {
        float2(1, 0), float2(-1, 0),
        float2(0, 1), float2(0, -1),
    };
    
    float3 p = positionBuffer.sample(samplr, vert.texCoord).xyz;
    float3 n = normalBuffer.sample(samplr, vert.texCoord).xyz;
    float2 ran = rand(vert.texCoord);
    float ao = 0.0f;
    float rad = occlusionUniforms.sampleRadius / p.z;
    
    // SSAO Calculation
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
    
    return ao;
}
