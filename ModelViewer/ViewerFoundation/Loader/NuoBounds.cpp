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



NuoBounds NuoBounds::Transform(const matrix_float4x4& matrix)
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


NuoBounds NuoBounds::Union(const NuoBounds& bounds)
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


NuoBounds NuoBounds::Union(const vector_float3& point)
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
