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



struct RayTracingTargets
{
    texture2d<float, access::read_write> lightingTracing [[id(0)]];
    texture2d<float, access::read_write> overlayForVirtual;
    texture2d<float, access::read_write> overlayForVirtualWithoutBlock;
    texture2d<float, access::read_write> lightingVirtual;
    texture2d<float, access::read_write> lightingVirtualBlocked;
    texture2d<float, access::read_write> modelMask;
};



static void self_illumination(uint2 tid,
                              device RayStructureUniform& structUniform,
                              constant NuoRayTracingUniforms& tracingUniforms,
                              device RayBuffer* shadowRay,
                              device RayBuffer* incidentRays,
                              device NuoRayTracingRandomUnit* random,
                              device RayTracingTargets& targets,
                              array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                              sampler samplr);

static void lightingTrcacingWrite(uint2 tid, float3 value,
                                  texture2d<float, access::read_write> texture);


void spawn_ray(device const RayBuffer& ray, device RayBuffer& spawn, float distance, float skip);


#pragma mark -- Visibilities Test


kernel void ray_visibility_init(uint2 tid [[thread_position_in_grid]],
                                device RayStructureUniform& structUniform [[buffer(0)]],
                                constant NuoRayTracingUniforms& tracingUniforms,
                                device RayBuffer* spawnRays,
                                device float3* visibilities)
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = structUniform.intersections[rayIdx];
    device const RayBuffer& startRay = structUniform.exitantRays[rayIdx];
    device RayBuffer& spawnRay = spawnRays[rayIdx];
    
    uint mask = surface_mask(rayIdx, structUniform);
    
    if ((intersection.distance >= 0.0) && (mask & kNuoRayMask_Virtual) == 0)
    {
        device uint* index = structUniform.index;
        device NuoRayTracingMaterial* materials = structUniform.materials;
        NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
        
        float opacity = material.shinessDisolveIllum.y;
        float Tr = (1.0 - opacity) < 1e-6 ? 0.0 : 1.0 - opacity;
        
        const float maxDistance = tracingUniforms.bounds.span;
        spawnRay = startRay;
        spawnRay.mask &= (~kNuoRayMask_Virtual);
        spawnRay.pathScatter = Tr;
        spawn_ray(startRay, spawnRay, intersection.distance, maxDistance / 20000.0);
        
        if (Tr == 0.0)
            spawnRay.maxDistance = -1;
        
        // assume the visibility is zero. later if the ray goes through all translucent surfaces,
        // the value will be overwritten. or the ray hit an opaque surface, or hit more surfaces
        // than the upper test limit, the zero visibility will be the result
        //
        visibilities[rayIdx] = 0.0;
    }
    else
    {
        spawnRay.maxDistance = -1;
        spawnRay.pathScatter = 1.0;
    }
}


kernel void ray_visibility(uint2 tid [[thread_position_in_grid]],
                           device RayStructureUniform& structUniform [[buffer(0)]],
                           constant NuoRayTracingUniforms& tracingUniforms,
                           device float3* visibilities)
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& spawnRay = structUniform.exitantRays[rayIdx];
    device Intersection & intersection = structUniform.intersections[rayIdx];
    if (spawnRay.maxDistance > 0)
    {
        if (intersection.distance >= 0)
        {
            device uint* index = structUniform.index;
            device NuoRayTracingMaterial* materials = structUniform.materials;
            NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
            
            float opacity = saturate(material.shinessDisolveIllum.y);
            float Tr = (1.0 - opacity) < 1e-6 ? 0.0 : 1.0 - opacity;
            spawnRay.pathScatter *= Tr;
            
            if (Tr == 0.0)
            {
                spawnRay.maxDistance = -1;
            }
            else
            {
                const float maxDistance = tracingUniforms.bounds.span;
                spawn_ray(spawnRay, spawnRay, intersection.distance, maxDistance / 20000.0);
            }
        }
        else
        {
            spawnRay.maxDistance = -1;
        }
    }
    
    if (spawnRay.maxDistance  < 0.0)
    {
        visibilities[rayIdx] = spawnRay.pathScatter;
    }
}


void spawn_ray(device const RayBuffer& ray, device RayBuffer& spawn, float distance, float skip)
{
    float3 intersectPoint = ray.origin + distance * ray.direction;
    spawn.origin = intersectPoint + ray.direction * skip;
    spawn.maxDistance = ray.maxDistance - distance - skip;
}



#pragma mark -- Path Tracing


