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



struct PathSample
{
    float3 direction;

    // the path scatter term contributed by the reflection where the current sample
    // plays as incident ray. it is
    //
    // f * cos(theta) / pdf, see p875, pbr-book, [14.19]
    //
    float3 pathScatterTerm;
};



static void self_illumination(uint2 tid,
                              device uint* index,
                              device NuoRayTracingMaterial* materials,
                              device Intersection& intersection,
                              constant NuoRayTracingUniforms& tracingUniforms,
                              device RayBuffer& ray,
                              device RayBuffer& incidentRay,
                              device NuoRayTracingRandomUnit* random,
                              texture2d<float, access::read_write> overlayResult,
                              array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                              sampler samplr);



kernel void primary_ray_process(uint2 tid [[thread_position_in_grid]],
                                constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                device RayBuffer* cameraRays [[buffer(1)]],
                                device uint* index [[buffer(2)]],
                                device NuoRayTracingMaterial* materials [[buffer(3)]],
                                device Intersection *intersections [[buffer(4)]],
                                constant NuoRayTracingUniforms& tracingUniforms [[buffer(5)]],
                                device NuoRayTracingRandomUnit* random [[buffer(6)]],
                                device RayBuffer* shadowRays0 [[buffer(7)]],
                                device RayBuffer* shadowRays1 [[buffer(8)]],
                                device RayBuffer* incidentRaysBuffer [[buffer(9)]],
                                texture2d<float, access::read_write> overlayResult [[texture(0)]],
                                array<texture2d<float>, kTextureBindingsCap> diffuseTex [[texture(1)]],
                                sampler samplr [[sampler(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer& cameraRay = cameraRays[rayIdx];
    device RayBuffer& incidentRay = incidentRaysBuffer[rayIdx];
    
    device RayBuffer* shadowRays[] = { shadowRays0, shadowRays1 };
    
    // directional light sources in the scene definition are considered area lights with finite
    // subtending solid angles, in far distance
    //
    shadow_ray_emit_infinite_area(tid, uniforms, cameraRay, index, materials, intersection,
                                  tracingUniforms, random, shadowRays, diffuseTex, samplr);
    
    self_illumination(tid, index, materials, intersection,
                      tracingUniforms, cameraRay, incidentRay,
                      random, overlayResult, diffuseTex, samplr);
}



kernel void incident_ray_process(uint2 tid [[thread_position_in_grid]],
                                 constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                                 device RayBuffer* cameraRays [[buffer(1)]],
                                 device uint* index [[buffer(2)]],
                                 device NuoRayTracingMaterial* materials [[buffer(3)]],
                                 device Intersection *intersections [[buffer(4)]],
                                 constant NuoRayTracingUniforms& tracingUniforms [[buffer(5)]],
                                 device NuoRayTracingRandomUnit* random [[buffer(6)]],
                                 device RayBuffer* incidentRaysBuffer [[buffer(7)]],
                                 texture2d<float, access::read_write> overlayResult [[texture(0)]],
                                 array<texture2d<float>, kTextureBindingsCap> diffuseTex [[texture(1)]],
                                 sampler samplr [[sampler(0)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = intersections[rayIdx];
    device RayBuffer& incidentRay = incidentRaysBuffer[rayIdx];
    
    self_illumination(tid, index, materials, intersection,
                      tracingUniforms, incidentRay, incidentRay,
                      random, overlayResult, diffuseTex, samplr);
}


kernel void shadow_contribute(uint2 tid [[thread_position_in_grid]],
                              constant NuoRayVolumeUniform& uniforms [[buffer(0)]],
                              device RayBuffer* rays [[buffer(1)]],
                              device uint* index [[buffer(2)]],
                              device NuoRayTracingMaterial* materials [[buffer(3)]],
                              device Intersection *intersections [[buffer(4)]],
                              device RayBuffer* shadowRays [[buffer(5)]],
                              texture_array<2, access::write>::t lightForOpaque [[texture(0)]],
                              texture_array<2, access::write>::t lightForTrans  [[texture(2)]])
{
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection& intersection = intersections[rayIdx];
    device RayBuffer& shadowRay = shadowRays[rayIdx];
    
    if (length(shadowRay.pathScatter) > 0)
    {
        texture_array<2, access::write>::t light = kShadowOnTranslucent ? lightForTrans : lightForOpaque;
        
        /**
         *  to generate a shadow map (rather than illuminating), the light transportation is integrand
         *
         *  previous comment before pbr-book reading:
         *      the total diffuse (with all blockers virtually removed) and the amount that considers
         *      blockers are recorded, and therefore accumulated by a subsequent accumulator.
         */
        
        light[0].write(float4(shadowRay.pathScatter, 1.0), tid);
        
        if (intersection.distance < 0.0f)
            light[1].write(float4(shadowRay.pathScatter, 1.0), tid);
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
        float3 illuminateWithBlock = lights[lightType][1].read(tid).rgb;
        float3 illuminatePercent = illuminateWithBlock;
        
        // (comment to above)
        // illuminateWithBlock won't be greater than illuminate. if the latter is too small,
        // use the former directly (rather than use zero)
        
        for (uint i = 0; i < 3; ++i)
        {
            if (illuminate[i] > 0.00001)   // avoid divided by zero
                illuminatePercent[i] = saturate(illuminateWithBlock[i] / illuminate[i]);
        }
        
        dstTex[lightType].write(float4((1 - illuminatePercent), 1.0), tid);
    }
}



PathSample sample_scatter(float3 Pn, float3 wi, float3 normal,      /* interaction point */
                          float2 sampleUV, float Cdeterminator,     /* randoms */
                          float3 Cdiff, float3 Cspec, float Mspec   /* material spec */     );


void self_illumination(uint2 tid,
                       device uint* index,
                       device NuoRayTracingMaterial* materials,
                       device Intersection& intersection,
                       constant NuoRayTracingUniforms& tracingUniforms,
                       device RayBuffer& ray,
                       device RayBuffer& incidentRay,
                       device NuoRayTracingRandomUnit* random,
                       texture2d<float, access::read_write> overlayResult,
                       array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                       sampler samplr)
{
    constant NuoRayTracingGlobalIlluminationParam& globalIllum = tracingUniforms.globalIllum;
    
    if (intersection.distance >= 0.0f)
    {
        const float maxDistance = tracingUniforms.bounds.span;
        const float ambientRadius = maxDistance / 25.0 * (1.0 - globalIllum.ambientRadius * 0.5);
        
        unsigned int triangleIndex = intersection.primitiveIndex;
        device uint* vertexIndex = index + triangleIndex * 3;
        float3 color = interpolate_color(materials, diffuseTex, index, intersection, samplr);
        
        // the outgoing ray (that is the input ray buffer) would be stored in the same buffer as the
        // incident ray (that is the output ray buffer) may be the same. so it's necessary to store the
        // color before calcuating the bounce
        //
        float3 originalRayColor = ray.pathScatter;
        
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
            
            overlayResult.write(float4(color, 1.0), tid);
            
            incidentRay.maxDistance = -1;
        }
        else
        {
            device NuoRayTracingRandomUnit& randomVars = random[(tid.y % 16) * 16 + (tid.x % 16) + 256 * ray.bounce];
            device float2& r = randomVars.uv;
            device float& Cdeterm = randomVars.pathTermDeterminator;
            
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            
            NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
            float3 specularColor = material.specularColor * (tracingUniforms.globalIllum.specularMaterialAdjust / 3.0);
            float specularPower = material.shinessDisolveIllum.x;
            
            PathSample sample = sample_scatter(intersectionPoint, -ray.direction, material.normal,
                                               r, Cdeterm,
                                               color, specularColor, specularPower);
            
            // terminate further tracing if the term is zero. this happens when the vector is out of
            // the hemisphere in the specular sampling
            //
            if (sample.pathScatterTerm.x == 0 &&
                sample.pathScatterTerm.y == 0 &&
                sample.pathScatterTerm.z == 0)
            {
                incidentRay.maxDistance = -1;
            }
            
            incidentRay.direction = sample.direction;
            incidentRay.origin = intersectionPoint + normalize(material.normal) * (maxDistance / 20000.0);
            incidentRay.maxDistance = maxDistance;
            incidentRay.mask = kNuoRayMask_Opaue | kNuoRayMask_Illuminating;
            incidentRay.bounce = ray.bounce + 1;
            incidentRay.ambientIlluminated = ray.ambientIlluminated;
            
            // make the term of this reflection contribute to the path scatter
            //
            incidentRay.pathScatter = sample.pathScatterTerm * ray.pathScatter;
        }
        
        if (ray.bounce > 0 && !ray.ambientIlluminated && intersection.distance > ambientRadius)
        {
            color = originalRayColor * globalIllum.ambient;
            overlayResult.write(float4(color, 1.0), tid);
            incidentRay.ambientIlluminated = true;
        }
    }
    else if (ray.maxDistance > 0)
    {
        if (ray.bounce > 0 && !ray.ambientIlluminated)
        {
            float3 color = ray.pathScatter * globalIllum.ambient;
            overlayResult.write(float4(color, 1.0), tid);
            incidentRay.ambientIlluminated = true;
        }
        
        incidentRay.maxDistance = -1;
    }
}


inline static float3 reflection_vector(float3 wo, float3 normal);
inline bool same_hemisphere(float3 w, float3 wp);


PathSample sample_scatter(float3 Pn, float3 ray, float3 normal,     /* interaction point */
                          float2 sampleUV, float Cdeterminator,     /* randoms */
                          float3 Cdiff, float3 Cspec, float Mspec   /* material spec */     )
{
    PathSample result;
    
    float CdiffSampleProbable = max(Cdiff.x, max(Cdiff.y, Cdiff.z));
    float CspecSampleProbable = min(Cspec.x, min(Cspec.y, Cspec.z));
    
    float probableTotal = CdiffSampleProbable + CspecSampleProbable;
    
    if (Cdeterminator < CdiffSampleProbable / probableTotal)
    {
        float3 wi = sample_cosine_weighted_hemisphere(sampleUV, 1);
        result.direction = align_hemisphere_normal(wi, normal);
        result.pathScatterTerm = Cdiff * (probableTotal / CdiffSampleProbable);
    }
    else
    {
        float3 wo = relative_to_hemisphere_normal(ray, normal);
        float3 wh = sample_cosine_weighted_hemisphere(sampleUV, Mspec);
        float3 wi = reflection_vector(wo, wh);
        
        if (!same_hemisphere(wo, wi))
        {
            result.pathScatterTerm = 0.0;
            return result;
        }
        
        // all the following factor omit a 1/pi factor, which would have been cancelled
        // in the calculation of cosinedPdfScale anyway
        //
        // hwPdf  -   PDF of the half vector in terms of theta_h, which is a cosine-weighed
        //            distribution based on micro-facet (and simplified by the Blinn-Phong).
        //            see comments in cosine_pow_pdf()
        //
        // f      -   BRDF specular term. note the normalization factor is (m + 8) / (8 * pi) because
        //            it is related to theta rather than theta_h.
        //            for the details of how the above normalization term is deduced, see http://www.farbrausch.de/%7Efg/stuff/phong.pdf
        //
        // pdf    -   PDF of the reflection vector. note this is not a analytical form in terms of theta,
        //            rather it is a value in terms of wo and the half-vector
        //            see p813, pbr-book
        //
        float hwPdf = (Mspec + 2.0) / 2.0;
        float pdf = hwPdf / (4.0 * dot(wo, wh));
        float3 f = (Cspec + (1.0f - Cspec) * pow(1.0f - saturate(dot(wo, wh)), 5.0)) * ((Mspec + 8.0) / 8.0);
        
        result.pathScatterTerm = f * (probableTotal / CspecSampleProbable) / pdf * wi.y /* cosine factor of incident ray */;
        result.direction = align_hemisphere_normal(wi, normal);
    }
    
    return result;
}


inline static float3 reflection_vector(float3 wo, float3 normal)
{
    return -wo + 2 * dot(wo, normal) * normal;
}


inline bool same_hemisphere(float3 w, float3 wp)
{
    return w.y * wp.y > 0;
}
