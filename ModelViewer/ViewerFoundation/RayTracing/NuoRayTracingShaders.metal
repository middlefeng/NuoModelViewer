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
    unsigned int mask;
    packed_float3 direction;
    float maxDistance;
    
    // cosine base strength factor (reserved, unused)
    float strength;
    packed_float3 color;
    int bounce;
};


struct Intersection
{
    float distance;
    int primitiveIndex;
    float2 coordinates;
};




float3 interpolateNormal(device NuoRayTracingMaterial *materials, device uint* index, Intersection intersection)
{
    // barycentric coordinates sum to one
    float3 uvw;
    uvw.xy = intersection.coordinates;
    uvw.z = 1.0f - uvw.x - uvw.y;
    
    unsigned int triangleIndex = intersection.primitiveIndex;
    index = index + triangleIndex * 3;
    
    // Lookup value for each vertex
    float3 n0 = materials[*(index + 0)].normal;
    float3 n1 = materials[*(index + 1)].normal;
    float3 n2 = materials[*(index + 2)].normal;
    
    // Compute sum of vertex attributes weighted by barycentric coordinates
    return uvw.x * n0 + uvw.y * n1 + uvw.z * n2;
}


float3 interpolateColor(device NuoRayTracingMaterial *materials, device uint* index, Intersection intersection)
{
    // barycentric coordinates sum to one
    float3 uvw;
    uvw.xy = intersection.coordinates;
    uvw.z = 1.0f - uvw.x - uvw.y;
    
    unsigned int triangleIndex = intersection.primitiveIndex;
    index = index + triangleIndex * 3;
    
    // Lookup value for each vertex
    float3 n0 = materials[*(index + 0)].diffuseColor;
    float3 n1 = materials[*(index + 1)].diffuseColor;
    float3 n2 = materials[*(index + 2)].diffuseColor;
    
    // Compute sum of vertex attributes weighted by barycentric coordinates
    return uvw.x * n0 + uvw.y * n1 + uvw.z * n2;
}





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
    
    // 0.2 is the empirically measured offset between the rasterization and the ray tracing.
    // seems caused by the different ways of anti-alias (MSAA vs. randomized camera rays)
    //
    float2 pixelCoord = (float2)tid + r + 0.2;
    
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
    
    ray.maxDistance = INFINITY;
}


static constant bool kShadowOnTranslucent  [[ function_constant(0) ]];

static void self_illumination(uint2 tid,
                              device uint* index,
                              device NuoRayTracingMaterial* materials,
                              device Intersection& intersection,
                              constant NuoRayTracingUniforms& tracingUniforms,
                              device RayBuffer& ray,
                              device RayBuffer& incidentRay,
                              device float2* random,
                              texture2d<float, access::read_write> overlayResult);