kernel void primary_ray_virtual(uint2 tid [[thread_position_in_grid]],
                                device RayStructureUniform& structUniform [[buffer(0)]],
                                device RayTracingTargets& targets,
                                constant NuoRayTracingUniforms& tracingUniforms,
                                device NuoRayTracingRandomUnit* random,
                                device RayBuffer* shadowRayMain,
                                array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                                sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = structUniform.intersections[rayIdx];
    device RayBuffer* shadowRay = shadowRayMain + rayIdx;
    const RayBuffer ray = structUniform.exitantRays[rayIdx];
    
    device NuoRayTracingRandomUnit& randomVars = random[(tid.y % 16) * 16 + (tid.x % 16) + 256 * ray.bounce];
    
    if (intersection.distance >= 0.0f)
    {
        // direct lighting on virtual surfaces as if no normal object present
            
        float totalDensity = 0;
        uint lightSourceIndex = light_source_select(tracingUniforms,
                                                    randomVars.lightSource, &totalDensity);
        
        constant NuoRayTracingLightSource& lightSource = tracingUniforms.lightSources[lightSourceIndex];
        
        shadow_ray_emit_infinite_area(ray, intersection, structUniform, tracingUniforms,
                                      lightSource, randomVars.uvLightSource, shadowRay,
                                      diffuseTex, samplr);
        
        shadowRay->pathScatter *= ray.pathScatter;
        shadowRay->pathScatter *= totalDensity;
        
        targets.lightingVirtual.write(float4(shadowRay->pathScatter, 1.0), tid);
    }
    else if (ray.maxDistance > 0)
    {
        targets.lightingVirtual.write(float4(1.0), tid);
    }
    
    ambient_with_no_block(tid, structUniform, tracingUniforms, ray, intersection, randomVars,
                          targets.overlayForVirtualWithoutBlock, diffuseTex, samplr);
}



kernel void primary_ray_process(uint2 tid [[thread_position_in_grid]],
                                device RayStructureUniform& structUniform [[buffer(0)]],
                                device RayTracingTargets& targets,
                                constant NuoRayTracingUniforms& tracingUniforms,
                                device NuoRayTracingRandomUnit* random,
                                device RayBuffer* shadowRayMain,
                                device RayBuffer* incidentRaysBuffer,
                                array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                                sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& cameraRay = structUniform.exitantRays[rayIdx];
    cameraRay.primaryHitMask = surface_mask(rayIdx, structUniform);
    
    self_illumination(tid, structUniform, tracingUniforms,
                      shadowRayMain, incidentRaysBuffer,
                      random, targets, diffuseTex, samplr);
}



kernel void incident_ray_process(uint2 tid [[thread_position_in_grid]],
                                 device RayStructureUniform& structUniform [[buffer(0)]],
                                 device RayTracingTargets& targets,
                                 constant NuoRayTracingUniforms& tracingUniforms,
                                 device NuoRayTracingRandomUnit* random,
                                 device RayBuffer* shadowRayMain,
                                 device Intersection *intersections,
                                 device float3* primaryVisibility,
                                 array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                                 sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    const unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & shadowIntersectionInfo = intersections[rayIdx];
    device RayBuffer& shadowRay = shadowRayMain[rayIdx];
    float shadowIntersection = shadowIntersectionInfo.distance;
    
    if (shadowRay.maxDistance > 0.0f)
    {
        bool isOcclusion = (shadowRay.primaryHitMask & kNuoRayMask_Virtual) && shadowRay.bounce == 1;
        
        if (!isOcclusion && (shadowIntersection < 0.0f))
            lightingTrcacingWrite(tid, shadowRay.pathScatter, targets.lightingTracing);
        
        if (isOcclusion && (shadowIntersection > 0.0f))
            targets.lightingVirtualBlocked.write(float4(shadowRay.pathScatter, 1.0), tid);
    }
    
    targets.modelMask.write(float4(primaryVisibility[rayIdx], 1.0), tid);
    
    self_illumination(tid, structUniform, tracingUniforms,
                      shadowRayMain, structUniform.exitantRays /* incident rays are the
                                                                  exitant rays of the next path */,
                      random, targets, diffuseTex, samplr);
}



    
/**
 *  write the result of illuminating surface and ambient
 *
 *  "directAmbient" means the ambient illumination conveyed by the first bounce, which is used for reduce the
 *  background occlusion (if there is shadow). On the other hand, "indirect" ambient or local light source are
 *  added to the final result.
 */
static void overlayWrite(uint hitType, float3 value, uint2 tid, bool directAmbient,
                         device RayTracingTargets& targets)
{
    bool isVirtual = (hitType & kNuoRayMask_Virtual);
    texture2d<float, access::read_write> texture = (isVirtual && directAmbient) ?
                                                    targets.overlayForVirtual   // direct ambient for reducing occlusion
                                                  : targets.lightingTracing;    // indirect ambient to be added to the result
    
    const float4 color = texture.read(tid);
    const float4 result = float4(color.rgb + value.rgb, 1.0);
    texture.write(result, tid);
}


static void lightingTrcacingWrite(uint2 tid, float3 value,
                                  texture2d<float, access::read_write> texture)
{
    const float4 color = texture.read(tid);
    const float4 result = float4(color.rgb + value, 1.0);
    texture.write(result, tid);
}


