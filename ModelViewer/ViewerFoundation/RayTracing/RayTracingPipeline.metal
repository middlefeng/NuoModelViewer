//
//  RayTracingPipeline.metal
//  ModelViewer
//
//  Created by Dong Feng on 7/7/23.
//  Copyright © 2023 Dong Feng. All rights reserved.
//

#include <metal_stdlib>

#include "NuoRayTracingUniform.h"
#include "RayTracingShadersCommon.h"


using namespace metal;


typedef metal::raytracing::primitive_acceleration_structure accelerated_struct;


kernel void ray_intersect(uint2 tid [[thread_position_in_grid]],
                          device RayStructureUniform& structUniform [[buffer(0)]],
                          device RayBuffer* rays [[buffer(1)]],
                          accelerated_struct accelerationStructure)
{
    constant NuoRayVolumeUniform& uniforms = structUniform.rayUniform;
    
    if (!(tid.x < uniforms.wViewPort && tid.y < uniforms.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * uniforms.wViewPort + tid.x;
    device RayBuffer& bufferRay = rays[rayIdx];
    
    // convert the RayBuffer item into Metal pipeline type
    metal::raytracing::ray ray;
    ray.origin = bufferRay.origin;
    ray.direction = bufferRay.direction;
    ray.max_distance = bufferRay.maxDistance;
    
    typedef raytracing::intersector<metal::raytracing::triangle_data> intersector;
    intersector::result_type intersection;
    
    intersector i;
    
    i.accept_any_intersection(false);
    intersection = i.intersect(ray, accelerationStructure);
    
    device Intersection& bufferIntersection = structUniform.intersections[rayIdx];
    bufferIntersection.distance = intersection.distance;
    bufferIntersection.coordinates = intersection.triangle_barycentric_coord;
    bufferIntersection.primitiveIndex = intersection.primitive_id;
}