kernel void ray_set_mask(uint2 tid [[thread_position_in_grid]],
                         constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                         device RayBuffer* rays [[buffer(1)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& ray = rays[rayIdx];
    
    if (kShadowOnTranslucent)
        ray.mask = kNuoRayMask_Translucent;
    else
        ray.mask = kNuoRayMask_Opaue;
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


static void shadow_ray_emit(uint2 tid,
                            constant NuoRayVolumeUniform& uniforms,
                            device RayBuffer& ray,
                            device uint* index,
                            device NuoRayTracingMaterial* materials,
                            device Intersection& intersection,
                            constant NuoRayTracingUniforms& tracingUniforms,
                            device float2* random,
                            device RayBuffer* shadowRays1,
                            device RayBuffer* shadowRays2);



kernel void primary_ray_process(uint2 tid [[thread_position_in_grid]],
                                constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                device RayBuffer* rays [[buffer(1)]],
                                device uint* index [[buffer(2)]],
                                device NuoRayTracingMaterial* materials [[buffer(3)]],
                                device Intersection *intersections [[buffer(4)]],
                                constant NuoRayTracingUniforms& tracingUniforms [[buffer(5)]],
                                device float2* random [[buffer(6)]],
                                device RayBuffer* shadowRays1 [[buffer(7)]],
                                device RayBuffer* shadowRays2 [[buffer(8)]],
                                device RayBuffer* incidentRaysBuffer [[buffer(9)]],
                                texture2d<float, access::read_write> overlayResult [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer& ray = rays[rayIdx];
    device RayBuffer& incidentRay = incidentRaysBuffer[rayIdx];
    
    shadow_ray_emit(tid, uniforms, ray, index, materials, intersection,
                    tracingUniforms, random,
                    shadowRays1,
                    shadowRays2);
    
    self_illumination(tid, index, materials, intersection,
                      tracingUniforms, ray, incidentRay,
                      random, overlayResult);
}



kernel void incident_ray_process(uint2 tid [[thread_position_in_grid]],
                                 constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                 device RayBuffer* rays [[buffer(1)]],
                                 device uint* index [[buffer(2)]],
                                 device NuoRayTracingMaterial* materials [[buffer(3)]],
                                 device Intersection *intersections [[buffer(4)]],
                                 constant NuoRayTracingUniforms& tracingUniforms [[buffer(5)]],
                                 device float2* random [[buffer(6)]],
                                 device RayBuffer* incidentRaysBuffer [[buffer(7)]],
                                 texture2d<float, access::read_write> overlayResult [[texture(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer& incidentRay = incidentRaysBuffer[rayIdx];
    
    self_illumination(tid, index, materials, intersection,
                      tracingUniforms, incidentRay, incidentRay,
                      random, overlayResult);
}



void shadow_ray_emit(uint2 tid,
                     constant NuoRayVolumeUniform& uniforms,
                     device RayBuffer& ray,
                     device uint* index,
                     device NuoRayTracingMaterial* materials,
                     device Intersection& intersection,
                     constant NuoRayTracingUniforms& tracingUniforms,
                     device float2* random,
                     device RayBuffer* shadowRays1,
                     device RayBuffer* shadowRays2)
{
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    
    device RayBuffer* shadowRay[2];
    shadowRay[0] = &shadowRays1[rayIdx];
    shadowRay[1] = &shadowRays2[rayIdx];
    
    const float maxDistance = tracingUniforms.bounds.span;
    
    float2 r = random[(tid.y % 16) * 16 + (tid.x % 16)];
    float2 r1 = random[(tid.y % 16) * 16 + (tid.x % 16) + 256];
    r = (r * 2.0 - 1.0) * maxDistance * 0.25;
    r1 = (r1 * 2.0 - 1.0);
    
    for (uint i = 0; i < 2; ++i)
    {
        device RayBuffer* shadowRayCurrent = shadowRay[i];
        
        // initialize the buffer's strength fields
        // (took 2 days to figure this out after spot the problem in debugger 8/21/2018)
        //
        shadowRayCurrent->strength = 0.0f;
        
        if (intersection.distance >= 0.0f)
        {
            float4 lightVec = float4(0.0, 0.0, 1.0, 0.0);
            lightVec = normalize(tracingUniforms.lightSources[i].direction * lightVec);
            
            float3 lightPosition = (lightVec.xyz * maxDistance);
            float3 lightRight = normalize(cross(lightVec.xyz, float3(r1.x, r1.y, 1.0)));
            float3 lightForward = cross(lightRight, lightVec.xyz);
            
            float radius = tracingUniforms.lightSources[i].radius / 2.0;
            lightPosition = lightPosition + lightRight * r.x * radius + lightForward * r.y * radius;
            
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            float3 shadowVec = normalize(lightPosition.xyz);
            
            shadowRayCurrent->maxDistance = maxDistance;
            shadowRayCurrent->mask = kNuoRayMask_Opaue;
            
            float3 normal = interpolateNormal(materials, index, intersection);
            
            shadowRayCurrent->origin = intersectionPoint + normalize(normal) * (maxDistance / 600000.0);
            shadowRayCurrent->direction = shadowVec;
            
            shadowRayCurrent->strength = dot(normal, shadowVec);
        }
        else
        {
            shadowRayCurrent->maxDistance = -1.0;
        }
    }
}



kernel void shadow_contribute(uint2 tid [[thread_position_in_grid]],
                              constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                              device RayBuffer* rays [[buffer(1)]],
                              device uint* index [[buffer(2)]],
                              device NuoRayTracingMaterial* materials [[buffer(3)]],
                              device Intersection *intersections [[buffer(4)]],
                              device RayBuffer* shadowRays [[buffer(5)]],
                              texture2d<float, access::read_write> light [[texture(0)]],
                              texture2d<float, access::read_write> lightWithBlock [[texture(1)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer & shadowRay = shadowRays[rayIdx];
    
    if (shadowRay.strength > 0)
    {
        /**
         *  the total diffuse (with all blockers virtually removed) and the amount that considers
         *  blockers are recorded, and therefore accumulated by a subsequent accumulator.
         */
        
        if (kShadowOnTranslucent)
        {
            float r = light.read(tid).r;
            light.write(float4(r, shadowRay.strength, 0.0, 1.0), tid);
        }
        else
        {
            float g = light.read(tid).g;
            light.write(float4(shadowRay.strength, g, 0.0, 1.0), tid);
        }
    
        if (intersection.distance < 0.0f)
        {
            if (kShadowOnTranslucent)
            {
                float r = lightWithBlock.read(tid).r;
                lightWithBlock.write(float4(r, shadowRay.strength, 0.0, 1.0), tid);
            }
            else
            {
                float g = lightWithBlock.read(tid).g;
                lightWithBlock.write(float4(shadowRay.strength, g, 0.0, 1.0), tid);
            }
        }
    }
}



kernel void shadow_illuminate(uint2 tid [[thread_position_in_grid]],
                              texture2d<float, access::read> light [[texture(0)]],
                              texture2d<float, access::read> lightWithBlock [[texture(1)]],
                              texture2d<float, access::write> dstTex [[texture(2)]])
{
    if (!(tid.x < dstTex.get_width() && tid.y < dstTex.get_height()))
        return;
    
    float illuminate = light.read(tid).r;
    float illuminateWithBlock = lightWithBlock.read(tid).r;
    float illuminatePercent = illuminateWithBlock;
    
    // (comment to above)
    // illuminateWithBlock won't be greater than illuminate. if the latter is too small,
    // use the former directly (rather than use zero)
    
    if (illuminate > 0.00001)   // avoid divided by zero
    {
        illuminatePercent = saturate(illuminateWithBlock / illuminate);
    }
    
    illuminate = light.read(tid).g;
    illuminateWithBlock = lightWithBlock.read(tid).g;
    float illuminatePercentTranslucent = illuminateWithBlock;
    
    if (illuminate > 0.00001)   // avoid divided by zero
    {
        illuminatePercentTranslucent = saturate(illuminateWithBlock / illuminate);
    }
    
    dstTex.write(float4(1 - illuminatePercent, 1 - illuminatePercentTranslucent, 0.0, 1.0), tid);
}


// uses the inversion method to map two uniformly random numbers to a three dimensional
// unit hemisphere where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0)
inline float3 sample_cosine_weighted_hemisphere(float2 u)
{
    float phi = 2.0f * M_PI_F * u.x;
    
    float cos_phi;
    float sin_phi = sincos(phi, cos_phi);
    
    float cos_theta = sqrt(u.y);
    float sin_theta = sqrt(1.0f - cos_theta * cos_theta);
    
    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}


// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction
inline float3 align_hemisphere_normal(float3 sample, float3 normal)
{
    // Set the "up" vector to the normal
    float3 up = normal;
    
    // Find an arbitrary direction perpendicular to the normal. This will become the
    // "right" vector.
    float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));
    if (length(right) < 1e-3)
        right = normalize(cross(normal, float3(0.0072f, 0.0034f, 1.0f)));
    
    // Find a third vector perpendicular to the previous two. This will be the
    // "forward" vector.
    float3 forward = cross(right, up);
    
    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * right + sample.y * up + sample.z * forward;
}


void self_illumination(uint2 tid,
                       device uint* index,
                       device NuoRayTracingMaterial* materials,
                       device Intersection& intersection,
                       constant NuoRayTracingUniforms& tracingUniforms,
                       device RayBuffer& ray,
                       device RayBuffer& incidentRay,
                       device float2* random,
                       texture2d<float, access::read_write> overlayResult)
{
    if (intersection.distance >= 0.0f)
    {
        unsigned int triangleIndex = intersection.primitiveIndex;
        device uint* vertexIndex = index + triangleIndex * 3;
        
        float3 color = interpolateColor(materials, index, intersection);
        
        int illuminate = materials[*(vertexIndex)].illuminate;
        if (illuminate == 0)
        {
            overlayResult.write(float4(color * ray.color * tracingUniforms.illuminationStrength, 1.0), tid);
            
            incidentRay.maxDistance = -1;
        }
        else
        {
            float2 r = random[(tid.y % 16) * 16 + (tid.x % 16) + 256 * ray.bounce];
            
            float3 normal = interpolateNormal(materials, index, intersection);
            float3 sampleVec = sample_cosine_weighted_hemisphere(r);
            
            const float maxDistance = tracingUniforms.bounds.span;
            
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            incidentRay.direction = align_hemisphere_normal(sampleVec, normal);
            incidentRay.origin = intersectionPoint + normalize(normal) * (maxDistance / 20000.0);
            incidentRay.maxDistance = maxDistance;
            incidentRay.mask = kNuoRayMask_Opaue | kNuoRayMask_Illuminating;
            incidentRay.bounce = ray.bounce + 1;
            
            incidentRay.color = color * ray.color;
        }
    }
}



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



