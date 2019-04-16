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
    //
    float pathScatter;
    
    packed_float3 color;
    int bounce;
    
    // determine if the ambient calculation should terminate, which is independent from
    // whether boucing should terminate
    bool ambientIlluminated;
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
    
    NuoRayTracingMaterial result;
    
    // compute sum of vertex attributes weighted by barycentric coordinates
    result.normal = uvw.x * n0 + uvw.y * n1 + uvw.z * n2;
    result.specularColor = uvw.x * s0 + uvw.y * s1 + uvw.z * s2;
    result.shinessDisolveIllum.x = uvw.x * sp0 + uvw.y * sp1 + uvw.z * sp2;
    
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


// uses the inversion method to map two uniformly random numbers to a three dimensional
// unit hemisphere where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0)
inline float3 sample_cosine_weighted_hemisphere(float2 u)
{
    float phi = 2.0f * M_PI_F * u.x;
    
    float cos_phi;
    float sin_phi = metal::sincos(phi, cos_phi);
    
    float cos_theta = metal::sqrt(u.y);
    float sin_theta = metal::sqrt(1.0f - cos_theta * cos_theta);
    
    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
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


// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction
inline float3 align_hemisphere_normal(float3 sample, float3 normal)
{
    // Set the "up" vector to the normal
    float3 up = normal;
    
    // Find an arbitrary direction perpendicular to the normal. This will become the
    // "right" vector.
    float3 right = metal::normalize(metal::cross(normal, metal::float3(0.0072f, 1.0f, 0.0034f)));
    if (metal::length(right) < 1e-3)
        right = metal::normalize(metal::cross(normal, metal::float3(0.0072f, 0.0034f, 1.0f)));
    
    // Find a third vector perpendicular to the previous two. This will be the
    // "forward" vector.
    metal::float3 forward = metal::cross(right, up);
    
    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * right + sample.y * up + sample.z * forward;
}



/**
 *  shadow ray optimization
 */

void shadow_ray_emit_infinite_area(uint2 tid,
                                   constant NuoRayVolumeUniform& uniforms,
                                   device RayBuffer& ray,
                                   device uint* index,
                                   device NuoRayTracingMaterial* materials,
                                   device Intersection& intersection,
                                   constant NuoRayTracingUniforms& tracingUniforms,
                                   device float2* random,
                                   device RayBuffer* shadowRays[2],
                                   metal::array<metal::texture2d<float>, kTextureBindingsCap> diffuseTex,
                                   metal::sampler samplr);



#endif /* RayTracingShadersCommon_h */

