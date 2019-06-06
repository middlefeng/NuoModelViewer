//
//  RayTracingShadersCommonCPU.cpp
//  ModelViewer
//
//  Created by Dong on 6/6/19.
//  Copyright © 2019 middleware. All rights reserved.
//

#include "RayTracingShadersCommonCPU.h"

#include <simd/simd.h>
#include <stdio.h>



typedef simd::float3 float3;



inline float3 align_hemisphere_normal(float3 sample, float3 normal);
inline float3 relative_to_hemisphere_normal(float3 w, float3 n);



void test()
{
    float3 vec[5];
    float3 n[5];
    
    for (size_t i = 0; i < 5; ++i)
    {
        vec[i] = float3 { ((float)rand() / RAND_MAX) * 2.f - 1.0f, ((float)rand() / RAND_MAX) * 2.f - 1.0f, ((float)rand() / RAND_MAX) * 2.f - 1.0f };
        vec[i] = simd::normalize(vec[i]);
        
        n[i] = float3 { ((float)rand() / RAND_MAX) * 2.f - 1.0f, ((float)rand() / RAND_MAX) * 2.f - 1.0f, ((float)rand() / RAND_MAX) * 2.f - 1.0f };
        n[i] = simd::normalize(n[i]);
        
        printf("Vector, [%f, %f, %f].\n", vec[i].x, vec[i].y, vec[i].z);
        
        float3 aligned = align_hemisphere_normal(vec[i], n[i]);
        
        printf("Vector Aligned, [%f, %f, %f].\n", aligned.x, aligned.y, aligned.z);
        
        float3 world = relative_to_hemisphere_normal(aligned, n[i]);
        
        printf("Vector Local, [%f, %f, %f].\n", world.x, world.y, world.z);
    }
}



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
    
    return float3 { simd::dot(w, coord.right), simd::dot(w, coord.up), simd::dot(w, coord.forward) };
}
