//
//  RayTracingShadersCommon.h
//  ModelViewer
//
//  Created by middleware on 9/17/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef RayTracingShadersCommon_h
#define RayTracingShadersCommon_h


/* data structures coming from <MetalPerformanceShaders/MPSRayIntersectorTypes.h> */

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
    
    // part of the radiance scatter function over an incrementally constructed path where this ray
    // as the latest section (pbr-book 14.16)
    //
    // it is the product of all BRDF and geometric coupling terms of the previous sections (pbr-book 14.14)
    // "BRDF and geometric coupling terms" -   f * cos(theta) / pdf(wo)         (14.19)
    //
    packed_float3 pathScatter;
    
    // if the ray has already deviated from the original camera direction
    //
    bool transThrough;
    
    // the lenght of path in terms of the number of subpaths, and
    // the mask type of the first hit surface
    //
    int bounce;
    unsigned int primaryHitMask;
    
    // determine if the ambient calculation should terminate, which is independent from
    // whether boucing should terminate
    bool ambientOccluded;
    
    // probability of the sample of the current sampling approach, and an alternative
    // sampling approach in the multiple importance sampling
    float pdf;
    float pdfAlternative;
};


/**
 *  MPSRayIntersector data type - MPSIntersectionDistancePrimitiveIndexCoordinates
 *
 *  (No reliable way of including the MPS framework headers)
 */

struct Intersection
{
    float distance;
    int primitiveIndex;
    float2 coordinates;
};




struct RayStructureUniform
{
    constant NuoRayVolumeUniform& rayUniform [[id(0)]];
    device uint* index [[id(1)]];
    device uint* masks;
    device NuoRayTracingMaterial* materials;
    device RayBuffer* exitantRays;
    device Intersection *intersections;
};




struct PathSample
{
    float3 direction;
    float3 original;
    
    // the path scatter term contributed by the reflection where the current sample
    // plays as incident ray. it is
    //
    // f * cos(theta) / pdf, see p875, pbr-book, [14.19]
    //
    float3 pathScatterTerm;
    
    float opacity;
    
    bool specularReflection;
    bool transmission;
    bool transThrough;
    
    float pdf;
};



constant bool kShadowOnTranslucent  [[ function_constant(0) ]];





/**
 *  sampling / interpolation utilities
 */

inline NuoRayTracingMaterial interpolate_material(device NuoRayTracingMaterial *materials, device uint* index, Intersection intersection)
{
    // barycentric coordinates sum to one
    float3 uvw;
    uvw.xy = intersection.coordinates;
    uvw.z = 1.0f - uvw.x - uvw.y;
    
    unsigned int triangleIndex = intersection.primitiveIndex;
    index = index + triangleIndex * 3;
    
    // lookup value for each vertex
    device NuoRayTracingMaterial& material0 = materials[*(index + 0)];
    device NuoRayTracingMaterial& material1 = materials[*(index + 1)];
    device NuoRayTracingMaterial& material2 = materials[*(index + 2)];
    
    device float3& n0 = material0.normal;
    device float3& n1 = material1.normal;
    device float3& n2 = material2.normal;
    
    device float3& s0 = material0.specularColor;
    device float3& s1 = material1.specularColor;
    device float3& s2 = material2.specularColor;
    
    float sp0 = material0.shinessDisolveIllum.x;
    float sp1 = material1.shinessDisolveIllum.x;
    float sp2 = material2.shinessDisolveIllum.x;
    
    float sd0 = material0.shinessDisolveIllum.y;
    float sd1 = material1.shinessDisolveIllum.y;
    float sd2 = material2.shinessDisolveIllum.y;
    
    NuoRayTracingMaterial result;
    
    // compute sum of vertex attributes weighted by barycentric coordinates
    result.normal = metal::normalize(uvw.x * n0 + uvw.y * n1 + uvw.z * n2);
    result.specularColor = uvw.x * s0 + uvw.y * s1 + uvw.z * s2;
    result.shinessDisolveIllum.x = uvw.x * sp0 + uvw.y * sp1 + uvw.z * sp2;
    result.shinessDisolveIllum.y = uvw.x * sd0 + uvw.y * sd1 + uvw.z * sd2;
    result.shinessDisolveIllum.z = material0.shinessDisolveIllum.z;
    
    return result;
}


inline float3 interpolate_color(device NuoRayTracingMaterial *materials,
                                metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                                device uint* index, Intersection intersection,
                                metal::sampler samplr)
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
    
    float3 color = uvw.x * n0 + uvw.y * n1 + uvw.z * n2;
    
    int textureIndex = materials[*(index + 0)].diffuseTex;
    if (textureIndex >= 0)
    {
        metal::texture2d<float> texture = diffuseTex[textureIndex];
        
        float2 texCoord0 = materials[*(index + 0)].texCoord.xy;
        float2 texCoord1 = materials[*(index + 1)].texCoord.xy;
        float2 texCoord2 = materials[*(index + 2)].texCoord.xy;
        
        float2 texCoord = uvw.x * texCoord0 + uvw.y * texCoord1 + uvw.z * texCoord2;
        float4 texColor = texture.sample(samplr, texCoord);
        
        color *= texColor.rgb;
    }
    
    return color;
}


