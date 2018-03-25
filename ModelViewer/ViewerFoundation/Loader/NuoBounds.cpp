//
//  NuoBounds.cpp
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include "NuoBounds.h"



NuoBounds::NuoBounds()
{
    _center.x = _center.y = _center.z = 0.;
    _span.x = _span.y = _span.z = 0.;
}



NuoBounds NuoBounds::Transform(const matrix_float4x4& matrix) const
{
    vector_float3 min = _center - _span / 2.0;
    vector_float4 pMin = { min.x, min.y, min.z, 1.0 };
    pMin = matrix_multiply(matrix, pMin);
    
    NuoBounds result;
    result._center = pMin.xyz;
    result._span = vector_float3(0);
    
    {
        vector_float4 point = { _center.x + _span.x / 2.0f,
                                _center.y - _span.y / 2.0f,
                                _center.z - _span.z / 2.0f, 1.0f };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    {
        vector_float4 point = { _center.x - _span.x / 2.0f,
                                _center.y + _span.y / 2.0f,
                                _center.z - _span.z / 2.0f, 1.0f };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    {
        vector_float4 point = { _center.x - _span.x / 2.0f,
                                _center.y - _span.y / 2.0f,
                                _center.z + _span.z / 2.0f, 1.0f };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    {
        vector_float4 point = { _center.x - _span.x / 2.0f,
                                _center.y + _span.y / 2.0f,
                                _center.z + _span.z / 2.0f, 1.0f };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    {
        vector_float4 point = { _center.x + _span.x / 2.0f,
                                _center.y + _span.y / 2.0f,
                                _center.z - _span.z / 2.0f, 1.0f };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    {
        vector_float4 point = { _center.x + _span.x / 2.0f,
                                _center.y - _span.y / 2.0f,
                                _center.z + _span.z / 2.0f, 1.0f };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    {
        vector_float3 p = _center + _span / 2.0f;
        vector_float4 point = { p.x, p.y, p.z, 1.0 };
        point = matrix_multiply(matrix, point);
        result = result.Union(point.xyz);
    }
    
    return result;
}


NuoBounds NuoBounds::Union(const NuoBounds& bounds) const
{
    vector_float3 aMin = _center - _span / 2.0;
    vector_float3 bMin = bounds._center - bounds._span / 2.0;
    vector_float3 aMax = _center + _span / 2.0;
    vector_float3 bMax = bounds._center + bounds._span / 2.0;
    
    vector_float3 resultMin = { fmin(aMin.x, bMin.x),
                                fmin(aMin.y, bMin.y),
                                fmin(aMin.z, bMin.z) };
    vector_float3 resultMax = { fmax(aMax.x, bMax.x),
                                fmax(aMax.y, bMax.y),
                                fmax(aMax.z, bMax.z) };
    
    NuoBounds result;
    result._center = (resultMax + resultMin) / 2.0;
    result._span = (resultMax - resultMin);
    
    return result;
}


NuoBounds NuoBounds::Union(const vector_float3& point) const
{
    vector_float3 aMin = _center - _span / 2.0;
    vector_float3 aMax = _center + _span / 2.0;
    
    vector_float3 resultMin = { fmin(aMin.x, point.x),
                                fmin(aMin.y, point.y),
                                fmin(aMin.z, point.z) };
    vector_float3 resultMax = { fmax(aMax.x, point.x),
                                fmax(aMax.y, point.y),
                                fmax(aMax.z, point.z) };
    
    NuoBounds result;
    result._center = (resultMax + resultMin) / 2.0;
    result._span = (resultMax - resultMin);
    
    return result;
}



float NuoBounds::MaxDimension() const
{
    return fmax(fmax(_span.x, _span.y), _span.z);
}


NuoSphere NuoBounds::Sphere() const
{
    NuoSphere result;
    result._center = _center;
    result._radius = MaxDimension() * 1.414 / 2.0;
    
    return result;
}


NuoSphere::NuoSphere()
{
    _center.x = _center.y = _center.z = 0.;
    _radius = 0.;
}


NuoSphere NuoSphere::Union(const NuoSphere &sphere)
{
    float distance = simd::distance(_center, sphere._center);
    const NuoSphere* smaller, * larger;
    
    //[_center distanceTo:other.center];
    //NuoBoundingSphere *smaller, *larger;
    
    if (_radius > sphere._radius)
    {
        smaller = &sphere;
        larger = this;
    }
    else
    {
        smaller = this;
        larger = &sphere;
    }
    
    float futhestOtherReach = distance + smaller->_radius;
    float largerRadius = larger->_radius;
    
    if (futhestOtherReach < largerRadius)
    {
        return *larger;
    }
    else
    {
        NuoSphere result;
        result._radius = (distance + sphere._radius + _radius) / 2.0;
        
        float newCenterDistance = result._radius - _radius;
        float factor = newCenterDistance / distance;
        result._center = _center + (sphere._center - _center) * factor;
        
        return result;
    }
}


NuoSphere NuoSphere::Transform(const matrix_float4x4& matrix) const
{
    NuoSphere result;
    vector_float4 center = { _center.x, _center.y, _center.z, 1.0 };
    result._center = matrix_multiply(matrix, center).xyz;
    result._radius = _radius;
    
    return result;
}



