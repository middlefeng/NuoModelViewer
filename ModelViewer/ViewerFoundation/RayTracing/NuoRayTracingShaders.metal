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


struct Intersection
{
    float distance;
    int primitiveIndex;
    float2 coordinates;
};


kernel void ray_emit(uint2 tid [[thread_position_in_grid]],
                     constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                     device RayWithMask* rays [[buffer(1)]],
                     device float2* random [[buffer(2)]],
                     texture2d<float, access::write> dstTex [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayWithMask& ray = rays[rayIdx];
    
    float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
    float2 pixelCoord = (float2)tid + r;
    
    const float u = (pixelCoord.x / (float)uniforms.wViewPort) * uniforms.uRange - uniforms.uRange / 2.0;
    const float v = (pixelCoord.y / (float)uniforms.hViewPort) * uniforms.vRange - uniforms.vRange / 2.0;
    
    float4 rayDirection = float4(normalize(float3(u, -v, -1.0)), 0.0);
    
    ray.direction = (uniforms.viewTrans * rayDirection).xyz;
    ray.origin = (uniforms.viewTrans * float4(0.0, 0.0, 0.0, 1.0)).xyz;
    
    ray.mask = 0;
    ray.maxDistance = INFINITY;
    
    dstTex.write(float4(0.0f, 0.0f, 0.0f, 0.0f), tid);
}




kernel void shade_function(uint2 tid [[thread_position_in_grid]],
                           constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                           device Intersection *intersections [[buffer(1)]],
                           texture2d<float, access::write> dstTex [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    
    if (intersection.distance >= 0.0f)
    {
        dstTex.write(float4(1.0, 0.0, 0.0, 1.0f), tid);
    }
}
