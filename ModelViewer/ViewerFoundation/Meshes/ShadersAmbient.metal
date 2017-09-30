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
                                  float scale, float ambientBias, float intensity)
{
    float3 diff = positionBuffer.sample(samplr, tcoord + uv).xyz - p;
    const float3 v = normalize(diff);
    const float d = length(diff) * scale;
    return max(0.0, dot(cnorm,v) - ambientBias) * (1.0 / (1.0 + d)) * intensity;
}


fragment ambient_occlusion(PS_INPUT i)
{
    PS_OUTPUT o = (PS_OUTPUT)0;
    o.color.rgb = 1.0f;
    const float2 vec[4] = {    float2(1, 0),float2(-1, 0),
        float2(0, 1),float2(0, -1) };
    
    float3 p = getPosition(i.uv);
    float3 n = getNormal(i.uv);
    float2 rand = getRandom(i.uv);
    float ao = 0.0f;
    float rad = g_sample_rad / p.z;
    
    //**SSAO Calculation**//
    int iterations = 4;
    for (int j = 0; j < iterations; ++j)
    {
        float2 coord1 = reflect(vec[j], rand) * rad;
        float2 coord2 = float2(coord1.x * 0.707 - coord1.y * 0.707, coord1.x * 0.707 + coord1.y * 0.707);
        
        ao += doAmbientOcclusion(i.uv, coord1 * 0.25, p, n);
        ao += doAmbientOcclusion(i.uv, coord2 * 0.5, p, n);
        ao += doAmbientOcclusion(i.uv, coord1 * 0.75, p, n);
        ao += doAmbientOcclusion(i.uv, coord2, p, n);
    }
    
    ao /= (float)iterations * 4.0;
    
    //**END**//
    //Do stuff here with your occlusion value AcaoAc: modulate ambient lighting, write it to a buffer for later //use, etc.
    return o;
}
