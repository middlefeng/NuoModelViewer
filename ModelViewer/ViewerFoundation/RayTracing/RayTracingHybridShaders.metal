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
    float distance;

    // the path scatter term contributed by the reflection where the current sample
    // plays as incident ray. it is
    //
    // f * cos(theta) / pdf, see p875, pbr-book, [14.19]
    //
    float3 pathScatterTerm;
};



struct SurfaceInteraction
{
    float3 p;
    NuoRayTracingMaterial material;
};



static void self_illumination(uint2 tid,
                              device RayStructureUniform& structUniform,
                              constant NuoRayTracingUniforms& tracingUniforms,
                              device RayBuffer* shadowRay,
                              float shadowIntersection,
                              device RayBuffer* incidentRays,
                              device NuoRayTracingRandomUnit* random,
                              texture2d<float, access::read_write> overlayResult,
                              texture2d<float, access::read_write> overlayForVirtual,
                              array<texture2d<float>, kTextureBindingsCap> diffuseTex,
                              sampler samplr);



kernel void primary_ray_process(uint2 tid [[thread_position_in_grid]],
                                device RayStructureUniform& structUniform [[buffer(0)]],
                                constant NuoRayTracingUniforms& tracingUniforms,
                                device NuoRayTracingRandomUnit* random,
                                device RayBuffer* shadowRays0,
                                device RayBuffer* shadowRays1,
                                device uint* masks,
                                array<texture2d<float>, kTextureBindingsCap> diffuseTex [[texture(2)]],
                                sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = structUniform.intersections[rayIdx];
    device RayBuffer& cameraRay = structUniform.exitantRays[rayIdx];
    
    unsigned int triangleIndex = intersection.primitiveIndex;
    cameraRay.primaryHitMask = masks[triangleIndex];
    
    device RayBuffer* shadowRays[] = { shadowRays0, shadowRays1 };
    
    // directional light sources in the scene definition are considered area lights with finite
    // subtending solid angles, in far distance
    //
    shadow_ray_emit_infinite_area(tid, structUniform,
                                  tracingUniforms, random, shadowRays, diffuseTex, samplr);
}


kernel void primary_and_incident_ray_process(uint2 tid [[thread_position_in_grid]],
                                             device RayStructureUniform& structUniform [[buffer(0)]],
                                             constant NuoRayTracingUniforms& tracingUniforms,
                                             device NuoRayTracingRandomUnit* random,
                                             device RayBuffer* shadowRayMain,
                                             device RayBuffer* shadowRays0,
                                             device RayBuffer* shadowRays1,
                                             device RayBuffer* incidentRaysBuffer,
                                             device uint* masks,
                                             texture2d<float, access::read_write> overlayResult [[texture(0)]],
                                             texture2d<float, access::read_write> overlayForVirtual [[texture(1)]],
                                             array<texture2d<float>, kTextureBindingsCap> diffuseTex [[texture(2)]],
                                             sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & intersection = structUniform.intersections[rayIdx];
    device RayBuffer& cameraRay = structUniform.exitantRays[rayIdx];
    
    unsigned int triangleIndex = intersection.primitiveIndex;
    cameraRay.primaryHitMask = masks[triangleIndex];
    
    device RayBuffer* shadowRays[] = { shadowRays0, shadowRays1 };
    
    // directional light sources in the scene definition are considered area lights with finite
    // subtending solid angles, in far distance
    //
    shadow_ray_emit_infinite_area(tid, structUniform,
                                  tracingUniforms, random, shadowRays, diffuseTex, samplr);
    
    self_illumination(tid, structUniform,
                      tracingUniforms, shadowRayMain, 1.0, incidentRaysBuffer,
                      random, overlayResult, overlayForVirtual, diffuseTex, samplr);
}



