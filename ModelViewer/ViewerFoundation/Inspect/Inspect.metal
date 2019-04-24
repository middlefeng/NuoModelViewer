//
//  Inspect.metal
//  ModelViewer
//
//  Created by middleware on 9/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include <metal_stdlib>
#include "Meshes/NuoUniforms.h"

#define NO_SHADERS_COMMON_FUNCTION_CONSTANTS 1
#define NO_RAY_TRACING_FUNCTIONS 1

#include "Meshes/ShadersCommon.h"
#include "RayTracing/RayTracingShadersCommon.h"


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



kernel void compute_visualize_ray_direction(uint2 tid [[thread_position_in_grid]],
                                            constant NuoRangeUniform& range [[buffer(0)]],
                                            device RayBuffer* rays [[buffer(1)]],
                                            texture2d<float, access::read_write> result)
{
    if (!(tid.x < range.w && tid.y < range.h))
        return;
    
    unsigned int rayIdx = tid.y * range.w + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    float3 rayNormalized = (ray.direction + 1.0) / 2.0;/*float3(0,//ray.direction[0] * 2.0 + 1.0,
                                  0,//ray.direction[1] * 2.0 + 1.0,
                                  ray.direction[2] * 2.0 + 1.0);*/
    
    result.write(float4(rayNormalized, 1.0), tid);
}
