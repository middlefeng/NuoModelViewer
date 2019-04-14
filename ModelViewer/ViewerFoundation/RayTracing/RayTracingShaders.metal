//
//  NuoRayTracingShaders.metal
//  ModelViewer
//
//  Created by middleware on 6/11/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "NuoRayTracingUniform.h"
#include "RayTracingShadersCommon.h"


using namespace metal;




#pragma mark -- Primary / Shadow Ray Emission, General Ray Mask

kernel void primary_ray_emit(uint2 tid [[thread_position_in_grid]],
                             constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                             device RayBuffer* rays [[buffer(1)]],
                             device float2* random [[buffer(2)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    const float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
    const float2 pixelCoord = (float2)tid + r;;
    
    const float u = (pixelCoord.x / (float)uniforms.wViewPort) * uniforms.uRange - uniforms.uRange / 2.0;
    const float v = (pixelCoord.y / (float)uniforms.hViewPort) * uniforms.vRange - uniforms.vRange / 2.0;
    
    float4 rayDirection = float4(normalize(float3(u, -v, -1.0)), 0.0);
    
    ray.direction = (uniforms.viewTrans * rayDirection).xyz;
    ray.origin = (uniforms.viewTrans * float4(0.0, 0.0, 0.0, 1.0)).xyz;
    ray.color = float3(1.0, 1.0, 1.0);
    
    // primary rays are generated with mask as opaque. rays for translucent mask are got by
    // set the mask later by "ray_set_mask"
    //
    ray.mask = kNuoRayMask_Opaue;
    
    ray.bounce = 0;
    ray.ambientIlluminated = false;
    
    ray.maxDistance = INFINITY;
}



kernel void ray_set_mask(uint2 tid [[thread_position_in_grid]],
                         constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                         device RayBuffer* rays [[buffer(1)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    if (kShadowOnTranslucent)
    {
        // rays are used for calculate the ambient, so both translucent and opaque are detected upon.
        // this implies the ambient of objects behind translucent objects is ignored
        //
        ray.mask = kNuoRayMask_Translucent | kNuoRayMask_Opaue;
    }
    else
    {
        ray.mask = kNuoRayMask_Opaue;
    }
}


kernel void ray_set_mask_illuminating(uint2 tid [[thread_position_in_grid]],
                                      constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                      device RayBuffer* rays [[buffer(1)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    ray.mask = kNuoRayMask_Illuminating;
}


void shadow_ray_emit_infinite_area(uint2 tid,
                                   constant NuoRayVolumeUniform& uniforms,
                                   device RayBuffer& ray,
                                   device uint* index,
                                   device NuoRayTracingMaterial* materials,
                                   device Intersection& intersection,
                                   constant NuoRayTracingUniforms& tracingUniforms,
                                   device float2* random,
                                   device RayBuffer* shadowRays[2])
{
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    
    const float maxDistance = tracingUniforms.bounds.span;
    
    float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
    
    for (uint i = 0; i < 2; ++i)
    {
        device RayBuffer* shadowRayCurrent = shadowRays[i] + rayIdx;
        
        // initialize the buffer's path scatter fields
        // (took 2 days to figure this out after spot the problem in debugger 8/21/2018)
        //
        shadowRayCurrent->pathScatter = 0.0f;
        
        if (intersection.distance >= 0.0f)
        {
            float4 lightVec = float4(0.0, 0.0, 1.0, 0.0);
            lightVec = normalize(tracingUniforms.lightSources[i].direction * lightVec);
            
            float maxThetaTan = tracingUniforms.lightSources[i].radius / 2.0 * 0.25;  // sacle factor to maintain backward-compatibility
            float maxThetaCos = (1 / metal::sqrt(maxThetaTan * maxThetaTan + 1));

            float3 shadowVec = sample_cone_uniform(r, maxThetaCos);
            shadowVec = align_hemisphere_normal(shadowVec, lightVec.xyz);
            
            shadowRayCurrent->maxDistance = maxDistance;
            shadowRayCurrent->mask = kNuoRayMask_Opaue;
            
            float3 normal = interpolate_material(materials, index, intersection).normal;
            
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            shadowRayCurrent->origin = intersectionPoint + normalize(normal) * (maxDistance / 20000.0);
            shadowRayCurrent->direction = shadowVec;
            
            // only the cosine factor is counted into the path scatter term, because samples are generated
            // from an inifinit distant area light (uniform on a finit contending solid angle) and used
            // as a scale map. no need to take into account the distance (constant) and the other cosine
            // (always 1). BRDF diffuse is assumed 1 because this is a scale map.
            //
            // todo: brdf specular term is not considered
            shadowRayCurrent->pathScatter = dot(normal, shadowVec);
        }
        else
        {
            shadowRayCurrent->maxDistance = -1.0;
        }
    }
}




#pragma mark -- Debug Tools


/**
 *  debug tools
 */

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
        lightVec = tracingUniforms.lightSources[0].direction * lightVec;
        dstTex.write(float4(lightVec.x, lightVec.y, 0.0, 1.0f), tid);
    }
}



