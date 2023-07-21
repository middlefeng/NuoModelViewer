//
//  RayTracingHybridShaders.metal
//  ModelViewer
//
//  Created by middleware on 9/17/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include <metal_stdlib>

#include "NuoRayTracingUniform.h"
#include "RayTracingShadersCommon.h"

#define SIMPLE_UTILS_ONLY 1
#include "Meshes/ShadersCommon.h"



using namespace metal;



struct IlluminateTargets
{
    texture2d<float, access::read_write> overlayResult                  [[id(0)]];
    texture2d<float, access::read_write> overlayForVirtual              [[id(1)]];
    texture2d<float, access::read_write> overlayForVirtualWithoutBlock  [[id(2)]];
};



static void self_illumination(uint2 tid,
                              device RayStructureUniform& structUniform,
                              device IlluminateTargets& targets,
                              constant NuoRayTracingUniforms& tracingUniforms,
                              device RayBuffer* incidentRays,
                              device NuoRayTracingRandomUnit* random,
                              device MaterialTextures* diffuseTex,
                              sampler samplr);



kernel void primary_ray_process_hybrid(uint2 tid [[thread_position_in_grid]],
                                       device RayStructureUniform& structUniform [[buffer(0)]],
                                       device IlluminateTargets& targets,
                                       constant NuoRayTracingUniforms& tracingUniforms,
                                       device NuoRayTracingRandomUnit* random,
                                       device RayBuffer* shadowRays0,
                                       device RayBuffer* shadowRays1,
                                       device MaterialTextures* diffuseTex,
                                       sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = structUniform.intersections[rayIdx];
    
    structUniform.exitantRays[rayIdx].primaryHitMask = surface_mask(rayIdx, structUniform);
    RayBuffer cameraRay = structUniform.exitantRays[rayIdx];
    
    device RayBuffer* shadowRays[] = { shadowRays0, shadowRays1 };
    device NuoRayTracingRandomUnit& randomVars = random[(tid.y % 16) * 16 + (tid.x % 16)];
    
    // directional light sources in the scene definition are considered area lights with finite
    // subtending solid angles, in far distance
    //
    for (uint i = 0; i < 2; ++i)
    {
        device RayBuffer* shadowRay = &shadowRays[i][rayIdx];
        shadow_ray_emit_infinite_area(cameraRay, intersection, structUniform, tracingUniforms,
                                      i, i + 1, /* sample on the i-th light source */
                                      randomVars, shadowRay, diffuseTex, samplr);
    }
    
    // ambient lighting on virtual surfaces as if no normal object present
    //
    if (cameraRay.mask == kNuoRayMask_Virtual)
    {
        ambient_with_no_block(tid, structUniform, tracingUniforms, cameraRay, intersection, randomVars,
                              targets.overlayForVirtualWithoutBlock, diffuseTex, samplr);
    }
}


kernel void primary_and_incident_ray_process(uint2 tid [[thread_position_in_grid]],
                                             device RayStructureUniform& structUniform [[buffer(0)]],
                                             device IlluminateTargets& targets,
                                             constant NuoRayTracingUniforms& tracingUniforms,
                                             device NuoRayTracingRandomUnit* random,
                                             device RayBuffer* shadowRays0,
                                             device RayBuffer* shadowRays1,
                                             device RayBuffer* incidentRaysBuffer,
                                             device MaterialTextures* textures,
                                             sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    structUniform.exitantRays[rayIdx].primaryHitMask = surface_mask(rayIdx, structUniform);
    RayBuffer cameraRay = structUniform.exitantRays[rayIdx];
    
    device RayBuffer* shadowRays[] = { shadowRays0, shadowRays1 };
    device NuoRayTracingRandomUnit& r = random[(tid.y % 16) * 16 + (tid.x % 16)];
    device Intersection & intersection = structUniform.intersections[rayIdx];
    
    // directional light sources in the scene definition are considered area lights with finite
    // subtending solid angles, in far distance
    //
    for (uint i = 0; i < 2; ++i)
    {
        device RayBuffer* shadowRay = &shadowRays[i][rayIdx];
        shadow_ray_emit_infinite_area(cameraRay, intersection, structUniform, tracingUniforms,
                                      i, i + 1, /* sample on the i-th light source */
                                      r, shadowRay, textures, samplr);
    }
    
    self_illumination(tid, structUniform, targets,
                      tracingUniforms, incidentRaysBuffer,
                      random, textures, samplr);
}



kernel void incident_ray_process_hybrid(uint2 tid [[thread_position_in_grid]],
                                        device RayStructureUniform& structUniform [[buffer(0)]],
                                        device IlluminateTargets& targets,
                                        constant NuoRayTracingUniforms& tracingUniforms,
                                        device NuoRayTracingRandomUnit* random,
                                        device MaterialTextures* textures,
                                        sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    self_illumination(tid, structUniform, targets,
                      tracingUniforms, structUniform.exitantRays /* incident rays are the
                                                                    exitant rays of the next path */,
                      random, textures, samplr);
}


