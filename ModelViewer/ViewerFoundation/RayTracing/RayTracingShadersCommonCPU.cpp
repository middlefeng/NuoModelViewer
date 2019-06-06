//
//  RayTracingShadersCommonCPU.cpp
//  ModelViewer
//
//  Created by Dong on 6/6/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#include "RayTracingShadersCommonCPU.h"

#include <simd/simd.h>



typedef simd::float3 float3;


// the vectors in "world" coordinate, which are basis of a hemisphere coordinate
//
struct NuoHemisphereCoordinate
{
    float3 right, forward, up;
};



NuoHemisphereCoordinate hemi_sphere_basis(float3 normal)
{
    NuoHemisphereCoordinate result;
    
    result.up = normal;
    
    // Find an arbitrary direction perpendicular to the normal. This will become the
    // "right" vector.
    result.right = simd::normalize(simd::cross(normal, float3 { 0.0072f, 1.0f, 0.0034f }));
    if (simd::length(result.right) < 1e-3)
        result.right = simd::normalize(simd::cross(normal, float3 { 0.0072f, 0.0034f, 1.0f }));
    
    // Find a third vector perpendicular to the previous two. This will be the
    // "forward" vector.
    result.forward = simd::cross(result.right, result.up);
    
    return result;
}



inline float3 align_hemisphere_normal(float3 sample, float3 normal)
{
    NuoHemisphereCoordinate coord = hemi_sphere_basis(normal);
    
    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * coord.right + sample.y * coord.up + sample.z * coord.forward;
}



inline float3 relative_to_hemisphere_normal(float3 w, float3 n)
{
    NuoHemisphereCoordinate coord = hemi_sphere_basis(n);
    
    return float3 { simd::dot(w.x, coord.right), simd::dot(w.y, coord.up), simd::dot(w.z, coord.forward) };
}