inline NuoRayTracingMaterial interpolate_full_material(device NuoRayTracingMaterial *materials,
                                                       metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                                                       float specularAdjust,
                                                       device uint* index, Intersection intersection,
                                                       metal::sampler samplr)
{
    float3 color = interpolate_color(materials, diffuseTex, index, intersection, samplr);
    
    NuoRayTracingMaterial material = interpolate_material(materials, index, intersection);
    material.diffuseColor = color;
    material.specularColor *= specularAdjust;
    
    return material;
}



#pragma mark -- Scatter Sampling


// uses the inversion method to map two uniformly random numbers to a three dimensional
// unit hemisphere where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0)
//
inline float3 sample_cosine_weighted_hemisphere(float2 u, int m)
{
    if (m > 1.999e5)
        return float3(0, 1, 0);
    
    float phi = 2.0f * M_PI_F * u.x;
    
    float cos_phi;
    float sin_phi = metal::sincos(phi, cos_phi);
    
    float cos_theta = m == 1 ? metal::sqrt(u.y) : metal::pow(u.y, 1.0 / (m + 1.0));
    float sin_theta = metal::sqrt(1.0f - cos_theta * cos_theta);
    
    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}


// normalized probability distribution of a cosine-raised-by-m-weight
//
inline float cosine_pow_pdf(float cos_theta, int m)
{
    // see p345, pbr-book, [5.5]
    // dw = sin(theta)d(theta)d(phi)
    
    if (m == 1)
    {
        // the factor 1/pi is got as k in normalizing the integral k*cos(x)dw
        //
        return cos_theta / M_PI_F;
    }
    else
    {
        // the factor  (m + 2) / (2 * pi) is got as k in normalizing the integral
        // k*cos^m(x)dw
        //
        return (m + 2) / (2 * M_PI_F) * metal::pow(cos_theta, m);
    }
}


inline float3 sample_cone_uniform(float2 u, float cosThetaMax)
{
    float cosTheta = (1 - u.x) + u.x * cosThetaMax;
    float sinTheta = metal::sqrt(1 - cosTheta * cosTheta);
    float phi = u.y * 2.0f * M_PI_F;
    
    return float3(metal::cos(phi) * sinTheta,
                  cosTheta,
                  metal::sin(phi) * sinTheta);
}



uint surface_mask(uint rayIdx, device RayStructureUniform& structUniform);




#pragma mark -- Spherical/Local Coordinate

// the vectors in "world" coordinate, which are basis of a hemisphere coordinate
//
struct NuoHemisphereCoordinate
{
    float3 right, forward, up;
};


inline NuoHemisphereCoordinate hemi_sphere_basis(float3 normal)
{
    NuoHemisphereCoordinate result;
    
    result.up = normal;
    
    // Find an arbitrary direction perpendicular to the normal. This will become the
    // "right" vector.
    result.right = simd::normalize(simd::cross(normal, float3 { 0.0072f, 1.0f, 0.0034f }));
    if (metal::length(result.right) < 1e-3)
        result.right = simd::normalize(metal::cross(normal, float3 { 0.0072f, 0.0034f, 1.0f }));
    
    // Find a third vector perpendicular to the previous two. This will be the
    // "forward" vector.
    result.forward = metal::cross(result.right, result.up);
    
    return result;
}


// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction
inline float3 align_hemisphere_normal(float3 sample, float3 n)
{
    NuoHemisphereCoordinate c = hemi_sphere_basis(n);
    
    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * c.right + sample.y * c.up + sample.z * c.forward;
}



inline float3 relative_to_hemisphere_normal(float3 w, float3 n)
{
    NuoHemisphereCoordinate c = hemi_sphere_basis(n);
    
    return float3 { metal::dot(w, c.right),
                    metal::dot(w, c.up),
                    metal::dot(w, c.forward) };
}



/**
 *  shadow ray optimization
 */

void shadow_ray_emit_infinite_area(thread const RayBuffer& ray,
                                   device Intersection& intersection,
                                   device RayStructureUniform& structUniform,
                                   constant NuoRayTracingUniforms& tracingUniforms,
                                   uint lightSourceStart, uint lightSourceEnd,
                                   device NuoRayTracingRandomUnit& randoms,
                                   device RayBuffer* shadowRays,
                                   metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                                   metal::sampler samplr);


void ambient_with_no_block(uint2 tid,
                           device RayStructureUniform& structUniform,
                           constant NuoRayTracingUniforms& tracingUniforms,
                           thread const RayBuffer& cameraRay,
                           device Intersection& intersection,
                           device NuoRayTracingRandomUnit& randomVars,
                           metal::texture2d<float, metal::access::read_write> target,
                           metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                           metal::sampler samplr);


void sample_scatter_ray(float maxDistance,
                        device NuoRayTracingRandomUnit& random,
                        device Intersection& intersection,
                        thread const NuoRayTracingMaterial& material,
                        thread const RayBuffer& ray,
                        thread RayBuffer& incidentRay);

void sample_light_by_scatter(float maxDistance,
                             constant NuoRayTracingLightSource* lightSources,
                             device NuoRayTracingRandomUnit& random,
                             device Intersection& intersection,
                             thread const NuoRayTracingMaterial& material,
                             thread const RayBuffer& ray,
                             device RayBuffer& shadowRay);

float ambient_distance_factor(float criteriaBlock, float criteriaUnblock,
                              float intersection, float power);



#endif /* RayTracingShadersCommon_h */