// informative name for the lighting result texture index
//
enum LightingType
{
    kLighting_WithoutBlock = 0,
    kLighting_WithBlock,
};
    

struct ShadowTargets
{
    texture_array<2, access::write>::t lightForOpaque  [[id(0)]];
    texture_array<2, access::write>::t lightForTrans   [[id(2)]];
    texture_array<2, access::write>::t lightForVirtual [[id(4)]];
};


kernel void shadow_contribute(uint2 tid [[thread_position_in_grid]],
                              device RayStructureUniform& structUniform [[buffer(0)]],
                              device ShadowTargets& targets,
                              device uint* shadeIndex)
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    
    device Intersection& intersection = structUniform.intersections[rayIdx];
    device RayBuffer& shadowRay = structUniform.exitantRays[rayIdx];
    
    texture_array<2, access::write>::t lightsDst[] = { targets.lightForOpaque,
                                                       targets.lightForTrans,
                                                       targets.lightForVirtual };
    
    device uint& targetIndex = *shadeIndex;
    
    // normal surfaces
    //
    if (targetIndex < 2)
    {
        if (color_to_grayscale(shadowRay.pathScatter) > 0)
        {
            /**
             *  to generate a shadow map (rather than illuminating), the light transportation is integrand
             *
             *  previous comment before pbr-book reading:
             *      the total diffuse (with all blockers virtually removed) and the amount that considers
             *      blockers are recorded, and therefore accumulated by a subsequent accumulator.
             */
            if ((shadowRay.primaryHitMask & kNuoRayMask_Virtual) == 0)
                lightsDst[targetIndex][kLighting_WithoutBlock].write(float4(shadowRay.pathScatter, 1.0), tid);
            
            if (intersection.distance > 0.0f)
            {
                if (shadowRay.primaryHitMask & kNuoRayMask_Virtual)
                {
                    lightsDst[kNuoRayIndex_OnVirtual][kLighting_WithBlock].write(float4(shadowRay.pathScatter, 1.0), tid);
                    lightsDst[targetIndex][kLighting_WithBlock].write(float4(float3(0.0), 1.0), tid);
                }
                else
                {
                    lightsDst[targetIndex][1].write(float4(shadowRay.pathScatter, 1.0), tid);
                }
            }
        }
    }
    
    // virtual surfaces (not considering block)
    
    if (targetIndex == kNuoRayIndex_OnVirtual)
    {
        if (color_to_grayscale(shadowRay.pathScatter) > 0.0)
            lightsDst[kNuoRayIndex_OnVirtual][kLighting_WithoutBlock].write(float4(shadowRay.pathScatter, 1.0), tid);
        
        if (shadowRay.maxDistance < 0.0)
            lightsDst[kNuoRayIndex_OnVirtual][kLighting_WithoutBlock].write(float4(float3(1.0), 1.0), tid);
    }
}



kernel void shadow_illuminate(uint2 tid [[thread_position_in_grid]],
                              texture_array<2, access::read>::t lightForOpaque [[texture(0)]],
                              texture_array<2, access::read>::t lightForTrans  [[texture(2)]],
                              texture_array<2, access::write>::t dstTex [[texture(4)]])
{
    if (!(tid.x < dstTex[0].get_width() && tid.y < dstTex[0].get_height()))
        return;
    
    texture_array<2, access::read>::t lights[] = { lightForOpaque, lightForTrans };
    
    for (uint lightType = 0; lightType < 2; ++lightType)
    {
        float3 illuminate = lights[lightType][0].read(tid).rgb;
        float3 block = lights[lightType][1].read(tid).rgb;
        float3 shadowPercent = safe_divide(block, illuminate);
        
        dstTex[lightType].write(float4((shadowPercent), 1.0), tid);
    }
}



kernel void lighting_accumulate(uint2 tid [[thread_position_in_grid]],
                                texture_array<2, access::read>::t lightingWithoutBlock,
                                texture_array<2, access::read>::t lightingWithBlock,
                                texture2d<float, access::write> resultWithoutBlock,
                                texture2d<float, access::write> resultWithBlock)
{
    if (!(tid.x < resultWithoutBlock.get_width() && tid.y < resultWithoutBlock.get_height()))
        return;
    
    for (uint i = 0; i < 2; ++i)
    {
        float3 illuminate = lightingWithoutBlock[0].read(tid).rgb +
                            lightingWithoutBlock[1].read(tid).rgb;
        resultWithoutBlock.write(float4(illuminate, 1.0), tid);
        
        illuminate = lightingWithBlock[0].read(tid).rgb +
                     lightingWithBlock[1].read(tid).rgb;
        resultWithBlock.write(float4(illuminate, 1.0), tid);
    }
}


    
/**
 *  write the result of illuminating surface and ambient
 */