kernel void incident_ray_process(uint2 tid [[thread_position_in_grid]],
                                 device RayStructureUniform& structUniform [[buffer(0)]],
                                 constant NuoRayTracingUniforms& tracingUniforms,
                                 device NuoRayTracingRandomUnit* random,
                                 device RayBuffer* shadowRayMain,
                                 device Intersection *intersections,
                                 texture2d<float, access::read_write> overlayResult [[texture(0)]],
                                 texture2d<float, access::read_write> overlayForVirtual [[texture(1)]],
                                 array<texture2d<float>, kTextureBindingsCap> diffuseTex [[texture(2)]],
                                 sampler samplr [[sampler(0)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    const unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device Intersection & shadowIntersection = intersections[rayIdx];
    
    self_illumination(tid, structUniform, tracingUniforms,
                      shadowRayMain, shadowIntersection.distance,
                      structUniform.exitantRays /* incident rays are the
                                                   exitant rays of the next path */,
                      random, overlayResult, overlayForVirtual, diffuseTex, samplr);
}


// informative name for the lighting result texture index
//
enum LightingType
{
    kLighting_WithoutBlock = 0,
    kLighting_WithBlock,
};


kernel void shadow_contribute(uint2 tid [[thread_position_in_grid]],
                              device RayStructureUniform& structUniform [[buffer(0)]],
                              device uint* shadeIndex,
                              texture_array<2, access::write>::t lightForOpaque  [[texture(0)]],
                              texture_array<2, access::write>::t lightForTrans   [[texture(2)]],
                              texture_array<2, access::write>::t lightForVirtual [[texture(4)]])
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    
    device Intersection& intersection = structUniform.intersections[rayIdx];
    device RayBuffer& shadowRay = structUniform.exitantRays[rayIdx];
    
    texture_array<2, access::write>::t lightsDst[] = { lightForOpaque,
                                                       lightForTrans,
                                                       lightForVirtual };
    
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



static PathSample sample_scatter(const thread SurfaceInteraction& interaction, float3 ray,
                                 float2 sampleUV, float Cdeterminator  /* randoms */ );

static PathSample sample_light_source(const thread SurfaceInteraction& interaction, float3 ray,
                                      device RayStructureUniform& structUniform,
                                      device NuoRayTracingRandomUnit& random,
                                      metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                                      metal::sampler samplr);


void overlay_write(uint hitType, float4 value, uint2 tid,
                   texture2d<float, access::read_write> overlayResult,
                   texture2d<float, access::read_write> overlayForVirtual)
{
    texture2d<float, access::read_write> texture = (hitType & kNuoRayMask_Virtual) ?
                                                        overlayForVirtual : overlayResult;
    
    float4 color = texture.read(tid);
    texture.write(float4(color.rgb + value.rgb, 1.0), tid);
    
    /*if (hitType & kNuoRayMask_Virtual)
        overlayForVirtual.write(value, tid);
    else
        overlayResult.write(value, tid);*/
}


void self_illumination(uint2 tid,
                       device RayStructureUniform& structUniform,
                       constant NuoRayTracingUniforms& tracingUniforms,
                       device RayBuffer* shadowRays,
                       float shadowIntersection,
                       device RayBuffer* incidentRays,
                       device NuoRayTracingRandomUnit* random,
                       texture2d<float, access::read_write> overlayResult,
                       texture2d<float, access::read_write> overlayForVirtual,
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
    RayBuffer ray = structUniform.exitantRays[rayIdx];
    
    if (shadowRay.maxDistance > 0.0f && shadowIntersection < 0.0f)
    {
        overlay_write(shadowRay.primaryHitMask, float4(shadowRay.pathScatter, 1.0), tid,
                      overlayResult, overlayForVirtual);
    }
    
    if (intersection.distance >= 0.0f)
    {
        const float maxDistance = tracingUniforms.bounds.span;
        const float ambientRadius = maxDistance / 5.0 * (1.0 - globalIllum.ambientRadius * 0.5);
        
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
            
            // clap the value or the anti-alias on object discontinuity will fail.
            // (the problem exists on bounced path as well, but monte carlo does not have a way
            // to handle that case, becuase it cannot predict the converged value)
            //
            if (ray.bounce == 0)
            {
                color = saturate(color);
                overlay_write(ray.primaryHitMask, float4(color, 1.0), tid,
                              overlayResult, overlayForVirtual);
            }
            
            incidentRay.maxDistance = -1;
            shadowRay.maxDistance = -1;
        }
        else
        {
            device NuoRayTracingRandomUnit& randomVars = random[(tid.y % 16) * 16 + (tid.x % 16) + 256 * ray.bounce];
            device float2& r = randomVars.uv;
            device float& Cdeterm = randomVars.pathTermDeterminator;
            
            float3 intersectionPoint = ray.origin + ray.direction * intersection.distance;
            
            NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
            material.diffuseColor = color;
            material.specularColor *= (tracingUniforms.globalIllum.specularMaterialAdjust / 3.0);
            intersectionPoint += normalize(material.normal) * (maxDistance / 20000.0);
            
            const SurfaceInteraction interaction = { intersectionPoint, material };
            PathSample sample = sample_scatter(interaction, -ray.direction, r, Cdeterm);
            
            PathSample shadowRaySample = sample_light_source(interaction, -ray.direction,
                                                             structUniform, randomVars, diffuseTex,samplr);
            shadowRay.direction = shadowRaySample.direction;
            shadowRay.origin = intersectionPoint;
            shadowRay.maxDistance = shadowRaySample.distance - (maxDistance / 10000.0);
            
            shadowRay.mask = kNuoRayMask_Opaue | kNuoRayMask_Illuminating;
            shadowRay.primaryHitMask = ray.primaryHitMask;
            shadowRay.pathScatter = shadowRaySample.pathScatterTerm * originalRayColor * globalIllum.illuminationStrength * 10.0;
            
            // terminate further tracing if the term is zero. this happens when the vector is out of
            // the hemisphere in the specular sampling
            //
            if (sample.pathScatterTerm.x == 0 &&
                sample.pathScatterTerm.y == 0 &&
                sample.pathScatterTerm.z == 0)
            {
                incidentRay.maxDistance = -1;
                incidentRay.pathScatter = 0.0;
            }
            else
            {
                incidentRay.direction = sample.direction;
                incidentRay.origin = intersectionPoint;
                incidentRay.maxDistance = maxDistance;
                incidentRay.mask = kNuoRayMask_Opaue | kNuoRayMask_Illuminating;
                incidentRay.primaryHitMask = ray.primaryHitMask;
                incidentRay.bounce = ray.bounce + 1;
                incidentRay.ambientIlluminated = ray.ambientIlluminated;
                
                // make the term of this reflection contribute to the path scatter
                //
                incidentRay.pathScatter = sample.pathScatterTerm * ray.pathScatter;
            }
        }
        
        if (ray.bounce > 0 && !ray.ambientIlluminated && intersection.distance > ambientRadius)
        {
            color = originalRayColor * globalIllum.ambient;
            overlay_write(ray.primaryHitMask, float4(color, 1.0), tid, overlayResult, overlayForVirtual);
            incidentRay.ambientIlluminated = true;
        }
    }
    else if (ray.maxDistance > 0)
    {
        if (ray.bounce > 0 && !ray.ambientIlluminated)
        {
            float3 color = ray.pathScatter * globalIllum.ambient;
            overlay_write(ray.primaryHitMask, float4(color, 1.0), tid, overlayResult, overlayForVirtual);
            incidentRay.ambientIlluminated = true;
        }
        else if (ray.bounce == 0)
        {
            overlayForVirtual.write(float4(float3(globalIllum.ambient), 1.0), tid);
            incidentRay.ambientIlluminated = true;
        }
        
        incidentRay.maxDistance = -1;
        shadowRay.maxDistance = -1;
    }
}


inline static float3 reflection_vector(float3 wo, float3 normal);
inline bool same_hemisphere(float3 w, float3 wp);


PathSample sample_scatter(const thread SurfaceInteraction& interaction, float3 ray,
                          float2 sampleUV, float Cdeterminator  /* randoms */ )
{
    PathSample result;
    
    const float3 Cdiff = interaction.material.diffuseColor;
    const float3 Cspec = interaction.material.specularColor;
    const float Mspec = interaction.material.shinessDisolveIllum.x;
    const float3 normal = interaction.material.normal;
    
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
    
PathSample sample_light_source(const thread SurfaceInteraction& interaction, float3 ray,
                               device RayStructureUniform& structUniform,
                               device NuoRayTracingRandomUnit& random,
                               metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                               metal::sampler samplr)
{
    const unsigned int lightSourceNumber = structUniform.lightSourceSize;
    const unsigned int lightIndex = (unsigned int)(random.lightSourceSelect * lightSourceNumber);
    device uint* lightVertexIndex = structUniform.indexLightSource + lightIndex * 3;
    device float3* vertices = structUniform.vertices;
    const float3 triangle[3] = { vertices[*(lightVertexIndex)],
                                 vertices[*(lightVertexIndex + 1)],
                                 vertices[*(lightVertexIndex + 2)] };
    
    const float2 uv = uniform_sample_triangle(random.lightSource);
    const float3 intersectPoint = triangle[0] * uv[0] + triangle[1] * uv[1]
                                                      + triangle[2] * (1 - uv[0] - uv[1]);
    
    Intersection intersection;
    intersection.coordinates = uv;
    intersection.primitiveIndex = lightIndex;
    
    const float3 color = interpolate_color(structUniform.materials, diffuseTex,
                                           structUniform.indexLightSource, intersection, samplr);
    NuoRayTracingMaterial material = interpolate_material(structUniform.materials,
                                                          structUniform.indexLightSource, intersection);
    
    const float3 direction = intersectPoint - interaction.p;
    
    PathSample result;
    result.direction = normalize(direction);
    
    const float area = triangle_area(triangle);
    const float distanceSquared = length_squared(direction);
    const float3 normal = material.normal;
    
    result.distance = sqrt(distanceSquared);
    
    const float pdfInverse = lightSourceNumber *
                                area * abs(dot(-result.direction, normal)) /
                                max(distanceSquared, 1e-6);
    
    result.pathScatterTerm = color * pdfInverse;
    
    const float3 Cdiff = interaction.material.diffuseColor;
    const float3 Cspec = interaction.material.specularColor;
    const float Mspec = interaction.material.shinessDisolveIllum.x;
    const float3 n = interaction.material.normal;
    
    const float3 wh = (ray + result.direction) / 2.0;
    float3 f = Cdiff + (Cspec + (1.0f - Cspec) * pow(1.0f - saturate(dot(result.direction, wh)), 5.0)) * ((Mspec + 8.0) / 8.0);
    f *= dot(n, result.direction) / M_PI_F;
    
    result.pathScatterTerm *= f;

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
