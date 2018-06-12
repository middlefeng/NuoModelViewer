//
//  NuoRayTracingShaders.metal
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "NuoRayTracingUniform.h"


using namespace metal;

/**
 *  MPSRayIntersector data type - MPSRayOriginMaskDirectionMaxDistance
 *
 *  (No reliable way of including the MPS framework headers)
 */

struct RayWithMask
{
    // fields that compatible with MPSRayOriginMaskDirectionMaxDistance
    //
    packed_float3 origin;
    uint mask;
    packed_float3 direction;
    float maxDistance;
    
    // additional info
    //
    float3 color;
};


kernel void ray_emit(uint2 tid [[thread_position_in_grid]],
                     constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                     device RayWithMask* rays [[buffer(1)]],
                     device float2* random [[buffer(2)]],
                     texture2d<float, access::write> dstTex [[texture(1)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayWithMask& ray = rays[rayIdx];
    
    const float u = (tid.x / (float)uniforms.wViewPort) * uniforms.uRange - uniforms.uRange / 2.0;
    const float v = (tid.y / (float)uniforms.hViewPort) * uniforms.vRange - uniforms.vRange / 2.0;
    
    ray.direction = normalize(float3(u, v, -1.0));
    ray.origin = float3(0.0, 0.0, 0.0);
    
    ray.mask = 0;
    ray.maxDistance = INFINITY;
    
    dstTex.write(float4(0.0f, 0.0f, 0.0f, 0.0f), tid);
}
