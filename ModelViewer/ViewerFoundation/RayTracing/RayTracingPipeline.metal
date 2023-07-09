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
                          device NuoRayVolumeUniform& rayUniform [[buffer(0)]],
                          device RayBuffer* rays [[buffer(1)]],
                          device Intersection* intersections,
                          accelerated_struct accelerationStructure)
{
    if (!(tid.x < rayUniform.wViewPort && tid.y < rayUniform.hViewPort))
        return;
    
    unsigned int rayIdx = tid.y * rayUniform.wViewPort + tid.x;
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
    i.assume_geometry_type(raytracing::geometry_type::triangle);
    
    intersection = i.intersect(ray, accelerationStructure);
    
    // convert the Metal pipeline intersection back into the one that is
    // compatible with MPS
    //
    device Intersection& bufferIntersection = intersections[rayIdx];
    
    // the rest of the renderer code assume the barycetric coord x and y bound to v0 and v1, which
    // was the same as regulated by the MPS implementation. the new ray tracing APIs mandates that
    // x and y bound to v1 and v2, which effectively makes them as y and z to the rest of thecode
    //
    // see section 2.17.4 of Metal shader 3 spec
    // https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf
    //
    float3 uvw;
    uvw.yz = intersection.triangle_barycentric_coord;
    uvw.x = 1.0f - uvw.y - uvw.z;
    
    bufferIntersection.coordinates = uvw.xy;
    bufferIntersection.primitiveIndex = intersection.primitive_id;
    
    if (intersection.type == raytracing::intersection_type::none)
        bufferIntersection.distance = -1;
    else
        bufferIntersection.distance = intersection.distance;
}