void self_illumination(uint2 tid,
                       device RayStructureUniform& structUniform,
                       constant NuoRayTracingUniforms& tracingUniforms,
                       device RayBuffer* shadowRays,
                       device RayBuffer* incidentRays,
                       device NuoRayTracingRandomUnit* random,
                       device RayTracingTargets& targets,
                       array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                       sampler samplr)
{
    constant NuoRayTracingGlobalIlluminationParam& globalIllum = tracingUniforms.globalIllum;
    
    unsigned int rayIdx = tid.y * structUniform.rayUniform.wViewPort + tid.x;
    device Intersection& intersection = structUniform.intersections[rayIdx];
    device NuoRayTracingMaterial* materials = structUniform.materials;
    device uint* index = structUniform.index;
    device RayBuffer& incidentRay = incidentRays[rayIdx];
    device RayBuffer& shadowRay = shadowRays[rayIdx];
    
    // make a copy from the exitant rays buffer as the same buffer might be used as
    // incident rays buffer
    //
    const RayBuffer ray = structUniform.exitantRays[rayIdx];
    
    // increase the bounce number no matter how the next path would be constructed according to
    // how the intersection went
    //
    incidentRay.bounce = ray.bounce + 1;
    
    // mark the rays invalid unless later evidences show they are not
    //
    incidentRay.maxDistance = -1;
    shadowRay.maxDistance = -1;
    
    bool directAmbient = (ray.bounce == 1);
    
    if (intersection.distance >= 0.0f)
    {
        const float maxDistance = tracingUniforms.bounds.span;
        const float ambientRadius = maxDistance / 5.0 * (1.0 - globalIllum.ambientRadius * 0.5);
        
        unsigned int triangleIndex = intersection.primitiveIndex;
        device uint* vertexIndex = index + triangleIndex * 3;
        float3 color = interpolate_color(materials, diffuseTex, index, intersection, samplr);
        
        int illuminate = materials[*(vertexIndex)].shinessDisolveIllum.z;
        if (illuminate == 0)
        {
            color = color * ray.pathScatter * globalIllum.illuminationStrength * 10.0;
            
            /* old comment regarding the light source sampling vs. reflection sampling:
            //   for bounced ray, multiplied with the integral base (2 PI, or the hemisphre)
            //   as there is no primary ray
            //
            // which seems not true and commented out (the 10.0 multiplication above is the
            // parameter range compensation for the removal of 2.0 * M_PI
            //
            // if (ray.bounce > 0)
            //     color = 2.0f * M_PI_F * color; */
            
            // clap the value or the anti-alias on object discontinuity will fail.
            // (the problem exists on bounced path as well, but monte carlo does not have a way
            // to handle that case, becuase it cannot predict the converged value)
            //
            if (ray.bounce == 0)
                color = saturate(color);
            
            overlayWrite(ray.primaryHitMask, color, tid,
                         false /* not ambient. local light source */ ,
                         targets);
        }
        else
        {
            device NuoRayTracingRandomUnit& randomVars = random[(tid.y % 16) * 16 + (tid.x % 16) + 256 * ray.bounce];
            
            float totalDensity = 0;
            uint lightSourceIndex = light_source_select(tracingUniforms,
                                                        randomVars.lightSource, &totalDensity);
            
            constant NuoRayTracingLightSource& lightSource = tracingUniforms.lightSources[lightSourceIndex];
            
            shadow_ray_emit_infinite_area(ray, intersection, structUniform, tracingUniforms,
                                          lightSource, randomVars.uvLightSource, &shadowRay,
                                          diffuseTex, samplr);
            
            shadowRay.pathScatter *= ray.pathScatter;
            shadowRay.pathScatter *= totalDensity;
            
            NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
            material.diffuseColor = color;
            material.specularColor *= (tracingUniforms.globalIllum.specularMaterialAdjust / 3.0);
            
            RayBuffer currentIncident;
            sample_scatter_ray(maxDistance, randomVars, intersection, material, ray, currentIncident);
            incidentRay = currentIncident;
            
            // if the ray has transmitted through translucent objects and then lands on a virtual surface,
            //   1. treat it as a first-bounce primary ray, so the shadow ray so it could be rendered
            //      onto the virtual target
            //   2. turn back on the ambient
            //
            if (ray.transThrough)
            {
                uint surfaceMask = surface_mask(rayIdx, structUniform);
                if (surfaceMask & kNuoRayMask_Virtual)
                {
                    shadowRay.primaryHitMask = kNuoRayMask_Virtual;
                    shadowRay.bounce = 1;
                    
                    incidentRay.primaryHitMask = kNuoRayMask_Virtual;
                    incidentRay.bounce = 1;
                    incidentRay.ambientOccluded = false;
                }
            }
        }
        
        if (ray.bounce > 0)
        {
            float ambientFactor = ambient_distance_factor(ambientRadius / 20.0, ambientRadius,
                                                          intersection.distance, 1.0);
            
            if (!ray.ambientOccluded && ambientFactor > 0)
            {
                color = ray.pathScatter * globalIllum.ambient * ambientFactor;
                overlayWrite(ray.primaryHitMask, color, tid, directAmbient, targets);
            }
            else if (incidentRay.bounce > 1 /* do not set occlusion for the first bounce (either
                                             * the object is too close to the camera, or a trans-through
                                             * ray hits a virtual surface */)
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
            overlayWrite(ray.primaryHitMask, color, tid, directAmbient, targets);
        }
        else if (ray.bounce == 0)
        {
            targets.overlayForVirtual.write(float4(globalIllum.ambient, 1.0), tid);
        }
    }
}

