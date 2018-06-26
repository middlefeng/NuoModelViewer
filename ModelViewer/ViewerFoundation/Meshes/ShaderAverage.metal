//
//  ShaderAverage.metal
//  ModelViewer
//
//  Created by Dong on 11/12/17.
//  Copyright © 2017 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "ShadersCommon.h"

using namespace metal;



fragment float4 fragment_texutre_average(PositionTextureSimple vert [[stage_in]],
                                         texture2d<float> textureAccumulated [[texture(0)]],
                                         texture2d<float> textureLatest [[texture(1)]],
                                         constant int& averageCount [[buffer(0)]],
                                         sampler samplr [[sampler(0)]])
{
    float4 colorAccumulated = textureAccumulated.sample(samplr, vert.texCoord);
    colorAccumulated *= (averageCount - 1) / (float)averageCount;
    
    float4 color = textureLatest.sample(samplr, vert.texCoord);
    color /= (float)averageCount;
    
    return color + colorAccumulated;
}






kernel void compute_texutre_average(uint2 tid [[thread_position_in_grid]],
                                    texture2d<float, access::read_write> textureAccumulated [[texture(0)]],
                                    texture2d<float, access::read> textureLatest [[texture(1)]],
                                    constant uint32_t& averageCount [[buffer(0)]])
{
    if (tid.x >= textureAccumulated.get_width(0) ||
        tid.y >= textureAccumulated.get_height(0))
    {
        return;
    }
    
    float4 colorAccumulated = float4(0);
    if (averageCount > 1)
        colorAccumulated = textureAccumulated.read(tid) * (averageCount - 1);
    
    float4 color = textureLatest.read(tid);
    textureAccumulated.write((color + colorAccumulated) / (float)averageCount, tid);
}


kernel void compute_texture_copy(uint2 tid [[thread_position_in_grid]],
                                 texture2d<float, access::read_write> target [[texture(0)]],
                                 texture2d<float, access::read> source [[texture(1)]])
{
    if (tid.x >= target.get_width(0) ||
        tid.y >= target.get_height(0))
    {
        return;
    }
    
    target.write(source.read(tid), tid);
}
