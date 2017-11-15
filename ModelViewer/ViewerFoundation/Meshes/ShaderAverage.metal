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
