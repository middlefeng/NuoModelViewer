//
//  Inspect.metal
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include <metal_stdlib>
#include "Meshes/ShadersCommon.h"


using namespace metal;


fragment float4 fragment_checker(PositionTextureSimple vert [[stage_in]])
{
    int row = (int)(vert.position.x / 20) % 2;
    int col = (int)(vert.position.y / 20) % 2;
    
    float4 color = (row == col)? float4(1.0, 1.0, 1.0, 1.0) : float4(0.85, 0.85, 0.85, 1.0);
    return color;
}



fragment float4 fragment_alpha(PositionTextureSimple vert [[stage_in]],
                               texture2d<float> texture [[texture(0)]],
                               sampler samplr [[sampler(0)]])
{
    float4 color = texture.sample(samplr, vert.texCoord);
    return float4(float3(0), color.a);
}



fragment float4 fragment_g(PositionTextureSimple vert [[stage_in]],
                           texture2d<float> texture [[texture(0)]],
                           sampler samplr [[sampler(0)]])
{
    float4 color = texture.sample(samplr, vert.texCoord);
    return float4(float3(0), color.g);
}



fragment float4 fragment_r(PositionTextureSimple vert [[stage_in]],
                           texture2d<float> texture [[texture(0)]],
                           sampler samplr [[sampler(0)]])
{
    float4 color = texture.sample(samplr, vert.texCoord);
    return float4(float3(0), color.r);
}