static void overlayWrite(uint hitType, float4 value, uint2 tid,
                         device IlluminateTargets& targets)
{
    texture2d<float, access::read_write> texture = (hitType & kNuoRayMask_Virtual)?
                                                    targets.overlayForVirtual : targets.overlayResult;
    
    threadgroup_barrier(mem_flags::mem_texture);
    
    const float4 color = texture.read(tid);
    const float4 result = float4(color.rgb + value.rgb, saturate(color.a + value.a));
    texture.write(result, tid);
}


void self_illumination(uint2 tid,
                       device RayStructureUniform& structUniform,
                       device IlluminateTargets& targets,
                       constant NuoRayTracingUniforms& tracingUniforms,
                       device RayBuffer* incidentRays,
                       device NuoRayTracingRandomUnit* random,
                       device MaterialTextures* textures,
                       sampler samplr)
{
    constant NuoRayTracingGlobalIlluminationParam& globalIllum = tracingUniforms.globalIllum;
    
    unsigned int rayIdx = tid.y * structUniform.rayUniform.wViewPort + tid.x;
    device Intersection& intersection = structUniform.intersections[rayIdx];
    device NuoRayTracingMaterial* materials = structUniform.materials;
    device uint* index = structUniform.index;
    device RayBuffer& incidentRay = incidentRays[rayIdx];
    
    // make a copy from the exitant rays buffer as the same buffer might be used as
    // incident rays buffer
    //
    const RayBuffer ray = structUniform.exitantRays[rayIdx];
    
    if (intersection.distance >= 0.0f)
    {
        const float maxDistance = tracingUniforms.bounds.span;
        const float ambientRadius = maxDistance / 5.0 * (1.0 - globalIllum.ambientRadius * 0.5);
        
        unsigned int triangleIndex = intersection.primitiveIndex;
        device uint* vertexIndex = index + triangleIndex * 3;
        float3 color = interpolate_color(materials, textures, index, intersection, samplr);
        
        int illuminate = materials[*(vertexIndex)].shinessDisolveIllum.z;
        if (illuminate == 0)
        {
            color = color * ray.pathScatter * globalIllum.illuminationStrength * 10.0;
            
            // old comment regarding the light source sampling vs. reflection sampling:
            //   for bounced ray, multiplied with the integral base (2 PI, or the hemisphre)
            //   as there is no primary ray
            //
            // which seems not true and commented out (the 10.0 multiplication above is the
            // parameter range compensation for the removal of 2.0 * M_PI
            //
            // if (ray.bounce > 0)
            //     color = 2.0f * M_PI_F * color;
            
            // clap the value or the anti-alias on object discontinuity will fail.
            // (the problem exists on bounced path as well, but monte carlo does not have a way
            // to handle that case, becuase it cannot predict the converged value)
            //
            if (ray.bounce == 0)
                color = saturate(color);
            
            overlayWrite(ray.primaryHitMask, float4(color, 1.0), tid, targets);
            
            incidentRay.maxDistance = -1;
        }
        else
        {
            device NuoRayTracingRandomUnit& randomVars = random[(tid.y % 16) * 16 + (tid.x % 16) + 256 * ray.bounce];
            NuoRayTracingMaterial material = interpolate_full_material(materials, textures,
                                                                       tracingUniforms.globalIllum.specularMaterialAdjust / 3.0,
                                                                       index, intersection, samplr);
            
            RayBuffer currentIncident;
            sample_scatter_ray(maxDistance, randomVars, intersection, material, ray, currentIncident);
            incidentRay = currentIncident;
        }
        
        if (ray.bounce > 0)
        {
            float ambientFactor = ambient_distance_factor(ambientRadius / 20.0, ambientRadius,
                                                          intersection.distance, 1.0);
            
            if (!ray.ambientOccluded && ambientFactor > 0)
            {
                color = ray.pathScatter * globalIllum.ambient * ambientFactor;
                overlayWrite(ray.primaryHitMask, float4(color, 1.0), tid, targets);
            }
            else
            {
                incidentRay.ambientOccluded = true;
            }
        }
    }
    else if (ray.maxDistance > 0)
    {
        if (ray.bounce > 0 && !ray.ambientOccluded)
        {
            float3 color = ray.pathScatter * globalIllum.ambient;
            overlayWrite(ray.primaryHitMask, float4(color, 1.0), tid, targets);
        }
        else if (ray.bounce == 0)
        {
            targets.overlayForVirtual.write(float4(globalIllum.ambient, 1.0), tid);
        }
        
        incidentRay.maxDistance = -1;
    }
}

