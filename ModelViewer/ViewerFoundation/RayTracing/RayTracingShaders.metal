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

#define SIMPLE_UTILS_ONLY 1
#include "Meshes/ShadersCommon.h"


using namespace metal;



static RayBuffer primary_ray(matrix44 viewTrans, float3 endPoint)
{
    RayBuffer ray;
    
    float4 rayDirection = float4(normalize(endPoint), 0.0);
    
    ray.direction = (viewTrans * rayDirection).xyz;
    ray.origin = (viewTrans * float4(0.0, 0.0, 0.0, 1.0)).xyz;
    
    return ray;
}




#pragma mark -- Primary / Shadow Ray Emission, General Ray Mask

kernel void primary_ray_emit(uint2 tid [[thread_position_in_grid]],
                             constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                             device RayBuffer* rays [[buffer(1)]],
                             device NuoRayTracingRandomUnit* random [[buffer(2)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    device float2& r = random[(tid.y % 16) * 16 + (tid.x % 16)].uv;
    const float2 pixelCoord = (float2)tid + r;;
    
    const float u = (pixelCoord.x / (float)uniforms.wViewPort) * uniforms.uRange - uniforms.uRange / 2.0;
    const float v = (pixelCoord.y / (float)uniforms.hViewPort) * uniforms.vRange - uniforms.vRange / 2.0;
    
    ray = primary_ray(uniforms.viewTrans, float3(u, -v, -1.0));
    ray.pathScatter = float3(1.0, 1.0, 1.0);
    
    // primary rays are generated with mask as opaque. rays for translucent mask are got by
    // set the mask later by "ray_set_mask"
    //
    ray.mask = kNuoRayMask_Opaue;
    
    ray.bounce = 0;
    ray.primaryHitMask = 0;
    ray.ambientIlluminated = false;
    
    ray.maxDistance = INFINITY;
}



kernel void ray_set_mask(uint2 tid [[thread_position_in_grid]],
                         constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                         device uint* rayMask [[buffer(1)]],
                         device RayBuffer* rays [[buffer(2)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    // rays are used for calculate the ambient, so both translucent and opaque are detected upon.
    // this implies the ambient of objects behind translucent objects is ignored
    //
    ray.mask = *rayMask;
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
                                   device NuoRayTracingRandomUnit* random,
                                   device RayBuffer* shadowRays[2],
                                   metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                                   metal::sampler samplr)
{
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    
    const float maxDistance = tracingUniforms.bounds.span;
    
    device float2& r = random[(tid.y % 16) * 16 + (tid.x % 16)].uv;
    
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
            
            float3 shadowVec = sample_cone_uniform(r, tracingUniforms.lightSources[i].coneAngleCosine);
            shadowVec = align_hemisphere_normal(shadowVec, lightVec.xyz);
            
            shadowRayCurrent->maxDistance = maxDistance;
            
            // either opaque blocker is checked, or no blocker is considered at all (for getting the
            // denominator light amount)
            //
            shadowRayCurrent->mask = kNuoRayMask_Opaue;
            
            NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
            
            float3 normal = material.normal;
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            shadowRayCurrent->origin = intersectionPoint + normalize(normal) * (maxDistance / 20000.0);
            shadowRayCurrent->direction = shadowVec;
            shadowRayCurrent->primaryHitMask = ray.primaryHitMask;
            
            // calculate a specular term which is normalized according to the diffuse term
            //
            
            float specularPower = material.shinessDisolveIllum.x;
            float3 eyeDirection = -ray.direction;
            float3 halfway = normalize(normalize(shadowVec + eyeDirection));
            
            // try to normalize to uphold Cdiff + Cspec < 1.0
            // this is best effort and user trial-and-error as OBJ is not always PBR
            //
            float3 specularColor = material.specularColor * (tracingUniforms.globalIllum.specularMaterialAdjust / 3.0);
            
            float3 diffuseTerm = interpolate_color(materials, diffuseTex, index, intersection, samplr);
            float3 specularTerm = specular_common_physically(specularColor, specularPower,
                                                             shadowVec, normal, halfway);
            
            // the cosine factor is counted into the path scatter term, as the geometric coupling term,
            // because samples are generated from an inifinit distant area light (uniform on a finit
            // contending solid angle)
            //
            // specular and diffuse is normalized and scale as half-half
            //
            shadowRayCurrent->pathScatter = (diffuseTerm + specularTerm) * dot(normal, shadowVec);
            shadowRayCurrent->pathScatter *= tracingUniforms.lightSources[i].density;
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



