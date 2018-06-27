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

struct RayBuffer
{
    // fields that compatible with MPSRayOriginMaskDirectionMaxDistance
    //
    packed_float3 origin;
    float minDistance;
    packed_float3 direction;
    float maxDistance;
    
    // cosine base strength factor
    float strength;
};


struct Intersection
{
    float distance;
    int primitiveIndex;
    float2 coordinates;
};


kernel void ray_emit(uint2 tid [[thread_position_in_grid]],
                     constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                     device RayBuffer* rays [[buffer(1)]],
                     device float2* random [[buffer(2)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
    float2 pixelCoord = (float2)tid + r;
    
    const float u = (pixelCoord.x / (float)uniforms.wViewPort) * uniforms.uRange - uniforms.uRange / 2.0;
    const float v = (pixelCoord.y / (float)uniforms.hViewPort) * uniforms.vRange - uniforms.vRange / 2.0;
    
    float4 rayDirection = float4(normalize(float3(u, -v, -1.0)), 0.0);
    
    ray.direction = (uniforms.viewTrans * rayDirection).xyz;
    ray.origin = (uniforms.viewTrans * float4(0.0, 0.0, 0.0, 1.0)).xyz;
    
    ray.minDistance = 0.00001;
    ray.maxDistance = INFINITY;
}



kernel void shadow_ray_emit(uint2 tid [[thread_position_in_grid]],
                            constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                            device RayBuffer* rays [[buffer(1)]],
                            device Intersection *intersections [[buffer(2)]],
                            constant NuoRayTracingUniforms& tracingUniforms [[buffer(3)]],
                            device float2* random [[buffer(4)]],
                            device RayBuffer* shadowRays1 [[buffer(5)]],
                            device RayBuffer* shadowRays2 [[buffer(6)]],
                            texture2d<float, access::write> dstTex [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer& ray = rays[rayIdx];
    
    device RayBuffer* shadowRay[2];
    shadowRay[0] = &shadowRays1[rayIdx];
    shadowRay[1] = &shadowRays2[rayIdx];
    
    for (uint i = 0; i < 2; ++i)
    {
        device RayBuffer* shadowRayCurrent = shadowRay[i];
        
        if (intersection.distance >= 0.0f)
        {
            float distance = tracingUniforms.bounds.span;
            float4 center = tracingUniforms.bounds.center;
            
            float4 lightVec = float4(0.0, 0.0, 1.0, 0.0);
            lightVec = normalize(tracingUniforms.lightSources[i] * lightVec);
            
            float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
            float2 r1 = random[(uint)(r1.x * 256)];
            r = (r * 2.0 - 1.0) * distance * 0.25;
            r1 = (r1 * 2.0 - 1.0);
            
            //if (dot(float3(r1, 1.0),  lightVec.xyz) > 0.9)
            {
            //    r1 = float2(0.0072f, 0.0034f);
            }
            
            //r = float2(0, 0);
            //float3 randomVec = normalize(float3(r.x, r.y, 1.0));
            
            float3 lightPosition = (lightVec.xyz * distance);// + center.xyz;
            float3 lightRight = normalize(cross(lightVec.xyz, float3(r1.x, r1.y, 1.0)));
            float3 lightForward = cross(lightRight, lightVec.xyz);
            
            lightPosition = lightPosition + lightRight * r.x + lightForward * r.y;
            
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            
            //lightVec.xyz = randomVec.x * lightRight + randomVec.y * lightForward + randomVec.z * lightVec.xyz;
            //lightPosition.xyz = lightPosition.xyz + r.x * distance * 0.1 * lightRight + r.y * distance * 0.1 * lightForward;
            float3 shadowVec = normalize(lightPosition.xyz);// - intersectionPoint);
            
            shadowRayCurrent->maxDistance = distance;
            shadowRayCurrent->minDistance = 0.001;
            
            
            shadowRayCurrent->origin = intersectionPoint;
            shadowRayCurrent->direction = shadowVec;
            shadowRayCurrent->strength = dot(lightVec.xyz, shadowVec);
        }
        else
        {
            shadowRayCurrent->maxDistance = -1.0;
        }
    }
}



kernel void shadow_shade(uint2 tid [[thread_position_in_grid]],
                        constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                        device RayBuffer* rays [[buffer(1)]],
                        device Intersection *intersections [[buffer(2)]],
                        device RayBuffer* shadowRays [[buffer(3)]],
                        texture2d<float, access::write> dstTex [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer& shadowRay = shadowRays[rayIdx];
    
    if (intersection.distance >= 0.0f)
    {
        dstTex.write(float4(0.0, 0.0, 0.0, 1.0f) * shadowRay.strength, tid);
    }
    /*else
    {
        dstTex.write(float4(1.0, 1.0, 1.0, 1.0f), tid);
    }*/
}








kernel void intersection_visualize(uint2 tid [[thread_position_in_grid]],
                                   constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                   device RayBuffer* rays [[buffer(1)]],
                                   device Intersection *intersections [[buffer(2)]],
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




kernel void light_direction_visualize(uint2 tid [[thread_position_in_grid]],
                                      constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                      device RayBuffer* rays [[buffer(1)]],
                                      device Intersection *intersections [[buffer(2)]],
                                      constant NuoRayTracingUniforms& tracingUniforms [[buffer(3)]],
                                      texture2d<float, access::write> dstTex [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    
    if (intersection.distance >= 0.0f)
    {
        float4 lightVec = float4(0.0, 0.0, 1.0, 0.0);
        lightVec = tracingUniforms.lightSources[0] * lightVec;
        dstTex.write(float4(lightVec.x, lightVec.y, 0.0, 1.0f), tid);
    }
}



