//
//  NuoBounds.cpp
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#include "NuoBounds.h"



NuoBounds::NuoBounds()
    : _center(0.0, 0.0, 0.0),
      _span(0.0, 0.0, 0.0)
{
}



NuoBounds NuoBounds::Transform(const NuoMatrixFloat44& matrix) const
{
    NuoVectorFloat3 min = _center - _span / 2.0f;
    NuoVectorFloat4 pMin(min.x(), min.y(), min.z(), 1.0);
    pMin = matrix * pMin;
    
    NuoBounds result;
    result._center = NuoVectorFloat3(pMin.x(), pMin.y(), pMin.z());
    result._span = NuoVectorFloat3(0.0f, 0.0f, 0.0f);
    
    {
        NuoVectorFloat4 point = { _center.x() + _span.x() / 2.0f,
                                  _center.y() - _span.y() / 2.0f,
                                  _center.z() - _span.z() / 2.0f, 1.0f };
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    {
        NuoVectorFloat4 point = { _center.x() - _span.x() / 2.0f,
                                  _center.y() + _span.y() / 2.0f,
                                  _center.z() - _span.z() / 2.0f, 1.0f };
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    {
        NuoVectorFloat4 point = { _center.x() - _span.x() / 2.0f,
                                  _center.y() - _span.y() / 2.0f,
                                  _center.z() + _span.z() / 2.0f, 1.0f };
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    {
        NuoVectorFloat4 point = { _center.x() - _span.x() / 2.0f,
                                  _center.y() + _span.y() / 2.0f,
                                  _center.z() + _span.z() / 2.0f, 1.0f };
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    {
        NuoVectorFloat4 point = { _center.x() + _span.x() / 2.0f,
                                  _center.y() + _span.y() / 2.0f,
                                  _center.z() - _span.z() / 2.0f, 1.0f };
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    {
        NuoVectorFloat4 point = { _center.x() + _span.x() / 2.0f,
                                  _center.y() - _span.y() / 2.0f,
                                  _center.z() + _span.z() / 2.0f, 1.0f };
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    {
        NuoVectorFloat3 p = _center + _span / 2.0f;
        NuoVectorFloat4 point(p.x(), p.y(), p.z(), 1.0);
        point = matrix * point;
        result = result.Union(NuoVectorFloat3(point.x(), point.y(), point.z()));
    }
    
    return result;
}


NuoBounds NuoBounds::Union(const NuoBounds& bounds) const
{
    NuoVectorFloat3 aMin = _center - _span / 2.0f;
    NuoVectorFloat3 bMin = bounds._center - bounds._span / 2.0f;
    NuoVectorFloat3 aMax = _center + _span / 2.0f;
    NuoVectorFloat3 bMax = bounds._center + bounds._span / 2.0f;
    
    NuoVectorFloat3 resultMin(fmin(aMin.x(), bMin.x()),
                              fmin(aMin.y(), bMin.y()),
                              fmin(aMin.z(), bMin.z()));
    NuoVectorFloat3 resultMax(fmax(aMax.x(), bMax.x()),
                              fmax(aMax.y(), bMax.y()),
                              fmax(aMax.z(), bMax.z()));
    
    NuoBounds result;
    result._center = (resultMax + resultMin) / 2.0f;
    result._span = (resultMax - resultMin);
    
    return result;
}


NuoBounds NuoBounds::Union(const NuoVectorFloat3& point) const
{
    NuoVectorFloat3 aMin = _center - _span / 2.0f;
    NuoVectorFloat3 aMax = _center + _span / 2.0f;
    
    NuoVectorFloat3 resultMin(fmin(aMin.x(), point.x()),
                              fmin(aMin.y(), point.y()),
                              fmin(aMin.z(), point.z()));
    NuoVectorFloat3 resultMax(fmax(aMax.x(), point.x()),
                              fmax(aMax.y(), point.y()),
                              fmax(aMax.z(), point.z()));
    
    NuoBounds result;
    result._center = (resultMax + resultMin) / 2.0f;
    result._span = (resultMax - resultMin);
    
    return result;
}



float NuoBounds::MaxDimension() const
{
    return fmax(fmax(_span.x(), _span.y()), _span.z());
}


NuoSphere NuoBounds::Sphere() const
{
    NuoSphere result;
    result._center = _center;
    result._radius = MaxDimension() * 1.414 / 2.0;
    
    return result;
}


bool NuoBounds::Intersect(const NuoRay& ray, float* near, float* far)
{
    const float rayDirection[3] = {ray._direction.x(), ray._direction.y(), ray._direction.z()};
    const float rayOrigin[3] = {ray._origin.x(), ray._origin.y(), ray._origin.z()};
    const double min[3] =
    {
        _center.x() - _span.x() / 2.0,
        _center.y() - _span.y() / 2.0,
        _center.z() - _span.z() / 2.0
    };
    const double max[3] =
    {
        _center.x() + _span.x() / 2.0,
        _center.y() + _span.y() / 2.0,
        _center.z() + _span.z() / 2.0
    };
    
    float t0 = 0, t1 = INFINITY;
    
    for (int i = 0; i < 3; ++i)
    {
        // update interval for _i_th bounding box slab
        float invRayDir = 1 / rayDirection[i];
        float tNear = (min[i] - rayOrigin[i]) * invRayDir;
        float tFar = (max[i] - rayOrigin[i]) * invRayDir;
        
        // update parametric interval from slab intersection $t$ values
        if (tNear > tFar)
            std::swap(tNear, tFar);
        
        // Update _tFar_ to ensure robust ray--bounds intersection
        t0 = tNear > t0 ? tNear : t0;
        t1 = tFar < t1 ? tFar : t1;
        if (t0 > t1)
            return false;
    }
    
    if (near)
        *near = t0;
    if (far)
        *far = t1;
    
    return true;
}


NuoSphere::NuoSphere()
    : _center(0.0, 0.0, 0.0),
      _radius(0.0)
{
}


NuoSphere NuoSphere::Union(const NuoSphere &sphere)
{
    float distance = NuoDistance(_center, sphere._center);
    const NuoSphere* smaller, * larger;
    
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


NuoSphere NuoSphere::Transform(const NuoMatrixFloat44& matrix) const
{
    NuoSphere result;
    NuoVectorFloat4 center(_center.x(), _center.y(), _center.z(), 1.0);
    center = matrix * center;
    
    result._center = NuoVectorFloat3(center.x(), center.y(), center.z());
    result._radius = _radius;
    
    return result;
}



