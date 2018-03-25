//
//  NuoBounds.hpp
//  ModelViewer
//
//  Created by Dong on 1/25/18.
//  Copyright © 2018 middleware. All rights reserved.
//

#ifndef NuoBounds_hpp
#define NuoBounds_hpp



#include <simd/simd.h>


/**
 *  it's usually arbitrary to pick either the bounds (i.e. bounding box) or the sphere
 *  to position objects to a subjectively comfortable place.
 *
 *  when it comes to the near/far plane calcuation, bounds is more accurate as it utilize
 *  z-buffer range to the objects' span maximally.
 */


struct NuoBoundsBase
{
    vector_float3 _center;
    vector_float3 _span;
};


struct NuoSphereBase
{
    vector_float3 _center;
    float _radius;
};


#if __cplusplus


class NuoSphere : public NuoSphereBase
{

public:
    
    NuoSphere();
    
    NuoSphere Union(const NuoSphere& sphere);
    NuoSphere Transform(const matrix_float4x4& matrix) const;

};


class NuoBounds : public NuoBoundsBase
{
public:
    NuoBounds();
    
    NuoBounds Transform(const matrix_float4x4& matrix) const;

    NuoBounds Union(const NuoBounds& bounds) const;
    NuoBounds Union(const vector_float3& point) const;
    float MaxDimension() const;
    
    NuoSphere Sphere() const;
};


#endif



#endif /* NuoBounds_hpp */
